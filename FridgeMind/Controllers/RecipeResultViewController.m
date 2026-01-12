
#import "RecipeResultViewController.h"
#import "NetworkManager.h"
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface RecipeResultViewController ()

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIButton *saveButton;

@end

@implementation RecipeResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"推荐菜谱";
    
    [self setupUI];
    [self displayRecipe];
}

- (void)setupUI {
    // Save Button
    self.saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.saveButton setTitle:@"保存到菜单" forState:UIControlStateNormal];
    self.saveButton.backgroundColor = [UIColor systemGreenColor];
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.saveButton.layer.cornerRadius = 8;
    self.saveButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.saveButton addTarget:self action:@selector(saveTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.saveButton];
    
    [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.height.mas_equalTo(50);
    }];
    
    // TextView
    self.textView = [[UITextView alloc] init];
    self.textView.editable = NO;
    self.textView.font = [UIFont systemFontOfSize:16];
    self.textView.textColor = [UIColor blackColor];
    [self.view addSubview:self.textView];
    
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.bottom.equalTo(self.saveButton.mas_top).offset(-20);
    }];
}

- (void)displayRecipe {
    if (!self.recipeData) return;
    
    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] init];
    
    // Name
    NSString *name = self.recipeData[@"name"] ?: @"未命名菜谱";
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n\n", name] attributes:@{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:24],
        NSForegroundColorAttributeName: [UIColor blackColor]
    }]];
    
    // Description
    NSString *desc = self.recipeData[@"description"] ?: @"";
    if (desc.length > 0) {
        [content appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n\n", desc] attributes:@{
            NSFontAttributeName: [UIFont italicSystemFontOfSize:16],
            NSForegroundColorAttributeName: [UIColor grayColor]
        }]];
    }
    
    // Ingredients
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:@"食材清单：\n" attributes:@{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:18],
        NSForegroundColorAttributeName: [UIColor darkGrayColor]
    }]];
    
    NSArray *ingredients = self.recipeData[@"ingredients"];
    if ([ingredients isKindOfClass:[NSArray class]]) {
        for (NSDictionary *ing in ingredients) {
            NSString *qty = ing[@"quantity"] ?: ing[@"amount"] ?: @"";
            NSString *unit = ing[@"unit"] ?: @"";
            NSString *line = [NSString stringWithFormat:@"• %@ %@%@\n", ing[@"name"], qty, unit];
            [content appendAttributedString:[[NSAttributedString alloc] initWithString:line attributes:@{
                NSFontAttributeName: [UIFont systemFontOfSize:16]
            }]];
        }
    }
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    
    // Steps
    [content appendAttributedString:[[NSAttributedString alloc] initWithString:@"烹饪步骤：\n" attributes:@{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:18],
        NSForegroundColorAttributeName: [UIColor darkGrayColor]
    }]];
    
    NSArray *steps = self.recipeData[@"steps"];
    if ([steps isKindOfClass:[NSArray class]]) {
        for (int i = 0; i < steps.count; i++) {
            NSString *step = steps[i];
            NSString *line = [NSString stringWithFormat:@"%d. %@\n\n", i + 1, step];
            [content appendAttributedString:[[NSAttributedString alloc] initWithString:line attributes:@{
                NSFontAttributeName: [UIFont systemFontOfSize:16]
            }]];
        }
    }
    
    self.textView.attributedText = content;
}

- (void)saveTapped {
    NSString *familyId = [NetworkManager sharedManager].currentFamilyId;
    if (!familyId) return;
    
    // Prepare params
    // recipeData matches API expectation roughly, but need to ensure keys
    // API: name, ingredients, steps, description, cookingMethod
    
    NSMutableDictionary *params = [self.recipeData mutableCopy];
    // Remove extra fields if any? API is permissive usually or ignores.
    
    [SVProgressHUD show];
    [[NetworkManager sharedManager] createDish:params familyId:familyId success:^(id  _Nullable response) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showSuccessWithStatus:@"保存成功"];
        [self.navigationController popViewControllerAnimated:YES];
    } failure:^(NSError * _Nonnull error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }];
}

@end
