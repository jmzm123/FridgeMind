#import "AddIngredientViewController.h"
#import <Masonry/Masonry.h>
#import "NetworkManager.h"

@interface AddIngredientViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) UITextField *quantityField;
@property (nonatomic, strong) UITextField *unitField;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UIButton *cameraButton;
@end

@implementation AddIngredientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.existingIngredient ? @"Edit Ingredient" : @"Add Ingredient";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupUI];
    
    if (self.existingIngredient) {
        self.nameField.text = self.existingIngredient.name;
        self.quantityField.text = [NSString stringWithFormat:@"%g", self.existingIngredient.quantity];
        self.unitField.text = self.existingIngredient.unit;
        
        if (self.existingIngredient.expirationDate) {
            NSDateFormatter *f = [[NSDateFormatter alloc] init];
            f.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
            NSDate *d = [f dateFromString:self.existingIngredient.expirationDate];
            if (!d) {
                f.dateFormat = @"yyyy-MM-dd";
                d = [f dateFromString:self.existingIngredient.expirationDate];
            }
            if (d) self.datePicker.date = d;
        }
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(saveTapped)];
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

- (void)cameraTapped {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Select Image Source" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [actionSheet addAction:[UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showImagePicker:UIImagePickerControllerSourceTypeCamera];
        }]];
    }
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Photo Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
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
    UIAlertController *loading = [UIAlertController alertControllerWithTitle:@"Identifying..." message:@"AI is looking at your food..." preferredStyle:UIAlertControllerStyleAlert];
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
                [self showError:[NSError errorWithDomain:@"com.fridgemind" code:404 userInfo:@{NSLocalizedDescriptionKey: @"No ingredients identified."}]];
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
    isoFormatter.dateFormat = @"yyyy-MM-dd";
    NSString *dateStr = [isoFormatter stringFromDate:self.datePicker.date];
    
    NSDictionary *params = @{
        @"familyId": self.familyId ?: @"",
        @"name": name,
        @"quantity": @(quantity),
        @"unit": unit ?: @"",
        @"expirationDate": dateStr,
        @"storageType": @"chilled"
    };
    
    if (self.existingIngredient) {
        [[NetworkManager sharedManager] updateIngredient:self.existingIngredient._id familyId:self.familyId params:params success:^(id  _Nullable response) {
            if (self.completionBlock) {
                self.completionBlock();
            }
            [self.navigationController popViewControllerAnimated:YES];
        } failure:^(NSError * _Nonnull error) {
            [self showError:error];
        }];
    } else {
        [[NetworkManager sharedManager] addIngredient:params success:^(id  _Nullable response) {
            if (self.completionBlock) {
                self.completionBlock();
            }
            [self.navigationController popViewControllerAnimated:YES];
        } failure:^(NSError * _Nonnull error) {
            [self showError:error];
        }];
    }
}

- (void)showError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
