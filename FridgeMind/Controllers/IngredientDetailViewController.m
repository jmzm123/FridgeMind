#import "IngredientDetailViewController.h"
#import "AddIngredientViewController.h"
#import <Masonry/Masonry.h>
#import "DBManager.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "NetworkManager.h"

@interface IngredientDetailViewController ()

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *quantityLabel;
@property (nonatomic, strong) UILabel *expirationLabel;
@property (nonatomic, strong) UILabel *storageLabel;
@property (nonatomic, strong) UILabel *statusLabel;

@end

@implementation IngredientDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"食材详情";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateData];
}

- (void)setupUI {
    // Edit Button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editTapped)];
    
    // UI Elements
    self.nameLabel = [self createLabelWithFont:[UIFont boldSystemFontOfSize:24]];
    self.quantityLabel = [self createLabelWithFont:[UIFont systemFontOfSize:18]];
    self.storageLabel = [self createLabelWithFont:[UIFont systemFontOfSize:16]];
    self.expirationLabel = [self createLabelWithFont:[UIFont systemFontOfSize:16]];
    self.statusLabel = [self createLabelWithFont:[UIFont boldSystemFontOfSize:18]];
    self.statusLabel.textColor = [UIColor darkGrayColor];
    
    [self.view addSubview:self.nameLabel];
    [self.view addSubview:self.quantityLabel];
    [self.view addSubview:self.storageLabel];
    [self.view addSubview:self.expirationLabel];
    [self.view addSubview:self.statusLabel];
    
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
    
    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [deleteButton setTitle:@"删除食材" forState:UIControlStateNormal];
    [deleteButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    deleteButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [deleteButton addTarget:self action:@selector(deleteTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:deleteButton];
    
    [deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-40);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(44);
    }];
}

- (UILabel *)createLabelWithFont:(UIFont *)font {
    UILabel *label = [[UILabel alloc] init];
    label.font = font;
    label.numberOfLines = 0;
    return label;
}

- (void)updateData {
    self.nameLabel.text = self.ingredient.name;
    self.quantityLabel.text = [NSString stringWithFormat:@"数量: %.1f %@", self.ingredient.quantity, self.ingredient.unit ?: @""];
    self.storageLabel.text = [NSString stringWithFormat:@"存放位置: %@", [self storageText:self.ingredient.storageType]];
    
    // Parse dates
    NSString *createDateStr = [self formatDateString:self.ingredient.createdAt];
    NSString *expireDateStr = [self formatDateString:self.ingredient.expirationDate];
    
    self.expirationLabel.text = [NSString stringWithFormat:@"有效期: %@ ~ %@", createDateStr, expireDateStr];
    
    // Status Logic
    NSDateFormatter *isoFormatter = [[NSDateFormatter alloc] init];
    isoFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    
    // Helper to get date object
    NSDate *created = [isoFormatter dateFromString:self.ingredient.createdAt];
    if (!created) {
        NSDateFormatter *fallback = [[NSDateFormatter alloc] init];
        fallback.dateFormat = @"yyyy-MM-dd";
        created = [fallback dateFromString:self.ingredient.createdAt];
    }
    
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
        
        // Days Stored
        NSDateComponents *storedDiff = [calendar components:NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:created toDate:now options:0];
        
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
        
        // Expired/Remaining
        if ([now compare:expired] == NSOrderedDescending) {
            // Expired
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
            self.statusLabel.textColor = [UIColor redColor];
        } else {
            // Remaining
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
             self.statusLabel.textColor = [UIColor darkGrayColor];
        }
        
        self.statusLabel.text = statusText;
    } else {
        self.statusLabel.text = @"--";
    }
}

- (NSString *)formatDateString:(NSString *)dateString {
    if (!dateString) return @"--";
    
    // Try to parse full ISO date
    NSDateFormatter *isoFormatter = [[NSDateFormatter alloc] init];
    isoFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    NSDate *date = [isoFormatter dateFromString:dateString];
    
    if (!date) {
        // Fallback for simple date format
        isoFormatter.dateFormat = @"yyyy-MM-dd";
        date = [isoFormatter dateFromString:dateString];
    }
    
    if (date) {
        NSDateFormatter *displayFormatter = [[NSDateFormatter alloc] init];
        displayFormatter.dateFormat = @"yyyy-MM-dd HH:mm";
        return [displayFormatter stringFromDate:date];
    }
    
    // If all parsing fails, just return raw string or substring
    if (dateString.length >= 16) {
        return [dateString substringToIndex:16];
    }
    return dateString;
}

- (NSString *)storageText:(NSString *)type {
    if ([type isEqualToString:@"frozen"]) return @"冷冻";
    if ([type isEqualToString:@"chilled"]) return @"冷藏";
    if ([type isEqualToString:@"pantry"]) return @"常温";
    return @"未知";
}

- (void)editTapped {
    AddIngredientViewController *vc = [[AddIngredientViewController alloc] init];
    vc.familyId = self.familyId;
    vc.existingIngredient = self.ingredient;
    vc.completionBlock = ^{
        // Refresh handled by viewWillAppear
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)deleteTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认删除" message:@"确定要删除这个食材吗？" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self performDelete];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performDelete {
    [SVProgressHUD show];
    
    NSString *ingId = self.ingredient._id ?: self.ingredient.localId;
    
    [[NetworkManager sharedManager] deleteIngredient:ingId success:^(id  _Nullable response) {
        [SVProgressHUD dismiss];
        [[DBManager sharedManager] markIngredientAsDeleted:self.ingredient.localId];
        [self.navigationController popViewControllerAnimated:YES];
    } failure:^(NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        // Even if network fails, we mark local as deleted (sync manager handles it later)
        [[DBManager sharedManager] markIngredientAsDeleted:self.ingredient.localId];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

@end
