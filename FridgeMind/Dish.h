#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DishIngredient : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) double quantity;
@property (nonatomic, copy) NSString *unit;
@property (nonatomic, copy) NSString *storageType;
@end

@interface Dish : NSObject
@property (nonatomic, copy) NSString *dishId;
@property (nonatomic, copy) NSString *familyId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSArray<DishIngredient *> *ingredients;
@property (nonatomic, copy) NSString *createdAt;
@end

NS_ASSUME_NONNULL_END
