#import "DishDetailViewController.h"
#import "AddDishViewController.h"
#import "NetworkManager.h"
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <YYModel/YYModel.h>

@interface DishDetailViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *stepsLabel;

@end

@implementation DishDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"菜谱详情";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"编辑" style:UIBarButtonItemStylePlain target:self action:@selector(editTapped)];
    
    [self setupUI];
    [self updateUI];
}

- (void)editTapped {
    AddDishViewController *vc = [[AddDishViewController alloc] init];
    vc.familyId = self.dish.familyId;
    vc.existingDish = self.dish;
    vc.onSave = ^{
        [self fetchDishDetails];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)fetchDishDetails {
    [SVProgressHUD show];
    [[NetworkManager sharedManager] fetchDish:self.dish.dishId familyId:self.dish.familyId success:^(id  _Nullable response) {
        [SVProgressHUD dismiss];
        if ([response isKindOfClass:[NSDictionary class]]) {
            self.dish = [Dish yy_modelWithDictionary:response];
            [self updateUI];
        }
    } failure:^(NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showErrorWithStatus:@"刷新失败"];
    }];
}

- (void)setupUI {
    self.scrollView = [[UIScrollView alloc] init];
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];
    
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont boldSystemFontOfSize:24];
    self.nameLabel.numberOfLines = 0;
    [self.contentView addSubview:self.nameLabel];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(20);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
    }];
    
    self.descLabel = [[UILabel alloc] init];
    self.descLabel.font = [UIFont systemFontOfSize:16];
    self.descLabel.textColor = [UIColor darkGrayColor];
    self.descLabel.numberOfLines = 0;
    [self.contentView addSubview:self.descLabel];
    [self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(10);
        make.left.right.equalTo(self.nameLabel);
    }];
    
    UILabel *ingredientsTitle = [[UILabel alloc] init];
    ingredientsTitle.text = @"所需食材";
    ingredientsTitle.font = [UIFont boldSystemFontOfSize:18];
    [self.contentView addSubview:ingredientsTitle];
    [ingredientsTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.descLabel.mas_bottom).offset(20);
        make.left.right.equalTo(self.nameLabel);
    }];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.scrollEnabled = NO; // Let outer scroll view handle scrolling
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.contentView addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(ingredientsTitle.mas_bottom).offset(10);
        make.left.right.equalTo(self.contentView);
        make.height.mas_equalTo(0); // Will update later
    }];
    
    UILabel *stepsTitle = [[UILabel alloc] init];
    stepsTitle.text = @"烹饪步骤";
    stepsTitle.font = [UIFont boldSystemFontOfSize:18];
    [self.contentView addSubview:stepsTitle];
    [stepsTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tableView.mas_bottom).offset(20);
        make.left.right.equalTo(self.nameLabel);
    }];
    
    self.stepsLabel = [[UILabel alloc] init];
    self.stepsLabel.font = [UIFont systemFontOfSize:16];
    self.stepsLabel.numberOfLines = 0;
    [self.contentView addSubview:self.stepsLabel];
    [self.stepsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(stepsTitle.mas_bottom).offset(10);
        make.left.right.equalTo(self.nameLabel);
        make.bottom.equalTo(self.contentView).offset(-20);
    }];
}

- (void)updateUI {
    self.nameLabel.text = self.dish.name;
    self.descLabel.text = self.dish.desc ?: @"暂无描述";
    
    // Update table view height based on content
    CGFloat rowHeight = 44.0;
    CGFloat tableHeight = MAX(self.dish.ingredients.count * rowHeight, 0); // Ensure non-negative
    [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(tableHeight);
    }];
    [self.tableView reloadData];
    
    // Format steps
    if (self.dish.steps && self.dish.steps.count > 0) {
        NSMutableString *stepsText = [NSMutableString string];
        for (int i = 0; i < self.dish.steps.count; i++) {
            NSString *step = self.dish.steps[i];
            [stepsText appendFormat:@"%d. %@\n\n", i + 1, step];
        }
        self.stepsLabel.text = stepsText;
    } else {
        self.stepsLabel.text = @"暂无步骤";
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dish.ingredients.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    DishIngredient *ingredient = self.dish.ingredients[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@%@", ingredient.name, ingredient.quantity ?: @"", ingredient.unit ?: @""];
    return cell;
}

@end
