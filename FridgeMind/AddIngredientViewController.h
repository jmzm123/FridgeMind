#import <UIKit/UIKit.h>
#import "Ingredient.h"

NS_ASSUME_NONNULL_BEGIN

@interface AddIngredientViewController : UIViewController
@property (nonatomic, strong) NSString *familyId;
@property (nonatomic, strong) Ingredient *existingIngredient;
@property (nonatomic, copy) void (^completionBlock)(void);
@end

NS_ASSUME_NONNULL_END
