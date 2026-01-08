#import "Dish.h"
#import <YYModel/YYModel.h>

@implementation DishIngredient
@end

@implementation Dish

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"dishId" : @[@"id", @"_id"],
        @"familyId" : @"family_id",
        @"createdAt" : @"created_at"
    };
}

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"ingredients" : [DishIngredient class]};
}

@end
