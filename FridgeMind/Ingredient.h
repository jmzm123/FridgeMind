#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Ingredient : NSObject
@property (nonatomic, copy) NSString *_id;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) double quantity;
@property (nonatomic, copy) NSString *unit;
@property (nonatomic, copy) NSString *expirationDate;
@property (nonatomic, copy) NSString *imageUrl;
@end

NS_ASSUME_NONNULL_END
