#import "IngredientListViewController.h"
#import <Masonry/Masonry.h>
#import "NetworkManager.h"
#import <YYModel/YYModel.h>
#import <SDWebImage/SDWebImage.h>
#import "AddIngredientViewController.h"
#import "RecipeSuggestionViewController.h"
#import "Ingredient.h"

@interface IngredientListViewController () <UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<Ingredient *> *ingredients;
@property (nonatomic, strong) NSArray<NSString *> *sectionTitles;
@property (nonatomic, strong) NSDictionary<NSString *, NSArray<Ingredient *> *> *groupedIngredients;
@end

@implementation IngredientListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.familyName ?: @"冰箱";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadData];
    [self updateNavigationItems];
}

- (void)updateNavigationItems {
    self.navigationItem.title = self.familyName ?: @"冰箱";
    
    // Add Item Button (Right Bar Button)
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTapped)];
    
    // Chef Button
    UIBarButtonItem *chefItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"wand.and.stars"] style:UIBarButtonItemStylePlain target:self action:@selector(chefTapped)];
    
    // Camera Button
    UIBarButtonItem *cameraItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"camera"] style:UIBarButtonItemStylePlain target:self action:@selector(cameraTapped)];
    
    self.navigationItem.rightBarButtonItems = @[addItem, chefItem, cameraItem];
}

- (void)setupUI {
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // Initial setup for non-tabbar usage
    [self updateNavigationItems];
}

- (void)cameraTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"识别食材" message:@"拍照或从相册选择" preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [alert addAction:[UIAlertAction actionWithTitle:@"相机" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showImagePicker:UIImagePickerControllerSourceTypeCamera];
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showImagePicker:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = sourceType;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (!image) return;
    
    [self identifyIngredientsFromImage:image];
}

- (void)identifyIngredientsFromImage:(UIImage *)image {
    // Compress image to reduce size (max 512px)
    CGFloat maxDimension = 512.0;
    CGSize size = image.size;
    CGFloat ratio = 1.0;
    if (size.width > maxDimension || size.height > maxDimension) {
        if (size.width > size.height) {
            ratio = maxDimension / size.width;
        } else {
            ratio = maxDimension / size.height;
        }
    }
    CGSize newSize = CGSizeMake(size.width * ratio, size.height * ratio);
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.7);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Use low compression quality to keep size small
    NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.5);
    NSString *base64 = [imageData base64EncodedStringWithOptions:0];
    
    // Log prefix for debugging
    if (base64.length > 50) {
        NSLog(@"Base64 Prefix: %@", [base64 substringToIndex:50]);
    }
    
    // NetworkManager expects raw base64 string, it adds the prefix internally
    // Show Loading
    UIAlertController *loading = [UIAlertController alertControllerWithTitle:@"识别中..." message:@"AI正在查看您的食物..." preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:loading animated:YES completion:nil];
    
    [[NetworkManager sharedManager] identifyIngredientsWithImageBase64:base64 success:^(id  _Nullable response) {
        [loading dismissViewControllerAnimated:YES completion:^{
            if ([response isKindOfClass:[NSArray class]]) {
                [self showIdentifiedIngredients:(NSArray *)response];
            } else {
                [self showError:@"AI响应无效"];
            }
        }];
    } failure:^(NSError * _Nonnull error) {
        [loading dismissViewControllerAnimated:YES completion:^{
            [self showError:error.localizedDescription];
        }];
    }];
}

- (void)showIdentifiedIngredients:(NSArray *)items {
    NSMutableString *message = [NSMutableString stringWithString:@"发现：\n"];
    for (NSDictionary *item in items) {
        [message appendFormat:@"- %@ (%@ %@)\n", item[@"name"], item[@"quantity"], item[@"unit"]];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"识别到的食材" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"全部添加到冰箱" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self addIngredients:items];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)addIngredients:(NSArray *)items {
    // Simple serial addition
    dispatch_group_t group = dispatch_group_create();
    __block NSMutableString *errors = [NSMutableString string];
    
    for (NSDictionary *item in items) {
        dispatch_group_enter(group);
        
        NSDictionary *params = @{
            @"name": item[@"name"],
            @"quantity": item[@"quantity"],
            @"unit": item[@"unit"],
            @"expirationDate": @"", // Optional or default
            @"storageType": item[@"storageType"] ?: @"chilled",
            @"familyId": [NetworkManager sharedManager].currentFamilyId
        };
        
        [[NetworkManager sharedManager] addIngredient:params success:^(id  _Nullable response) {
            dispatch_group_leave(group);
        } failure:^(NSError * _Nonnull error) {
            [errors appendFormat:@"Failed to add %@: %@\n", item[@"name"], error.localizedDescription];
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self loadData];
        if (errors.length > 0) {
            [self showError:errors];
        } else {
            [self showSuccess:@"所有食材已添加！"];
        }
    });
}

