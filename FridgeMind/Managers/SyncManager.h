#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SyncManager : NSObject

+ (instancetype)sharedManager;

extern NSString * const kSyncDidFinishNotification;

- (void)sync; // Trigger sync manually or automatically

// For App Delegate hooks
- (void)startMonitoring;

@end

NS_ASSUME_NONNULL_END
