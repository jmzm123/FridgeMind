#import "SyncManager.h"
#import "DBManager.h"
#import "NetworkManager.h"
#import "Ingredient.h"
#import <UIKit/UIKit.h>
#import <YYModel/YYModel.h>
#import <AFNetworking/AFNetworking.h>

NSString * const kSyncDidFinishNotification = @"kSyncDidFinishNotification";

@interface SyncManager ()
@property (nonatomic, strong) dispatch_queue_t syncQueue;
@property (atomic, assign) BOOL isSyncing;
@end

@implementation SyncManager

+ (instancetype)sharedManager {
    static SyncManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SyncManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _syncQueue = dispatch_queue_create("com.fridgemind.sync", DISPATCH_QUEUE_SERIAL);
        _isSyncing = NO;
    }
    return self;
}

- (void)startMonitoring {
    // Listen for app active
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sync) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // Network reachability
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusReachableViaWiFi || status == AFNetworkReachabilityStatusReachableViaWWAN) {
            NSLog(@"Network reachable.");
            // Only sync if there are pending local changes to save resources
            if ([[DBManager sharedManager] fetchIngredientsForSync].count > 0) {
                 NSLog(@"Pending changes found, triggering sync...");
                 [self sync];
            }
        }
    }];
}

- (void)sync {
    @synchronized (self) {
        if (self.isSyncing) return;
        self.isSyncing = YES;
    }
    
    dispatch_async(self.syncQueue, ^{
        [self performSync];
        @synchronized (self) {
            self.isSyncing = NO;
        }
    });
}

- (void)performSync {
    // 1. Push Local Changes
    [self pushLocalChanges];
    
    // 2. Pull Server Changes
    [self pullServerChanges];
}

- (void)pushLocalChanges {
    NSArray<Ingredient *> *pending = [[DBManager sharedManager] fetchIngredientsForSync];
    NSString *familyId = [NetworkManager sharedManager].currentFamilyId;
    if (!familyId) return;
    
    dispatch_group_t group = dispatch_group_create();
    
    for (Ingredient *ing in pending) {
        dispatch_group_enter(group);
        
        if (ing.deleted) {
            if (ing._id) {
                // Case C: Delete on Server
                [[NetworkManager sharedManager] deleteIngredient:ing._id success:^(id  _Nullable response) {
                    [[DBManager sharedManager] hardDeleteIngredient:ing.localId];
                    dispatch_group_leave(group);
                } failure:^(NSError * _Nonnull error) {
                    dispatch_group_leave(group);
                }];
            } else {
                // Case D: Local only delete
                [[DBManager sharedManager] hardDeleteIngredient:ing.localId];
                dispatch_group_leave(group);
            }
        } else if (ing._id) {
            // Case B: Update
            NSDictionary *params = [ing yy_modelToJSONObject];
            NSMutableDictionary *cleanParams = [params mutableCopy];
            [cleanParams removeObjectForKey:@"_id"];
            [cleanParams removeObjectForKey:@"localId"];
            [cleanParams removeObjectForKey:@"syncStatus"];
            [cleanParams removeObjectForKey:@"deleted"];
            
            [[NetworkManager sharedManager] updateIngredient:ing._id familyId:familyId params:cleanParams success:^(id  _Nullable response) {
                ing.syncStatus = @"synced";
                [[DBManager sharedManager] updateIngredientAfterSync:ing];
                dispatch_group_leave(group);
            } failure:^(NSError * _Nonnull error) {
                dispatch_group_leave(group);
            }];
        } else {
            // Case A: Create
            NSDictionary *params = [ing yy_modelToJSONObject];
            NSMutableDictionary *cleanParams = [params mutableCopy];
            [cleanParams removeObjectForKey:@"localId"];
            [cleanParams removeObjectForKey:@"syncStatus"];
            [cleanParams removeObjectForKey:@"deleted"];
            cleanParams[@"familyId"] = familyId;
            
            [[NetworkManager sharedManager] addIngredient:cleanParams success:^(id  _Nullable response) {
                if ([response isKindOfClass:[NSDictionary class]]) {
                    ing._id = response[@"id"];
                    ing.syncStatus = @"synced";
                     [[DBManager sharedManager] updateIngredientAfterSync:ing];
                }
                dispatch_group_leave(group);
            } failure:^(NSError * _Nonnull error) {
                dispatch_group_leave(group);
            }];
        }
    }
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

- (void)pullServerChanges {
    NSString *lastSyncTime = [[NSUserDefaults standardUserDefaults] stringForKey:@"kLastSyncTime"];
    NSString *familyId = [NetworkManager sharedManager].currentFamilyId;
    if (!familyId) return;
    
    // Using dispatch semaphore to wait for pull to finish before notifying?
    // Or just async. Since performSync calls pull after push, we are in background thread.
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    [[NetworkManager sharedManager] fetchIngredients:familyId updatedSince:lastSyncTime success:^(id  _Nullable response) {
        if ([response isKindOfClass:[NSArray class]]) {
            NSArray *serverIngredients = response;
            for (NSDictionary *dict in serverIngredients) {
                NSString *serverId = dict[@"id"];
                if (!serverId) continue;
                
                Ingredient *localIng = [[DBManager sharedManager] fetchIngredientByServerId:serverId];
                
                Ingredient *serverIng = [Ingredient yy_modelWithDictionary:dict];
                serverIng._id = serverId;
                
                if (dict[@"deleted_at"] && ![dict[@"deleted_at"] isEqual:[NSNull null]]) {
                     if (localIng) {
                         [[DBManager sharedManager] hardDeleteIngredient:localIng.localId];
                     }
                } else {
                    if (localIng) {
                        // Protect local pending changes
                        if ([localIng.syncStatus isEqualToString:@"pending"] || [localIng.syncStatus isEqualToString:@"failed"]) {
                            NSLog(@"Skipping overwrite of local pending ingredient: %@", localIng.name);
                            continue;
                        }
                        
                        // Overwrite
                        serverIng.localId = localIng.localId;
                        serverIng.syncStatus = @"synced";
                        [[DBManager sharedManager] saveIngredient:serverIng];
                    } else {
                        // Insert
                        serverIng.localId = [[NSUUID UUID] UUIDString];
                        serverIng.syncStatus = @"synced";
                        [[DBManager sharedManager] saveIngredient:serverIng];
                    }
                }
            }
            
            NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
            NSString *now = [formatter stringFromDate:[NSDate date]];
            [[NSUserDefaults standardUserDefaults] setObject:now forKey:@"kLastSyncTime"];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kSyncDidFinishNotification object:nil];
        });
        dispatch_semaphore_signal(sema);
        
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"Pull failed: %@", error);
        dispatch_semaphore_signal(sema);
    }];
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

@end
