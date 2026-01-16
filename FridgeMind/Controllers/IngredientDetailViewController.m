#import "IngredientDetailViewController.h"
#import "AddIngredientViewController.h"
#import <Masonry/Masonry.h>
#import "DBManager.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "NetworkManager.h"

@interface IngredientDetailViewController ()

// UI 控件声明
@property (nonatomic, strong) UILabel *nameLabel;       // 食材名称标签
@property (nonatomic, strong) UILabel *quantityLabel;   // 数量标签
@property (nonatomic, strong) UILabel *expirationLabel; // 过期时间标签
@property (nonatomic, strong) UILabel *storageLabel;    // 存放位置标签
@property (nonatomic, strong) UILabel *statusLabel;     // 状态详情标签（显示已放多久/过期多久/剩余多久）

@end

@implementation IngredientDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 设置页面标题
    self.title = @"食材详情";
    // 设置背景颜色为白色
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 初始化 UI 界面
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 每次页面即将显示时更新数据，确保编辑后数据同步
    [self updateData];
}

// 初始化并布局所有 UI 控件
- (void)setupUI {
    // 设置导航栏右侧的“编辑”按钮
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editTapped)];
    
    // 创建各个标签控件
    self.nameLabel = [self createLabelWithFont:[UIFont boldSystemFontOfSize:24]]; // 名称用大号粗体
    self.quantityLabel = [self createLabelWithFont:[UIFont systemFontOfSize:18]];
    self.storageLabel = [self createLabelWithFont:[UIFont systemFontOfSize:16]];
    self.expirationLabel = [self createLabelWithFont:[UIFont systemFontOfSize:16]];
    self.statusLabel = [self createLabelWithFont:[UIFont boldSystemFontOfSize:18]];
    self.statusLabel.textColor = [UIColor darkGrayColor];
    
    // 将控件添加到视图中
    [self.view addSubview:self.nameLabel];
    [self.view addSubview:self.quantityLabel];
    [self.view addSubview:self.storageLabel];
    [self.view addSubview:self.expirationLabel];
    [self.view addSubview:self.statusLabel];
    
    // 使用 Masonry 进行自动布局
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(20);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
    }];
    
    [self.quantityLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(10);
        make.left.right.equalTo(self.nameLabel);
    }];
    
    [self.storageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.quantityLabel.mas_bottom).offset(10);
        make.left.right.equalTo(self.nameLabel);
    }];
    
    [self.expirationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.storageLabel.mas_bottom).offset(10);
        make.left.right.equalTo(self.nameLabel);
    }];
    
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.expirationLabel.mas_bottom).offset(20);
        make.left.right.equalTo(self.nameLabel);
    }];
    
    // 创建底部的“删除食材”按钮
    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [deleteButton setTitle:@"删除食材" forState:UIControlStateNormal];
    [deleteButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal]; // 红色警示文字
    deleteButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [deleteButton addTarget:self action:@selector(deleteTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:deleteButton];
    
    [deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-40);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(44);
    }];
}

// 辅助方法：快速创建多行标签
- (UILabel *)createLabelWithFont:(UIFont *)font {
    UILabel *label = [[UILabel alloc] init];
    label.font = font;
    label.numberOfLines = 0; // 允许自动换行
    return label;
}

