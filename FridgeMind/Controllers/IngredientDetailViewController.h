#import <UIKit/UIKit.h>
#import "Ingredient.h"

NS_ASSUME_NONNULL_BEGIN

@interface IngredientDetailViewController : UIViewController

@property (nonatomic, strong) Ingredient *ingredient;
@property (nonatomic, strong) NSString *familyId;

@end

NS_ASSUME_NONNULL_END
