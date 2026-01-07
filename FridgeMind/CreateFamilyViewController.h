#import <UIKit/UIKit.h>

typedef void(^CompletionBlock)(void);

@interface CreateFamilyViewController : UIViewController
@property (nonatomic, copy) CompletionBlock completionBlock;
@end
