#import "AddIngredientViewController.h"
#import <Masonry/Masonry.h>
#import "NetworkManager.h"
#import "DBManager.h"
#import "SyncManager.h"
#import "Ingredient.h"

@interface AddIngredientViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) UITextField *quantityField;
@property (nonatomic, strong) UITextField *unitField;
@property (nonatomic, strong) UISegmentedControl *storageControl;
@property (nonatomic, strong) UIDatePicker *expirationDatePicker;
@property (nonatomic, strong) UIDatePicker *putInDatePicker;
@property (nonatomic, strong) UILabel *expirationLabel;
@property (nonatomic, strong) UILabel *putInLabel;
@property (nonatomic, strong) UIButton *cameraButton;
@end

@implementation AddIngredientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.existingIngredient ? @"编辑食材" : @"添加食材";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupUI];
    
    if (self.existingIngredient) {
        self.nameField.text = self.existingIngredient.name;
        self.quantityField.text = [NSString stringWithFormat:@"%g", self.existingIngredient.quantity];
        self.unitField.text = self.existingIngredient.unit;
        
        if (self.existingIngredient.storageType) {
            if ([self.existingIngredient.storageType isEqualToString:@"frozen"]) {
                self.storageControl.selectedSegmentIndex = 1;
            } else if ([self.existingIngredient.storageType isEqualToString:@"pantry"]) {
                self.storageControl.selectedSegmentIndex = 2;
            } else {
                self.storageControl.selectedSegmentIndex = 0;
            }
        }
        
        NSDateFormatter *f = [[NSDateFormatter alloc] init];
        f.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        
        if (self.existingIngredient.expirationDate) {
            NSDate *d = [f dateFromString:self.existingIngredient.expirationDate];
            if (!d) {
                f.dateFormat = @"yyyy-MM-dd"; // Fallback
                d = [f dateFromString:self.existingIngredient.expirationDate];
                f.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ"; // Reset
            }
            if (d) self.expirationDatePicker.date = d;
        }
        
        if (self.existingIngredient.createdAt) {
             NSDate *d = [f dateFromString:self.existingIngredient.createdAt];
             if (d) self.putInDatePicker.date = d;
        }
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(saveTapped)];
}

- (void)setupUI {
    // Camera Button
    self.cameraButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cameraButton setImage:[UIImage systemImageNamed:@"camera"] forState:UIControlStateNormal];
    [self.cameraButton addTarget:self action:@selector(cameraTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cameraButton];
    
    [self.cameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.width.height.mas_equalTo(44);
    }];

    // Name
    self.nameField = [self createTextField:@"名称 (例如: 牛奶)"];
    [self.view addSubview:self.nameField];
    
    // Quantity
    self.quantityField = [self createTextField:@"数量 (例如: 1.5)"];
    self.quantityField.keyboardType = UIKeyboardTypeDecimalPad;
    [self.view addSubview:self.quantityField];
    
    // Unit
    self.unitField = [self createTextField:@"单位 (例如: 升, 公斤)"];
    [self.view addSubview:self.unitField];
    
    // Storage Type
    self.storageControl = [[UISegmentedControl alloc] initWithItems:@[@"冷藏", @"冷冻", @"其他"]];
    self.storageControl.selectedSegmentIndex = 0;
    [self.view addSubview:self.storageControl];
    
    // Put In Date Label & Picker
    self.putInLabel = [[UILabel alloc] init];
    self.putInLabel.text = @"放入时间:";
    self.putInLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:self.putInLabel];
    
    self.putInDatePicker = [[UIDatePicker alloc] init];
    self.putInDatePicker.datePickerMode = UIDatePickerModeDateAndTime;
    if (@available(iOS 13.4, *)) {
        self.putInDatePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
    }
    [self.view addSubview:self.putInDatePicker];
    
    // Expiration Date Label & Picker
    self.expirationLabel = [[UILabel alloc] init];
    self.expirationLabel.text = @"过期时间:";
    self.expirationLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:self.expirationLabel];

    self.expirationDatePicker = [[UIDatePicker alloc] init];
    self.expirationDatePicker.datePickerMode = UIDatePickerModeDateAndTime;
    if (@available(iOS 13.4, *)) {
        self.expirationDatePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
    }
    // Default expiration + 7 days
    self.expirationDatePicker.date = [NSDate dateWithTimeIntervalSinceNow:7*24*3600];
    [self.view addSubview:self.expirationDatePicker];
    
    // Layout
    [self.nameField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(20);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.cameraButton.mas_left).offset(-10);
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
    
    [self.storageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.unitField.mas_bottom).offset(15);
        make.left.right.equalTo(self.nameField);
        make.height.mas_equalTo(32);
    }];
    
    // Put In Date Layout
    [self.putInLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.storageControl.mas_bottom).offset(20);
        make.left.equalTo(self.nameField);
    }];
    
    [self.putInDatePicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.putInLabel);
        make.right.equalTo(self.nameField);
    }];
    
    // Expiration Date Layout
    [self.expirationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.putInLabel.mas_bottom).offset(20);
        make.left.equalTo(self.nameField);
    }];
    
    [self.expirationDatePicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.expirationLabel);
        make.right.equalTo(self.nameField);
    }];
}

