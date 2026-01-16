#import "DBManager.h"
#import <sqlite3.h>

@interface DBManager ()
@property (nonatomic, assign) sqlite3 *db;
@property (nonatomic, strong) NSString *databasePath;
@property (nonatomic, strong) dispatch_queue_t dbQueue;
@end

@implementation DBManager

+ (instancetype)sharedManager {
    static DBManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DBManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *docsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        _databasePath = [docsDir stringByAppendingPathComponent:@"fridgemind.db"];
        _dbQueue = dispatch_queue_create("com.fridgemind.db", DISPATCH_QUEUE_SERIAL);
        
        // Open DB immediately and keep open
        if (sqlite3_open([_databasePath UTF8String], &_db) != SQLITE_OK) {
            NSLog(@"Failed to open database at %@", _databasePath);
        } else {
            [self createTable];
        }
    }
    return self;
}

// Deprecated/No-op to match interface if kept, but better to remove from interface.
// If I remove from interface, I don't need them here.
// I will remove them from .h as well.

- (void)createTable {
    // Already running on main thread during init, which is fine as it's the only access at that point.
    // Or we can wrap it, but init is implicitly safe if sharedManager is accessed safely.
    // For extra safety:
    dispatch_sync(self.dbQueue, ^{
        char *errMsg;
        const char *sql = "CREATE TABLE IF NOT EXISTS IngredientLocal ("
                          "local_id TEXT PRIMARY KEY, "
                          "server_id TEXT, "
                          "name TEXT, "
                          "quantity REAL, "
                          "unit TEXT, "
                          "expiration_date TEXT, "
                          "created_at TEXT, "
                          "image_url TEXT, "
                          "storage_type TEXT, "
                          "sync_status TEXT, "
                          "updated_at REAL, "
                          "deleted INTEGER)";
        
        if (sqlite3_exec(self.db, sql, NULL, NULL, &errMsg) != SQLITE_OK) {
            NSLog(@"Failed to create table: %s", errMsg);
        }
    });
}

