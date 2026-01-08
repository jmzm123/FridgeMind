#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DishIngredient : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *quantity; // Changed to string to support "适量" etc. if needed, or keep number if consistent
@property (nonatomic, copy) NSString *unit;
@property (nonatomic, copy) NSString *storageType;
@end

@interface Dish : NSObject
@property (nonatomic, copy) NSString *dishId;
@property (nonatomic, copy) NSString *familyId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSArray<NSString *> *steps;
@property (nonatomic, strong) NSArray<DishIngredient *> *ingredients;
@property (nonatomic, copy) NSString *cookingMethod;
@property (nonatomic, copy) NSString *createdAt;
@end

NS_ASSUME_NONNULL_END
