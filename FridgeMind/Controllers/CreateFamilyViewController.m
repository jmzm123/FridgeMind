#import "CreateFamilyViewController.h"
#import <Masonry/Masonry.h>
#import "NetworkManager.h"

@interface CreateFamilyViewController ()
@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) UIButton *createButton;
@end

@implementation CreateFamilyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"创建家庭";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupUI];
}

- (void)setupUI {
    self.nameField = [[UITextField alloc] init];
    self.nameField.placeholder = @"家庭名称";
    self.nameField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:self.nameField];
    
    self.createButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.createButton setTitle:@"创建" forState:UIControlStateNormal];
    [self.createButton addTarget:self action:@selector(createTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.createButton];
    
    [self.nameField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(50);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.height.mas_equalTo(44);
    }];
    
    [self.createButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameField.mas_bottom).offset(20);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(44);
        make.width.mas_equalTo(120);
    }];
}

- (void)createTapped {
    NSString *name = self.nameField.text;
    if (name.length == 0) return;
    
    [[NetworkManager sharedManager] createFamily:name success:^(id  _Nullable response) {
        if (self.completionBlock) {
            self.completionBlock();
        }
        [self.navigationController popViewControllerAnimated:YES];
    } failure:^(NSError * _Nonnull error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

@end
