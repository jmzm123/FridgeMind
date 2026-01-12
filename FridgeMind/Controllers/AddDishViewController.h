#import <UIKit/UIKit.h>

@class Dish;

NS_ASSUME_NONNULL_BEGIN

@interface AddDishViewController : UIViewController

@property (nonatomic, copy) NSString *familyId;
@property (nonatomic, strong, nullable) Dish *existingDish;
@property (nonatomic, copy, nullable) void (^onSave)(void);

@end

NS_ASSUME_NONNULL_END
