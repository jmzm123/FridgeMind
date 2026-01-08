#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Ingredient : NSObject
@property (nonatomic, copy) NSString *localId; // UUID
@property (nonatomic, copy) NSString *_id; // server_id
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) double quantity;
@property (nonatomic, copy) NSString *unit;
@property (nonatomic, copy) NSString *expirationDate;
@property (nonatomic, copy) NSString *createdAt;
@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, copy) NSString *storageType; // frozen, chilled, pantry

// Sync related
@property (nonatomic, copy) NSString *syncStatus; // pending, synced, failed
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, assign) BOOL deleted;
@end

NS_ASSUME_NONNULL_END
