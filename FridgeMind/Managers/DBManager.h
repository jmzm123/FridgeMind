#import <Foundation/Foundation.h>
#import "Ingredient.h"

NS_ASSUME_NONNULL_BEGIN

@interface DBManager : NSObject

+ (instancetype)sharedManager;

// CRUD for Ingredient
- (void)saveIngredient:(Ingredient *)ingredient; // Insert or Update based on local_id
- (void)markIngredientAsDeleted:(NSString *)localId;
- (void)hardDeleteIngredient:(NSString *)localId;
- (NSArray<Ingredient *> *)fetchAllIngredients; // Returns non-deleted + pending deleted? Spec says fetch all from DB.
- (NSArray<Ingredient *> *)fetchIngredientsForSync; // pending or failed

// Sync Helpers
- (void)updateIngredientAfterSync:(Ingredient *)ingredient;
- (Ingredient * _Nullable)fetchIngredientByServerId:(NSString *)serverId;
- (Ingredient * _Nullable)fetchIngredientByLocalId:(NSString *)localId;

@end

NS_ASSUME_NONNULL_END