- (void)showError:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showSuccess:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"成功" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)chefTapped {
    if (self.ingredients.count == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"冰箱空空如也" message:@"先添加一些食材吧！" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // Collect ingredient names
    NSMutableArray *names = [NSMutableArray array];
    for (Ingredient *ing in self.ingredients) {
        if (ing.name) [names addObject:ing.name];
    }
    
    // Show Loading
    UIAlertController *loading = [UIAlertController alertControllerWithTitle:@"AI大厨..." message:@"正在思考菜谱..." preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:loading animated:YES completion:nil];
    
    [[NetworkManager sharedManager] suggestRecipeWithIngredients:names success:^(id  _Nullable response) {
        [loading dismissViewControllerAnimated:YES completion:^{
            RecipeSuggestionViewController *vc = [[RecipeSuggestionViewController alloc] init];
            vc.recipeData = response;
            [self.navigationController pushViewController:vc animated:YES];
        }];
    } failure:^(NSError * _Nonnull error) {
        [loading dismissViewControllerAnimated:YES completion:^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }];
    }];
}

- (void)loadData {
    if (![NetworkManager sharedManager].currentFamilyId) return;
    
    [[NetworkManager sharedManager] fetchIngredients:[NetworkManager sharedManager].currentFamilyId success:^(id  _Nullable response) {
        NSArray *dataArray = response;
        if ([response isKindOfClass:[NSDictionary class]]) {
            // Check if response has "data" field or is just the array
             if (response[@"data"]) {
                 dataArray = response[@"data"];
             }
        }
        
        // If dataArray is still not an array (e.g. wrapper object), we might need more logic.
        // But let's assume standard array for now.
        if ([dataArray isKindOfClass:[NSArray class]]) {
            self.ingredients = [NSArray yy_modelArrayWithClass:[Ingredient class] json:dataArray];
            
            // Group ingredients
            NSMutableArray *chilled = [NSMutableArray array];
            NSMutableArray *frozen = [NSMutableArray array];
            NSMutableArray *others = [NSMutableArray array];
            
            for (Ingredient *ing in self.ingredients) {
                if ([ing.storageType isEqualToString:@"frozen"]) {
                    [frozen addObject:ing];
                } else if ([ing.storageType isEqualToString:@"pantry"]) {
                    [others addObject:ing];
                } else {
                    [chilled addObject:ing];
                }
            }
            
            self.sectionTitles = @[@"冷藏室", @"冷冻室", @"其他"];
            self.groupedIngredients = @{
                @"冷藏室": chilled,
                @"冷冻室": frozen,
                @"其他": others
            };
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"Failed to fetch ingredients: %@", error);
    }];
}

- (void)addTapped {
    // Navigate to Add Ingredient VC
    AddIngredientViewController *vc = [[AddIngredientViewController alloc] init];
    vc.familyId = [NetworkManager sharedManager].currentFamilyId;
    vc.completionBlock = ^{
        [self loadData];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionTitles.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionTitles[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *sectionTitle = self.sectionTitles[section];
    NSArray *items = self.groupedIngredients[sectionTitle];
    return items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"IngredientCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    
    NSString *sectionTitle = self.sectionTitles[indexPath.section];
    NSArray *items = self.groupedIngredients[sectionTitle];
    Ingredient *ingredient = items[indexPath.row];
    
    cell.textLabel.text = ingredient.name;
    
    // Format subtitle
    NSString *dateStr = @"";
    if (ingredient.expirationDate) {
        // Simple string extraction or formatting
        // Assuming backend sends ISO string
        if (ingredient.expirationDate.length >= 10) {
             dateStr = [NSString stringWithFormat:@" - 过期: %@", [ingredient.expirationDate substringToIndex:10]];
        }
    }
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f %@%@", ingredient.quantity, ingredient.unit ?: @"", dateStr];
    
    if (ingredient.imageUrl) {
         [cell.imageView sd_setImageWithURL:[NSURL URLWithString:ingredient.imageUrl] placeholderImage:[UIImage systemImageNamed:@"photo"]];
    } else {
        cell.imageView.image = [UIImage systemImageNamed:@"carrot"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *sectionTitle = self.sectionTitles[indexPath.section];
    NSArray *items = self.groupedIngredients[sectionTitle];
    Ingredient *ingredient = items[indexPath.row];
    
    AddIngredientViewController *vc = [[AddIngredientViewController alloc] init];
    vc.familyId = self.familyId;
    vc.existingIngredient = ingredient;
    vc.completionBlock = ^{
        [self loadData];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

@end
