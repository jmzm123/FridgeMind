#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Ingredient : NSObject
@property (nonatomic, copy) NSString *localId; // UUID 本地创建时立即生成（UUID）不依赖网络
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

/// 根据食材名称获取预设图标URL (Tencent COS)
+ (nullable NSString *)imageURLForName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
