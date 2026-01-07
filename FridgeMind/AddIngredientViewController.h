#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AddIngredientViewController : UIViewController
@property (nonatomic, strong) NSString *familyId;
@property (nonatomic, copy) void (^completionBlock)(void);
@end

NS_ASSUME_NONNULL_END
