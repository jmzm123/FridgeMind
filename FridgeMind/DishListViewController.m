#import "DishListViewController.h"
#import "NetworkManager.h"
#import "Dish.h"
#import <Masonry/Masonry.h>
#import <YYModel/YYModel.h>
#import "AddDishViewController.h"
#import "CookingViewController.h"

@interface DishListViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<Dish *> *dishes;
@property (nonatomic, strong) NSMutableArray<NSString *> *selectedDishIds;
@property (nonatomic, assign) BOOL isSelectionMode;
@end

@implementation DishListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"菜单";
    self.view.backgroundColor = [UIColor whiteColor];
    self.selectedDishIds = [NSMutableArray array];
    
    [self setupUI];
    [self loadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.isSelectionMode) {
        [self loadData];
    }
    [self updateNavigationItems];
}

- (void)updateNavigationItems {
    if (self.isSelectionMode) {
        self.navigationItem.title = @"选择菜品";
        self.navigationItem.rightBarButtonItems = @[
            [[UIBarButtonItem alloc] initWithTitle:@"决定" style:UIBarButtonItemStyleDone target:self action:@selector(decideTapped)],
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cookTapped)]
        ];
    } else {
        self.navigationItem.title = @"做饭";
        UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTapped)];
        UIBarButtonItem *cookItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"flame"] style:UIBarButtonItemStylePlain target:self action:@selector(cookTapped)];
        self.navigationItem.rightBarButtonItems = @[addItem, cookItem];
    }
}

- (void)setupUI {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self updateNavigationItems];
}

- (void)loadData {
    if (![NetworkManager sharedManager].currentFamilyId) return;
    
    [[NetworkManager sharedManager] fetchDishes:[NetworkManager sharedManager].currentFamilyId success:^(id  _Nullable response) {
        NSArray *data = response;
        if ([response isKindOfClass:[NSArray class]]) {
            self.dishes = [NSArray yy_modelArrayWithClass:[Dish class] json:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"Failed to fetch dishes: %@", error);
    }];
}

- (void)addTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加菜谱" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"AI 智能推荐" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CookingViewController *vc = [[CookingViewController alloc] init];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"手动添加" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        AddDishViewController *vc = [[AddDishViewController alloc] init];
        vc.familyId = [NetworkManager sharedManager].currentFamilyId;
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)cookTapped {
    self.isSelectionMode = !self.isSelectionMode;
    [self.tableView setEditing:self.isSelectionMode animated:YES];
    
    [self updateNavigationItems];
    
    if (!self.isSelectionMode) {
        [self.selectedDishIds removeAllObjects];
    }
}

- (void)decideTapped {
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    if (selectedRows.count == 0) {
        [self showError:@"请至少选择一道菜！"];
        return;
    }
    
    NSMutableArray *ids = [NSMutableArray array];
    for (NSIndexPath *indexPath in selectedRows) {
        Dish *d = self.dishes[indexPath.row];
        if (d.dishId) [ids addObject:d.dishId];
    }
    
    // Call API
    UIAlertController *loading = [UIAlertController alertControllerWithTitle:@"分析中..." message:@"正在检查冰箱..." preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:loading animated:YES completion:nil];
    
    [[NetworkManager sharedManager] makeCookDecision:[NetworkManager sharedManager].currentFamilyId dishIds:ids success:^(id  _Nullable response) {
        [loading dismissViewControllerAnimated:YES completion:^{
            [self showDecisionResult:response];
        }];
    } failure:^(NSError * _Nonnull error) {
        [loading dismissViewControllerAnimated:YES completion:^{
            [self showError:error.localizedDescription];
        }];
    }];
}

- (void)showDecisionResult:(NSDictionary *)result {
    NSArray *available = result[@"available"];
    NSArray *needPrep = result[@"needPreparation"];
    
    NSMutableString *msg = [NSMutableString string];
    
    if (available.count > 0) {
        [msg appendString:@"✅ 可以做：\n"];
        for (NSDictionary *d in available) {
            [msg appendFormat:@"- %@\n", d[@"name"]];
        }
        [msg appendString:@"\n"];
    }
    
    if (needPrep.count > 0) {
        [msg appendString:@"❄️ 需要解冻/准备：\n"];
        for (NSDictionary *d in needPrep) {
            [msg appendFormat:@"- %@ (%@)\n", d[@"name"], d[@"action"]];
        }
    }
    
    if (available.count == 0 && needPrep.count == 0) {
        [msg appendString:@"❌ 所选菜品缺少食材。"];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"决策结果" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self cookTapped]; // Exit selection mode
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showError:(NSString *)msg {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dishes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"DishCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    
    Dish *dish = self.dishes[indexPath.row];
    cell.textLabel.text = dish.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu 种食材", (unsigned long)dish.ingredients.count];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tableView.editing) {
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    // Show details or edit (future work)
}

@end
