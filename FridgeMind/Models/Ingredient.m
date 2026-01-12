#import "Ingredient.h"

@implementation Ingredient

+ (NSDictionary *)modelCustomPropertyMapper {
    return @{
        @"_id" : @[@"id", @"_id"],
        @"createdAt" : @[@"created_at", @"createdAt", @"create_time"],
        @"updatedAt" : @[@"updated_at", @"updatedAt", @"update_time"],
        @"imageUrl" : @[@"image_url", @"imageUrl", @"img"],
        @"storageType" : @[@"storage_type", @"storageType"],
        @"expirationDate" : @[@"expiration_date", @"expire_at", @"expirationDate", @"expiry_date"]
    };
}


@end
