#import "AddIngredientViewController.h"
#import <Masonry/Masonry.h>
#import "NetworkManager.h"

@interface AddIngredientViewController ()
@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) UITextField *quantityField;
@property (nonatomic, strong) UITextField *unitField;
@property (nonatomic, strong) UIDatePicker *datePicker;
@end

@implementation AddIngredientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Add Ingredient";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupUI];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(saveTapped)];
}

- (void)setupUI {
    // Name
    self.nameField = [self createTextField:@"Name (e.g. Milk)"];
    [self.view addSubview:self.nameField];
    
    // Quantity
    self.quantityField = [self createTextField:@"Quantity (e.g. 1.5)"];
    self.quantityField.keyboardType = UIKeyboardTypeDecimalPad;
    [self.view addSubview:self.quantityField];
    
    // Unit
    self.unitField = [self createTextField:@"Unit (e.g. L, kg)"];
    [self.view addSubview:self.unitField];
    
    // Date Picker
    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.datePickerMode = UIDatePickerModeDate;
    if (@available(iOS 13.4, *)) {
        self.datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    [self.view addSubview:self.datePicker];
    
    // Layout
    [self.nameField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(20);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.height.mas_equalTo(44);
    }];
    
    [self.quantityField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameField.mas_bottom).offset(15);
        make.left.right.height.equalTo(self.nameField);
    }];
    
    [self.unitField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.quantityField.mas_bottom).offset(15);
        make.left.right.height.equalTo(self.nameField);
    }];
    
    [self.datePicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.unitField.mas_bottom).offset(15);
        make.centerX.equalTo(self.view);
    }];
}

- (UITextField *)createTextField:(NSString *)placeholder {
    UITextField *tf = [[UITextField alloc] init];
    tf.placeholder = placeholder;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    return tf;
}

- (void)saveTapped {
    NSString *name = self.nameField.text;
    if (name.length == 0) return;
    
    double quantity = [self.quantityField.text doubleValue];
    NSString *unit = self.unitField.text;
    
    // Format Date
    NSDateFormatter *isoFormatter = [[NSDateFormatter alloc] init];
    isoFormatter.dateFormat = @"yyyy-MM-dd";
    NSString *dateStr = [isoFormatter stringFromDate:self.datePicker.date];
    
    NSDictionary *params = @{
        @"familyId": self.familyId,
        @"name": name,
        @"quantity": @(quantity),
        @"unit": unit ?: @"",
        @"expirationDate": dateStr
    };
    
    [[NetworkManager sharedManager] addIngredient:params success:^(id  _Nullable response) {
        if (self.completionBlock) {
            self.completionBlock();
        }
        [self.navigationController popViewControllerAnimated:YES];
    } failure:^(NSError * _Nonnull error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

@end
