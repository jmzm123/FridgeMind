#import "IngredientListViewController.h"
#import <Masonry/Masonry.h>
#import "NetworkManager.h"
#import <YYModel/YYModel.h>
#import <SDWebImage/SDWebImage.h>
#import "AddIngredientViewController.h"
#import "IngredientDetailViewController.h"
#import "RecipeSuggestionViewController.h"
#import "Ingredient.h"
#import "DBManager.h"
#import "SyncManager.h"

@interface IngredientListViewController () <UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
// 列表视图，用于展示食材
@property (nonatomic, strong) UITableView *tableView;
// 所有食材数据源
@property (nonatomic, strong) NSArray<Ingredient *> *ingredients;
// 分组标题（冷藏、冷冻、其他）
@property (nonatomic, strong) NSArray<NSString *> *sectionTitles;
// 0分组后的食材字典，Key为分组标题，Value为食材数组
@property (nonatomic, strong) NSDictionary<NSString *, NSArray<Ingredient *> *> *groupedIngredients;
@end

@implementation IngredientListViewController

#pragma mark - Life Cycle / 生命周期

- (void)viewDidLoad {
    [super viewDidLoad];
    // 设置页面标题
    self.title = self.familyName ?: @"冰箱";
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 初始化UI界面
    [self setupUI];
    // 注册同步完成通知，以便数据同步后刷新列表
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadData) name:kSyncDidFinishNotification object:nil];
}

- (void)dealloc {
    // 移除通知监听
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 每次页面出现时刷新数据
    [self loadData];
    // 更新导航栏按钮
    [self updateNavigationItems];
}

#pragma mark - UI Setup / 界面初始化

- (void)updateNavigationItems {
    self.navigationItem.title = self.familyName ?: @"冰箱";
    
    // 添加食材按钮（右上角+号）
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTapped)];
    
    // AI大厨按钮（魔法棒图标）
    UIBarButtonItem *chefItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"wand.and.stars"] style:UIBarButtonItemStylePlain target:self action:@selector(chefTapped)];
    
    // 拍照识别按钮（相机图标）
    UIBarButtonItem *cameraItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"camera"] style:UIBarButtonItemStylePlain target:self action:@selector(cameraTapped)];
    
    // 设置导航栏右侧按钮组
    self.navigationItem.rightBarButtonItems = @[addItem, chefItem, cameraItem];
}

- (void)setupUI {
    // 初始化TableView
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 80; // 增加行高以容纳大图片
    [self.view addSubview:self.tableView];
    
    // 使用Masonry布局TableView，填满整个视图
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // 添加下拉刷新控件
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;
    
    // 初始化导航项
    [self updateNavigationItems];
}

#pragma mark - Actions / 事件处理

/// 点击相机按钮，弹出选择框（拍照或相册）
- (void)cameraTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"识别食材" message:@"拍照或从相册选择" preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 如果设备支持相机，添加相机选项
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [alert addAction:[UIAlertAction actionWithTitle:@"相机" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showImagePicker:UIImagePickerControllerSourceTypeCamera];
        }]];
    }
    
    // 添加相册选项
    [alert addAction:[UIAlertAction actionWithTitle:@"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showImagePicker:UIImagePickerControllerSourceTypePhotoLibrary];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

/// 显示图片选择器
- (void)showImagePicker:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = sourceType;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    // 获取原始图片
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    if (!image) return;
    
    // 开始识别图片中的食材
    [self identifyIngredientsFromImage:image];
}

/// AI识别图片食材
- (void)identifyIngredientsFromImage:(UIImage *)image {
    // 压缩图片以减少上传大小 (最大边长 512px)
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
    
    // 重绘图片调整大小
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.7);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 使用低质量JPEG压缩以减小文件体积
    NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.5);
    NSString *base64 = [imageData base64EncodedStringWithOptions:0];
    
    // 调试日志：输出Base64前缀
    if (base64.length > 50) {
        NSLog(@"Base64 Prefix: %@", [base64 substringToIndex:50]);
    }
    
    // 显示加载提示
    UIAlertController *loading = [UIAlertController alertControllerWithTitle:@"识别中..." message:@"AI正在查看您的食物..." preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:loading animated:YES completion:nil];
    
    // 调用网络接口进行识别
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

/// 显示识别结果确认框
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