- (UITextField *)createTextField:(NSString *)placeholder {
    UITextField *tf = [[UITextField alloc] init];
    tf.placeholder = placeholder;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    return tf;
}

- (void)cameraTapped {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"选择图片来源" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"相机" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showImagePicker:UIImagePickerControllerSourceTypeCamera];
        }]];
    }
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)showImagePicker:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = sourceType;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - Image Picker

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (!image) return;
    
    // Resize image to max 1024px to speed up upload and AI processing
    UIImage *resizedImage = [self resizeImage:image toMaxDimension:1024];
    
    // Compress and convert to Base64
    NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.6); // Slightly higher compression
    NSString *base64 = [imageData base64EncodedStringWithOptions:0];
    
    // Show Loading
    UIAlertController *loading = [UIAlertController alertControllerWithTitle:@"识别中..." message:@"AI正在查看你的食材..." preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:loading animated:YES completion:nil];
    
    [[NetworkManager sharedManager] identifyIngredientsWithImageBase64:base64 success:^(id  _Nullable response) {
        [loading dismissViewControllerAnimated:YES completion:^{
            // Parse response: array of ingredients
            NSArray *items = response;
            if ([items isKindOfClass:[NSArray class]] && items.count > 0) {
                NSDictionary *item = items[0]; // Take first one for now
                self.nameField.text = item[@"name"];
                self.quantityField.text = [NSString stringWithFormat:@"%@", item[@"quantity"] ?: @1];
                self.unitField.text = item[@"unit"];
            } else {
                [self showError:[NSError errorWithDomain:@"com.fridgemind" code:404 userInfo:@{NSLocalizedDescriptionKey: @"未识别出食材。"}]];
            }
        }];
    } failure:^(NSError * _Nonnull error) {
        [loading dismissViewControllerAnimated:YES completion:^{
            [self showError:error];
        }];
    }];
}

- (UIImage *)resizeImage:(UIImage *)image toMaxDimension:(CGFloat)maxDimension {
    if (image.size.width <= maxDimension && image.size.height <= maxDimension) {
        return image;
    }
    
    CGFloat aspectRatio = image.size.width / image.size.height;
    CGSize newSize;
    if (image.size.width > image.size.height) {
        newSize = CGSizeMake(maxDimension, maxDimension / aspectRatio);
    } else {
        newSize = CGSizeMake(maxDimension * aspectRatio, maxDimension);
    }
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)saveTapped {
    NSString *name = self.nameField.text;
    if (name.length == 0) return;
    
    double quantity = [self.quantityField.text doubleValue];
    NSString *unit = self.unitField.text;
    
    // Format Date
    NSDateFormatter *isoFormatter = [[NSDateFormatter alloc] init];
    isoFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    NSString *expireStr = [isoFormatter stringFromDate:self.expirationDatePicker.date];
    NSString *createStr = [isoFormatter stringFromDate:self.putInDatePicker.date];
    
    NSString *storageType = @"chilled";
    if (self.storageControl.selectedSegmentIndex == 1) {
        storageType = @"frozen";
    } else if (self.storageControl.selectedSegmentIndex == 2) {
        storageType = @"pantry";
    }
    
    Ingredient *ing = self.existingIngredient ?: [[Ingredient alloc] init];
    ing.name = name;
    ing.quantity = quantity;
    ing.unit = unit ?: @"";
    ing.expirationDate = expireStr;
    ing.createdAt = createStr;
    ing.storageType = storageType;
    ing.updatedAt = [NSDate date];
    ing.syncStatus = @"pending";
    ing.deleted = NO;
    
    if (!ing.localId) {
        ing.localId = [[NSUUID UUID] UUIDString];
    }
    
    [[DBManager sharedManager] saveIngredient:ing];
    // [[SyncManager sharedManager] sync]; // Trigger sync
    
    if (self.completionBlock) {
        self.completionBlock();
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
