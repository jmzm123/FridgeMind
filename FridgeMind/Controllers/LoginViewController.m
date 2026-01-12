#import "LoginViewController.h"
#import <Masonry/Masonry.h>
#import "NetworkManager.h"
#import "FamilyListViewController.h"

@interface LoginViewController ()
@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UITextField *codeField;
@property (nonatomic, strong) UIButton *sendCodeButton;
@property (nonatomic, strong) UIButton *loginButton;
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupUI];
}

- (void)setupUI {
    // Email Field
    self.emailField = [[UITextField alloc] init];
    self.emailField.placeholder = @"请输入邮箱";
    self.emailField.borderStyle = UITextBorderStyleRoundedRect;
    self.emailField.text = @"test_user@example.com"; // Default for test
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.view addSubview:self.emailField];
    
    [self.emailField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(50);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.height.mas_equalTo(44);
    }];
    
    // Code Field
    self.codeField = [[UITextField alloc] init];
    self.codeField.placeholder = @"请输入验证码";
    self.codeField.borderStyle = UITextBorderStyleRoundedRect;
    self.codeField.text = @"123456"; // Default for test
    self.codeField.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:self.codeField];
    
    [self.codeField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.emailField.mas_bottom).offset(20);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-120); // Space for button
        make.height.mas_equalTo(44);
    }];
    
    // Send Code Button
    self.sendCodeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.sendCodeButton setTitle:@"发送验证码" forState:UIControlStateNormal];
    [self.sendCodeButton addTarget:self action:@selector(sendCodeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.sendCodeButton];
    
    [self.sendCodeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.codeField.mas_right).offset(10);
        make.right.equalTo(self.view).offset(-20);
        make.centerY.equalTo(self.codeField);
        make.height.mas_equalTo(44);
    }];
    
    // Login Button
    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.loginButton setTitle:@"登录" forState:UIControlStateNormal];
    self.loginButton.backgroundColor = [UIColor systemBlueColor];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.layer.cornerRadius = 8;
    [self.loginButton addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginButton];
    
    [self.loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.codeField.mas_bottom).offset(40);
        make.left.right.equalTo(self.emailField);
        make.height.mas_equalTo(50);
    }];
}

#pragma mark - Actions

- (void)sendCodeTapped {
    NSString *email = self.emailField.text;
    if (email.length == 0) return;
    
    [[NetworkManager sharedManager] sendCodeToEmail:email success:^(id  _Nullable response) {
        NSLog(@"Code sent!");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"成功" message:@"验证码已发送到您的邮箱" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"Failed to send code: %@", error);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)loginTapped {
    NSString *email = self.emailField.text;
    NSString *code = self.codeField.text;
    
    if (email.length == 0 || code.length == 0) return;
    
    [[NetworkManager sharedManager] verifyCode:code email:email success:^(id  _Nullable response) {
        NSLog(@"Login Success: %@", response);
        // Switch to Main Interface
        FamilyListViewController *familyVC = [[FamilyListViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:familyVC];
        
        // Ensure UI update on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            UIWindow *window = self.view.window;
            window.rootViewController = nav;
            [window makeKeyAndVisible];
            
            // Optional: Animation
            [UIView transitionWithView:window
                              duration:0.3
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:nil
                            completion:nil];
        });
        
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"Login Failed: %@", error);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

@end
