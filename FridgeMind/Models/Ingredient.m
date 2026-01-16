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

+ (nullable NSString *)imageURLForName:(NSString *)name {
    if (!name || name.length == 0) return nil;
    
    static NSDictionary *mapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mapping = @{
            @"牛奶": @"Milk",
            @"奶酪": @"Cheese",
            @"酸奶": @"Yogurt",
            @"黄油": @"Butter",
            @"鸡蛋": @"Eggs",
            @"苹果": @"Apple",
            @"葡萄": @"Grapes",
            @"草莓": @"Strawberry",
            @"蓝莓": @"Blueberry",
            @"柠檬": @"Lemon",
            @"西瓜": @"Watermelon",
            @"桃子": @"Peach",
            @"樱桃": @"Cherry",
            @"梨": @"Pear",
            @"生菜": @"Lettuce",
            @"菠菜": @"Spinach",
            @"卷心菜": @"Cabbage",
            @"西兰花": @"Broccoli",
            @"花菜": @"Cauliflower",
            @"胡萝卜": @"Carrot",
            @"黄瓜": @"Cucumber",
            @"番茄": @"Tomato",
            @"甜椒": @"Bell Pepper",
            @"蘑菇": @"Mushroom",
            @"芦笋": @"Asparagus",
            @"芹菜": @"Celery",
            @"西葫芦": @"Zucchini",
            @"玉米": @"Corn",
            @"茄子": @"Eggplant",
            @"辣椒": @"Chili Pepper",
            @"鸡胸肉": @"Chicken Breast",
            @"牛排": @"Steak",
            @"猪肉": @"Pork",
            @"培根": @"Bacon",
            @"香肠": @"Sausage",
            @"三文鱼": @"Salmon",
            @"虾": @"Shrimp",
            @"豆腐": @"Tofu",
            @"可乐": @"Cola",
            @"果汁": @"Juice",
            @"啤酒": @"Beer",
            @"矿泉水": @"Water",
            @"番茄酱": @"Ketchup",
            @"蛋黄酱": @"Mayonnaise",
            @"果酱": @"Jam",
            @"味噌": @"Miso",
            @"巧克力": @"Chocolate",
            @"冰淇淋": @"Ice Cream",
            @"蛋糕": @"Cake",
            @"牛油果": @"Avocado"
        };
    });
    
    NSString *englishName = mapping[name];
    if (englishName) {
        // Handle spaces in English names for URL if necessary, though usually safe or already encoded.
        // Assuming standard URL format.
        NSString *encodedName = [englishName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
        return [NSString stringWithFormat:@"https://fridge-1358341988.cos.ap-guangzhou.myqcloud.com/output/%@.png", encodedName];
    }
    
    return nil;
}

@end
