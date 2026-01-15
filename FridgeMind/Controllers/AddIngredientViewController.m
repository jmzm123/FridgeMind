#import "AddIngredientViewController.h"
#import <Masonry/Masonry.h>
#import "NetworkManager.h"
#import "DBManager.h"
#import "SyncManager.h"
#import "Ingredient.h"

@interface AddIngredientViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) UITextField *quantityField;
@property (nonatomic, strong) UITextField *unitField;
@property (nonatomic, strong) UISegmentedControl *storageControl;
@property (nonatomic, strong) UIDatePicker *expirationDatePicker;
@property (nonatomic, strong) UIDatePicker *putInDatePicker;
@property (nonatomic, strong) UILabel *expirationLabel;
@property (nonatomic, strong) UILabel *putInLabel;
@property (nonatomic, strong) UIButton *cameraButton;

// Batch Add UI
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<Ingredient *> *pendingIngredients;
@end

@implementation AddIngredientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.existingIngredient ? @"编辑食材" : @"添加食材";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.pendingIngredients = [NSMutableArray array];
    
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
        
        // Single Edit Mode: "Save"
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(saveTapped)];
    } else {
        // Batch Add Mode: "Put In Fridge"
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"全部放入" style:UIBarButtonItemStyleDone target:self action:@selector(finishTapped)];
    }
}

- (void)setupUI {
    // Camera Button
    self.cameraButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cameraButton setImage:[UIImage systemImageNamed:@"camera"] forState:UIControlStateNormal];
    [self.cameraButton addTarget:self action:@selector(cameraTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cameraButton];
    
    // Camera Hint
    UILabel *cameraHint = [[UILabel alloc] init];
    cameraHint.text = @"拍食材/小票";
    cameraHint.font = [UIFont systemFontOfSize:10];
    cameraHint.textColor = [UIColor darkGrayColor];
    cameraHint.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:cameraHint];
    
    [self.cameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.width.height.mas_equalTo(44);
    }];
    
    [cameraHint mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cameraButton.mas_bottom).offset(2);
        make.centerX.equalTo(self.cameraButton);
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
    
    // Batch UI Elements
    if (!self.existingIngredient) {
        self.addButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.addButton setTitle:@"添加 / 暂存" forState:UIControlStateNormal];
        self.addButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [self.addButton addTarget:self action:@selector(addTapped) forControlEvents:UIControlEventTouchUpInside];
        
        // Style the button
        self.addButton.backgroundColor = [UIColor systemBlueColor];
        [self.addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.addButton.layer.cornerRadius = 8;
        
        [self.view addSubview:self.addButton];
        
        self.tableView = [[UITableView alloc] init];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        [self.view addSubview:self.tableView];
        
        [self.addButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.expirationLabel.mas_bottom).offset(25);
            make.centerX.equalTo(self.view);
            make.width.mas_equalTo(200);
            make.height.mas_equalTo(44);
        }];
        
        [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.addButton.mas_bottom).offset(15);
            make.left.right.bottom.equalTo(self.view);
        }];
    }
}

- (UITextField *)createTextField:(NSString *)placeholder {
    UITextField *tf = [[UITextField alloc] init];
    tf.placeholder = placeholder;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    return tf;
}

