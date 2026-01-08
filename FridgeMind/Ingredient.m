#import "Ingredient.h"

@implementation Ingredient

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"_id" : @[@"id", @"_id"]
    };
}

@end