- (void)saveIngredient:(Ingredient *)ingredient {
    dispatch_sync(self.dbQueue, ^{
        // Check if exists
        NSString *checkSql = [NSString stringWithFormat:@"SELECT count(*) FROM IngredientLocal WHERE local_id = '%@'", ingredient.localId];
        sqlite3_stmt *statement;
        BOOL exists = NO;
        if (sqlite3_prepare_v2(self.db, [checkSql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                exists = sqlite3_column_int(statement, 0) > 0;
            }
        }
        sqlite3_finalize(statement);
        
        NSString *sql;
        if (exists) {
            sql = @"UPDATE IngredientLocal SET name=?, quantity=?, unit=?, expiration_date=?, created_at=?, image_url=?, storage_type=?, sync_status=?, updated_at=?, deleted=?, server_id=? WHERE local_id=?";
        } else {
            sql = @"INSERT INTO IngredientLocal (name, quantity, unit, expiration_date, created_at, image_url, storage_type, sync_status, updated_at, deleted, server_id, local_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        }
        
        if (sqlite3_prepare_v2(self.db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [ingredient.name UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_double(statement, 2, ingredient.quantity);
            sqlite3_bind_text(statement, 3, [ingredient.unit UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 4, [ingredient.expirationDate UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 5, [ingredient.createdAt UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 6, [ingredient.imageUrl UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 7, [ingredient.storageType UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 8, [ingredient.syncStatus UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_double(statement, 9, [ingredient.updatedAt timeIntervalSince1970]);
            sqlite3_bind_int(statement, 10, ingredient.deleted ? 1 : 0);
            if (ingredient._id) {
                sqlite3_bind_text(statement, 11, [ingredient._id UTF8String], -1, SQLITE_TRANSIENT);
            } else {
                sqlite3_bind_null(statement, 11);
            }
            sqlite3_bind_text(statement, 12, [ingredient.localId UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) != SQLITE_DONE) {
                NSLog(@"Error saving ingredient: %s", sqlite3_errmsg(self.db));
            }
        }
        sqlite3_finalize(statement);
    });
}

- (void)markIngredientAsDeleted:(NSString *)localId {
    dispatch_sync(self.dbQueue, ^{
        NSString *sql = @"UPDATE IngredientLocal SET deleted=1, sync_status='pending', updated_at=? WHERE local_id=?";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(self.db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_double(statement, 1, [[NSDate date] timeIntervalSince1970]);
            sqlite3_bind_text(statement, 2, [localId UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(statement) != SQLITE_DONE) {
                NSLog(@"Error marking deleted: %s", sqlite3_errmsg(self.db));
            }
        }
        sqlite3_finalize(statement);
    });
}

- (void)hardDeleteIngredient:(NSString *)localId {
    dispatch_sync(self.dbQueue, ^{
        NSString *sql = @"DELETE FROM IngredientLocal WHERE local_id=?";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(self.db, [sql UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [localId UTF8String], -1, SQLITE_TRANSIENT);
            if (sqlite3_step(statement) != SQLITE_DONE) {
                NSLog(@"Error hard deleting: %s", sqlite3_errmsg(self.db));
            }
        }
        sqlite3_finalize(statement);
    });
}

- (NSArray<Ingredient *> *)fetchAllIngredients {
    NSMutableArray *result = [NSMutableArray array];
    dispatch_sync(self.dbQueue, ^{
        // Spec says: "There exists any record where sync_status != synced" for triggers.
        // For UI display, we usually want non-deleted items.
        const char *sql = "SELECT * FROM IngredientLocal WHERE deleted = 0 ORDER BY created_at DESC";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(self.db, sql, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                [result addObject:[self ingredientFromStatement:statement]];
            }
        }
        sqlite3_finalize(statement);
    });
    return result;
}

- (NSArray<Ingredient *> *)fetchIngredientsForSync {
    NSMutableArray *result = [NSMutableArray array];
    dispatch_sync(self.dbQueue, ^{
        const char *sql = "SELECT * FROM IngredientLocal WHERE sync_status IN ('pending', 'failed') ORDER BY updated_at ASC";
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(self.db, sql, -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                [result addObject:[self ingredientFromStatement:statement]];
            }
        }
        sqlite3_finalize(statement);
    });
    return result;
}

- (Ingredient *)fetchIngredientByServerId:(NSString *)serverId {
    __block Ingredient *ing = nil;
    dispatch_sync(self.dbQueue, ^{
        const char *sql = "SELECT * FROM IngredientLocal WHERE server_id = ?";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(self.db, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [serverId UTF8String], -1, SQLITE_TRANSIENT);
            if (sqlite3_step(statement) == SQLITE_ROW) {
                ing = [self ingredientFromStatement:statement];
            }
        }
        sqlite3_finalize(statement);
    });
    return ing;
}

- (Ingredient *)fetchIngredientByLocalId:(NSString *)localId {
    __block Ingredient *ing = nil;
    dispatch_sync(self.dbQueue, ^{
        const char *sql = "SELECT * FROM IngredientLocal WHERE local_id = ?";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(self.db, sql, -1, &statement, NULL) == SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [localId UTF8String], -1, SQLITE_TRANSIENT);
            if (sqlite3_step(statement) == SQLITE_ROW) {
                ing = [self ingredientFromStatement:statement];
            }
        }
        sqlite3_finalize(statement);
    });
    return ing;
}

- (void)updateIngredientAfterSync:(Ingredient *)ingredient {
    // Just reuse save logic but caller ensures fields are correct (synced status etc)
    [self saveIngredient:ingredient];
}

- (Ingredient *)ingredientFromStatement:(sqlite3_stmt *)statement {
    Ingredient *ing = [[Ingredient alloc] init];
    ing.localId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
    
    char *serverId = (char *)sqlite3_column_text(statement, 1);
    if (serverId) ing._id = [NSString stringWithUTF8String:serverId];
    
    char *name = (char *)sqlite3_column_text(statement, 2);
    if (name) ing.name = [NSString stringWithUTF8String:name];
    
    ing.quantity = sqlite3_column_double(statement, 3);
    
    char *unit = (char *)sqlite3_column_text(statement, 4);
    if (unit) ing.unit = [NSString stringWithUTF8String:unit];
    
    char *exp = (char *)sqlite3_column_text(statement, 5);
    if (exp) ing.expirationDate = [NSString stringWithUTF8String:exp];
    
    char *created = (char *)sqlite3_column_text(statement, 6);
    if (created) ing.createdAt = [NSString stringWithUTF8String:created];
    
    char *img = (char *)sqlite3_column_text(statement, 7);
    if (img) ing.imageUrl = [NSString stringWithUTF8String:img];
    
    char *storage = (char *)sqlite3_column_text(statement, 8);
    if (storage) ing.storageType = [NSString stringWithUTF8String:storage];
    
    char *sync = (char *)sqlite3_column_text(statement, 9);
    if (sync) ing.syncStatus = [NSString stringWithUTF8String:sync];
    
    ing.updatedAt = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(statement, 10)];
    ing.deleted = sqlite3_column_int(statement, 11) != 0;
    
    return ing;
}

- (void)dealloc {
    if (_db) {
        sqlite3_close(_db);
    }
}

@end