// 更新页面数据
- (void)updateData {
    // 填充基本信息
    self.nameLabel.text = self.ingredient.name;
    self.quantityLabel.text = [NSString stringWithFormat:@"数量: %.1f %@", self.ingredient.quantity, self.ingredient.unit ?: @""];
    self.storageLabel.text = [NSString stringWithFormat:@"存放位置: %@", [self storageText:self.ingredient.storageType]];
    
    // 解析并格式化日期字符串
    NSString *createDateStr = [self formatDateString:self.ingredient.createdAt];
    NSString *expireDateStr = [self formatDateString:self.ingredient.expirationDate];
    
    self.expirationLabel.text = [NSString stringWithFormat:@"有效期: %@ ~ %@", createDateStr, expireDateStr];
    
    // 状态显示逻辑（核心计算部分）
    NSDateFormatter *isoFormatter = [[NSDateFormatter alloc] init];
    isoFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    
    // 解析创建时间（兼容多种日期格式）
    NSDate *created = [isoFormatter dateFromString:self.ingredient.createdAt];
    if (!created) {
        NSDateFormatter *fallback = [[NSDateFormatter alloc] init];
        fallback.dateFormat = @"yyyy-MM-dd";
        created = [fallback dateFromString:self.ingredient.createdAt];
    }
    
    // 解析过期时间
    NSDate *expired = [isoFormatter dateFromString:self.ingredient.expirationDate];
    if (!expired) {
        NSDateFormatter *fallback = [[NSDateFormatter alloc] init];
        fallback.dateFormat = @"yyyy-MM-dd";
        expired = [fallback dateFromString:self.ingredient.expirationDate];
    }
    
    if (created && expired) {
        NSDate *now = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSMutableString *statusText = [NSMutableString string];
        
        // 计算已存放时长（从放入时间到现在）
        NSDateComponents *storedDiff = [calendar components:NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:created toDate:now options:0];
        
        // 格式化“已放”时间显示
        if (storedDiff.day >= 1) {
            if (storedDiff.hour > 0) {
                [statusText appendFormat:@"已放: %ld 天 %ld 小时\n", (long)storedDiff.day, (long)storedDiff.hour];
            } else {
                [statusText appendFormat:@"已放: %ld 天\n", (long)storedDiff.day];
            }
        } else if (storedDiff.hour >= 1) {
            [statusText appendFormat:@"已放: %ld 小时\n", (long)storedDiff.hour];
        } else {
            [statusText appendFormat:@"已放: %ld 分钟\n", (long)storedDiff.minute];
        }
        
        // 计算过期状态或剩余时间（比较现在和过期时间）
        if ([now compare:expired] == NSOrderedDescending) {
            // 已过期分支
            NSDateComponents *expireDiff = [calendar components:NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:expired toDate:now options:0];
            
            if (expireDiff.day >= 1) {
                if (expireDiff.hour > 0) {
                    [statusText appendFormat:@"已过期: %ld 天 %ld 小时", (long)expireDiff.day, (long)expireDiff.hour];
                } else {
                    [statusText appendFormat:@"已过期: %ld 天", (long)expireDiff.day];
                }
            } else if (expireDiff.hour >= 1) {
                [statusText appendFormat:@"已过期: %ld 小时", (long)expireDiff.hour];
            } else {
                [statusText appendFormat:@"已过期: %ld 分钟", (long)expireDiff.minute];
            }
            self.statusLabel.textColor = [UIColor redColor]; // 过期显示红色
        } else {
            // 未过期（剩余时间）分支
            NSDateComponents *remainDiff = [calendar components:NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:now toDate:expired options:0];
             if (remainDiff.day >= 1) {
                 if (remainDiff.hour > 0) {
                     [statusText appendFormat:@"剩余: %ld 天 %ld 小时", (long)remainDiff.day, (long)remainDiff.hour];
                 } else {
                     [statusText appendFormat:@"剩余: %ld 天", (long)remainDiff.day];
                 }
             } else if (remainDiff.hour >= 1) {
                 [statusText appendFormat:@"剩余: %ld 小时", (long)remainDiff.hour];
             } else {
                 [statusText appendFormat:@"剩余: %ld 分钟", (long)remainDiff.minute];
             }
             self.statusLabel.textColor = [UIColor darkGrayColor]; // 正常显示深灰色
        }
        
        self.statusLabel.text = statusText;
    } else {
        self.statusLabel.text = @"--"; // 日期无效时的占位符
    }
}

// 辅助方法：格式化日期字符串用于显示
- (NSString *)formatDateString:(NSString *)dateString {
    if (!dateString) return @"--";
    
    // 尝试解析完整的 ISO 日期格式
    NSDateFormatter *isoFormatter = [[NSDateFormatter alloc] init];
    isoFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    NSDate *date = [isoFormatter dateFromString:dateString];
    
    if (!date) {
        // 尝试解析简单的日期格式
        isoFormatter.dateFormat = @"yyyy-MM-dd";
        date = [isoFormatter dateFromString:dateString];
    }
    
    if (date) {
        // 格式化为易读的 "yyyy-MM-dd HH:mm"
        NSDateFormatter *displayFormatter = [[NSDateFormatter alloc] init];
        displayFormatter.dateFormat = @"yyyy-MM-dd HH:mm";
        return [displayFormatter stringFromDate:date];
    }
    
    // 如果解析失败，直接截取前16位或返回原字符串
    if (dateString.length >= 16) {
        return [dateString substringToIndex:16];
    }
    return dateString;
}

// 辅助方法：将存储类型代码转换为中文
- (NSString *)storageText:(NSString *)type {
    if ([type isEqualToString:@"frozen"]) return @"冷冻";
    if ([type isEqualToString:@"chilled"]) return @"冷藏";
    if ([type isEqualToString:@"pantry"]) return @"常温";
    return @"未知";
}

// 点击“编辑”按钮的响应方法
- (void)editTapped {
    AddIngredientViewController *vc = [[AddIngredientViewController alloc] init];
    vc.familyId = self.familyId;
    vc.existingIngredient = self.ingredient; // 传递当前食材对象以进入编辑模式
    vc.completionBlock = ^{
        // 编辑完成后回调，刷新会在 viewWillAppear 中处理
    };
    [self.navigationController pushViewController:vc animated:YES];
}

// 点击“删除”按钮的响应方法
- (void)deleteTapped {
    // 弹出确认对话框
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认删除" message:@"确定要删除这个食材吗？" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self performDelete]; // 用户确认后执行删除
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

// 执行删除操作
- (void)performDelete {
    [SVProgressHUD show]; // 显示加载中
    
    NSString *ingId = self.ingredient._id ?: self.ingredient.localId;
    
    // 调用网络接口删除食材
    [[NetworkManager sharedManager] deleteIngredient:ingId success:^(id  _Nullable response) {
        [SVProgressHUD dismiss];
        // 标记本地数据库中的记录为已删除
        [[DBManager sharedManager] markIngredientAsDeleted:self.ingredient.localId];
        // 返回上一页
        [self.navigationController popViewControllerAnimated:YES];
    } failure:^(NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        // 即使网络失败，也先在本地标记为已删除（SyncManager 稍后会处理同步）
        [[DBManager sharedManager] markIngredientAsDeleted:self.ingredient.localId];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

@end