/// 将识别到的食材批量添加到数据库
- (void)addIngredients:(NSArray *)items {
    NSDateFormatter *isoFormatter = [[NSDateFormatter alloc] init];
    isoFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    
    for (NSDictionary *item in items) {
        Ingredient *ing = [[Ingredient alloc] init];
        ing.localId = [[NSUUID UUID] UUIDString];
        ing.name = item[@"name"];
        ing.quantity = [item[@"quantity"] doubleValue];
        ing.unit = item[@"unit"];
        ing.storageType = item[@"storageType"] ?: @"chilled";
        ing.createdAt = [isoFormatter stringFromDate:[NSDate date]];
        ing.updatedAt = [NSDate date];
        ing.syncStatus = @"pending";
        ing.deleted = NO;
        
        [[DBManager sharedManager] saveIngredient:ing];
    }
    
    [self loadData];
    [self showSuccess:@"所有食材已添加！"];
    [[SyncManager sharedManager] sync];
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

// 点击AI大厨按钮，根据当前食材生成菜谱
- (void)chefTapped {
    if (self.ingredients.count == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"冰箱空空如也" message:@"先添加一些食材吧！" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // 收集所有食材名称
    NSMutableArray *names = [NSMutableArray array];
    for (Ingredient *ing in self.ingredients) {
        if (ing.name) [names addObject:ing.name];
    }
    
    // 显示加载提示
    UIAlertController *loading = [UIAlertController alertControllerWithTitle:@"AI大厨..." message:@"正在思考菜谱..." preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:loading animated:YES completion:nil];
    
    // 调用网络接口获取菜谱建议
    [[NetworkManager sharedManager] suggestRecipeWithIngredients:names cookingMethod:nil success:^(id  _Nullable response) {
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

#pragma mark - Data Management / 数据管理

- (void)loadData {
    // 1. 从本地数据库获取所有食材
    self.ingredients = [[DBManager sharedManager] fetchAllIngredients];
    
    // 2. 对食材进行分组
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
    
    // 设置分组标题和数据源
    self.sectionTitles = @[@"冷藏室", @"冷冻室", @"其他"];
    self.groupedIngredients = @{
        @"冷藏室": chilled,
        @"冷冻室": frozen,
        @"其他": others
    };
    
    // 3. 刷新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        if (self.tableView.refreshControl.isRefreshing) {
            [self.tableView.refreshControl endRefreshing];
        }
    });
}

- (void)handleRefresh:(UIRefreshControl *)sender {
    // 下拉刷新触发数据重载
    [self loadData];
    [sender endRefreshing];
}

/// 点击添加按钮
- (void)addTapped {
    // 跳转到添加食材页面
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
    
    // 获取当前行的食材对象
    NSString *sectionTitle = self.sectionTitles[indexPath.section];
    NSArray *items = self.groupedIngredients[sectionTitle];
    Ingredient *ingredient = items[indexPath.row];
    
    // 隐藏系统自带的 ImageView 和 Label
    cell.imageView.image = nil;
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;
    
    // --- 自定义 UI 元素 ---
    
    // 0. 自定义大图片 (Tag: 2001)
    UIImageView *iconImageView = [cell.contentView viewWithTag:2001];
    if (!iconImageView) {
        iconImageView = [[UIImageView alloc] init];
        iconImageView.tag = 2001;
        iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        iconImageView.layer.cornerRadius = 8;
        iconImageView.clipsToBounds = YES;
        [cell.contentView addSubview:iconImageView];
        
        [iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(cell.contentView).offset(16);
            make.centerY.equalTo(cell.contentView);
            make.width.height.mas_equalTo(60); // 放大一倍 (原约为30-40)
        }];
    }
    
    // 1. 自定义名称 Label (Tag: 2002)
    UILabel *nameLabel = [cell.contentView viewWithTag:2002];
    if (!nameLabel) {
        nameLabel = [[UILabel alloc] init];
        nameLabel.tag = 2002;
        nameLabel.font = [UIFont systemFontOfSize:16]; // 对应 cell.textLabel
        [cell.contentView addSubview:nameLabel];
        
        [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(iconImageView.mas_right).offset(12);
            make.top.equalTo(iconImageView).offset(5);
        }];
    }
    nameLabel.text = ingredient.name;
    
    // 2. 自定义详情 Label (Tag: 2003)
    UILabel *detailLabel = [cell.contentView viewWithTag:2003];
    if (!detailLabel) {
        detailLabel = [[UILabel alloc] init];
        detailLabel.tag = 2003;
        detailLabel.font = [UIFont systemFontOfSize:12]; // 对应 cell.detailTextLabel
        detailLabel.textColor = [UIColor grayColor];
        [cell.contentView addSubview:detailLabel];
        
        [detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(nameLabel);
            make.top.equalTo(nameLabel.mas_bottom).offset(4);
        }];
    }
    detailLabel.text = [NSString stringWithFormat:@"%.1f %@", ingredient.quantity, ingredient.unit ?: @""];
    
    
    // 加载图片逻辑 (使用自定义 iconImageView)
    NSString *displayImageURL = ingredient.imageUrl;
    if (!displayImageURL || displayImageURL.length == 0) {
        displayImageURL = [Ingredient imageURLForName:ingredient.name];
    }
    
    if (displayImageURL && displayImageURL.length > 0) {
         [iconImageView sd_setImageWithURL:[NSURL URLWithString:displayImageURL] placeholderImage:[UIImage systemImageNamed:@"carrot"]];
    } else {
        iconImageView.image = [UIImage systemImageNamed:@"carrot"];
    }
    
    // 3. 日期显示 Label (Tag: 1001)
    UILabel *dateLabel = [cell.contentView viewWithTag:1001];
    if (!dateLabel) {
        dateLabel = [[UILabel alloc] init];
        dateLabel.tag = 1001;
        dateLabel.font = [UIFont systemFontOfSize:10];
        dateLabel.textColor = [UIColor grayColor];
        dateLabel.textAlignment = NSTextAlignmentRight;
        [cell.contentView addSubview:dateLabel];
    }
    
    [dateLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cell.contentView).offset(12);
        make.right.equalTo(cell.contentView).offset(-16);
    }];
    
    // 2. 状态文本 Label (Tag: 1002) - 显示"已放X天"或"已过期X天"
    UILabel *statusLabel = [cell.contentView viewWithTag:1002];
    if (!statusLabel) {
        statusLabel = [[UILabel alloc] init];
        statusLabel.tag = 1002;
        statusLabel.font = [UIFont boldSystemFontOfSize:10];
        statusLabel.textAlignment = NSTextAlignmentRight;
        [cell.contentView addSubview:statusLabel];
    }
    
    [statusLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(dateLabel.mas_bottom).offset(2);
        make.right.equalTo(dateLabel);
    }];

    // 3. 进度条 (Tag: 999) - 可视化过期进度
    UIProgressView *progressView = [cell.contentView viewWithTag:999];
    if (!progressView) {
        progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        progressView.tag = 999;
        progressView.layer.cornerRadius = 3;
        progressView.clipsToBounds = YES;
        [cell.contentView addSubview:progressView];
    }
    
    [progressView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(statusLabel.mas_bottom).offset(5);
        make.right.equalTo(dateLabel);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(6);
    }];
    
    // --- 数据解析与格式化 ---
    NSDateFormatter *isoFormatter = [[NSDateFormatter alloc] init];
    isoFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    
    NSDate *created = nil;
    if (ingredient.createdAt) created = [isoFormatter dateFromString:ingredient.createdAt];
    
    // 放入时间回退解析逻辑
    if (!created && ingredient.createdAt.length >= 10) {
        NSDateFormatter *fallbackFormatter = [[NSDateFormatter alloc] init];
        fallbackFormatter.dateFormat = @"yyyy-MM-dd";
        created = [fallbackFormatter dateFromString:[ingredient.createdAt substringToIndex:10]];
    }
    
    NSDate *expired = nil;
    if (ingredient.expirationDate) expired = [isoFormatter dateFromString:ingredient.expirationDate];
    
    // 过期时间回退解析逻辑
    if (!expired && ingredient.expirationDate.length >= 10) {
        NSDateFormatter *fallbackFormatter = [[NSDateFormatter alloc] init];
        fallbackFormatter.dateFormat = @"yyyy-MM-dd";
        expired = [fallbackFormatter dateFromString:[ingredient.expirationDate substringToIndex:10]];
    }
    
    // 显示日期范围 (放入 ~ 过期)
    NSDateFormatter *displayFormatter = [[NSDateFormatter alloc] init];
    displayFormatter.dateFormat = @"MM-dd";
    NSString *createdStr = created ? [displayFormatter stringFromDate:created] : @"--";
    NSString *expiredStr = expired ? [displayFormatter stringFromDate:expired] : @"--";
    dateLabel.text = [NSString stringWithFormat:@"%@ ~ %@", createdStr, expiredStr];
    
    // 计算并显示状态文本 (精确到天、小时、分钟)
    if (created && expired) {
        NSDate *now = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        // 计算已存放天数
        NSDateComponents *storedComponents = [calendar components:NSCalendarUnitDay fromDate:created toDate:now options:0];
        // NSInteger daysStored = storedComponents.day; // 未使用
        
        // 计算剩余天数
        NSDateComponents *expireComponents = [calendar components:NSCalendarUnitDay fromDate:now toDate:expired options:0];
        // NSInteger daysRemaining = expireComponents.day; // 未使用
        
        if ([now compare:expired] == NSOrderedDescending) {
            // --- 已过期 ---
            NSDateComponents *diff = [calendar components:NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:expired toDate:now options:0];
            
            if (diff.day >= 1) {
                if (diff.hour > 0) {
                    statusLabel.text = [NSString stringWithFormat:@"已过期 %ld 天 %ld 小时", (long)diff.day, (long)diff.hour];
                } else {
                    statusLabel.text = [NSString stringWithFormat:@"已过期 %ld 天", (long)diff.day];
                }
            } else if (diff.hour >= 1) {
                statusLabel.text = [NSString stringWithFormat:@"已过期 %ld 小时", (long)diff.hour];
            } else {
                statusLabel.text = [NSString stringWithFormat:@"已过期 %ld 分钟", (long)diff.minute];
            }
            statusLabel.textColor = [UIColor redColor];
        } else {
            // --- 未过期（显示已放时间） ---
            NSDateComponents *diff = [calendar components:NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:created toDate:now options:0];
            
            if (diff.day >= 1) {
                if (diff.hour > 0) {
                     statusLabel.text = [NSString stringWithFormat:@"已放 %ld 天 %ld 小时", (long)diff.day, (long)diff.hour];
                } else {
                     statusLabel.text = [NSString stringWithFormat:@"已放 %ld 天", (long)diff.day];
                }
            } else if (diff.hour >= 1) {
                statusLabel.text = [NSString stringWithFormat:@"已放 %ld 小时", (long)diff.hour];
            } else {
                statusLabel.text = [NSString stringWithFormat:@"已放 %ld 分钟", (long)diff.minute];
            }
            statusLabel.textColor = [UIColor grayColor];
        }
    } else {
        statusLabel.text = @"--";
        statusLabel.textColor = [UIColor grayColor];
    }
    
    // 设置Cell详情文本 (清除旧的日期信息，只保留数量)
    // cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f %@", ingredient.quantity, ingredient.unit ?: @""]; // 已移至上方自定义 Label


    // --- 进度条逻辑 ---
    if (created && expired) {
        NSTimeInterval total = [expired timeIntervalSinceDate:created];
        NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:created];
        
        if (total > 0) {
            float progress = elapsed / total;
            if (progress < 0) progress = 0;
            if (progress > 1) progress = 1;
            
            progressView.progress = progress;
            progressView.hidden = NO;
            
            // 根据过期程度改变颜色
            if ([[NSDate date] compare:expired] == NSOrderedDescending) {
                // 已过期 -> 红色满格
                progressView.progressTintColor = [UIColor redColor];
                progressView.progress = 1.0;
            } else {
                if (progress > 0.9) {
                    progressView.progressTintColor = [UIColor redColor]; // 即将过期
                } else if (progress > 0.7) {
                    progressView.progressTintColor = [UIColor orangeColor]; // 临近过期
                } else {
                    progressView.progressTintColor = [UIColor greenColor]; // 状态良好
                }
            }
        } else {
            progressView.hidden = YES;
        }
    } else {
        progressView.hidden = YES;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // 获取选中食材
    NSString *sectionTitle = self.sectionTitles[indexPath.section];
    NSArray *items = self.groupedIngredients[sectionTitle];
    Ingredient *ingredient = items[indexPath.row];
    
    // 跳转到详情页
    IngredientDetailViewController *vc = [[IngredientDetailViewController alloc] init];
    vc.familyId = self.familyId;
    vc.ingredient = ingredient;
    [self.navigationController pushViewController:vc animated:YES];
}

// 允许编辑（删除）
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// 处理删除操作
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *sectionTitle = self.sectionTitles[indexPath.section];
        NSArray *items = self.groupedIngredients[sectionTitle];
        Ingredient *ingredient = items[indexPath.row];
        
        // 标记为已删除
        [[DBManager sharedManager] markIngredientAsDeleted:ingredient.localId];
        
        // 刷新UI
        [self loadData];
        
        // 触发同步
        [[SyncManager sharedManager] sync];
    }
}

@end