- (void)cameraTapped {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"选择图片来源" message:@"把食材平铺到平面或购物小票，可自动批量识别" preferredStyle:UIAlertControllerStyleActionSheet];
    
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
    UIAlertController *loading = [UIAlertController alertControllerWithTitle:@"识别中..." message:@"AI正在分析食材或小票..." preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:loading animated:YES completion:nil];
    
    [[NetworkManager sharedManager] identifyIngredientsWithImageBase64:base64 success:^(id  _Nullable response) {
        [loading dismissViewControllerAnimated:YES completion:^{
            // Parse response: array of ingredients
            NSArray *items = response;
            if ([items isKindOfClass:[NSArray class]] && items.count > 0) {
                // If multiple items, add all to pending list directly
                if (items.count > 1 || self.pendingIngredients.count > 0) {
                    for (NSDictionary *itemDict in items) {
                        Ingredient *ing = [self createIngredientFromDictionary:itemDict];
                        if (ing) {
                            [self.pendingIngredients addObject:ing];
                        }
                    }
                    [self.tableView reloadData];
                    
                    NSString *msg = [NSString stringWithFormat:@"已识别 %lu 个食材并加入待放入列表", (unsigned long)items.count];
                    UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"识别成功" message:msg preferredStyle:UIAlertControllerStyleAlert];
                    [successAlert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:successAlert animated:YES completion:nil];
                    
                } else {
                    // If only 1 item and list is empty, fill the input fields for review (Single Add flow)
                    NSDictionary *item = items[0];
                    self.nameField.text = item[@"name"];
                    self.quantityField.text = [NSString stringWithFormat:@"%@", item[@"quantity"] ?: @1];
                    self.unitField.text = item[@"unit"];
                    
                    NSString *storage = item[@"storageType"];
                    if ([storage isEqualToString:@"frozen"]) {
                        self.storageControl.selectedSegmentIndex = 1;
                    } else if ([storage isEqualToString:@"pantry"]) {
                        self.storageControl.selectedSegmentIndex = 2;
                    } else {
                        self.storageControl.selectedSegmentIndex = 0;
                    }
                }
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

- (Ingredient *)createIngredientFromDictionary:(NSDictionary *)dict {
    NSString *name = dict[@"name"];
    if (!name || name.length == 0) return nil;
    
    Ingredient *ing = [[Ingredient alloc] init];
    ing.name = name;
    ing.quantity = [dict[@"quantity"] doubleValue];
    ing.unit = dict[@"unit"] ?: @"";
    
    // Default dates
    NSDateFormatter *isoFormatter = [[NSDateFormatter alloc] init];
    isoFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    ing.createdAt = [isoFormatter stringFromDate:[NSDate date]];
    ing.expirationDate = [isoFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:7*24*3600]];
    ing.updatedAt = [NSDate date];
    ing.syncStatus = @"pending";
    ing.deleted = NO;
    ing.localId = [[NSUUID UUID] UUIDString];
    
    NSString *storage = dict[@"storageType"];
    if ([storage isEqualToString:@"frozen"]) {
        ing.storageType = @"frozen";
    } else if ([storage isEqualToString:@"pantry"]) {
        ing.storageType = @"pantry";
    } else {
        ing.storageType = @"chilled";
    }
    
    return ing;
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

- (void)addTapped {
    Ingredient *ing = [self createIngredientFromInput];
    if (!ing) return;
    
    [self.pendingIngredients addObject:ing];
    [self.tableView reloadData];
    
    // Clear inputs
    self.nameField.text = @"";
    self.quantityField.text = @"";
    self.unitField.text = @"";
    self.storageControl.selectedSegmentIndex = 0;
    self.putInDatePicker.date = [NSDate date];
    self.expirationDatePicker.date = [NSDate dateWithTimeIntervalSinceNow:7*24*3600];
    
    [self.nameField becomeFirstResponder];
}

- (void)finishTapped {
    // If pending list is empty, but inputs are filled, treat as single add
    if (self.pendingIngredients.count == 0) {
        if (self.nameField.text.length > 0) {
            Ingredient *ing = [self createIngredientFromInput];
            if (ing) {
                [self.pendingIngredients addObject:ing];
            }
        }
    } else {
        // If pending list has items, and inputs are also filled, ask or auto-add?
        // Let's auto-add if valid, otherwise ignore incomplete input
        if (self.nameField.text.length > 0) {
            Ingredient *ing = [self createIngredientFromInput];
            if (ing) {
                 [self.pendingIngredients addObject:ing];
            }
        }
    }
    
    if (self.pendingIngredients.count == 0) {
        // Nothing to save
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    // Batch Save
    for (Ingredient *ing in self.pendingIngredients) {
        [[DBManager sharedManager] saveIngredient:ing];
    }
    
    if (self.completionBlock) {
        self.completionBlock();
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (Ingredient *)createIngredientFromInput {
    NSString *name = self.nameField.text;
    if (name.length == 0) return nil;
    
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
    
    return ing;
}

- (void)saveTapped {
    Ingredient *ing = [self createIngredientFromInput];
    if (!ing) return;
    
    [[DBManager sharedManager] saveIngredient:ing];
    
    if (self.completionBlock) {
        self.completionBlock();
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.pendingIngredients.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"PendingCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    
    Ingredient *ing = self.pendingIngredients[indexPath.row];
    cell.textLabel.text = ing.name;
    
    NSString *storage = @"冷藏";
    if ([ing.storageType isEqualToString:@"frozen"]) storage = @"冷冻";
    if ([ing.storageType isEqualToString:@"pantry"]) storage = @"常温";
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f %@ | %@", ing.quantity, ing.unit, storage];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.pendingIngredients removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)showError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
