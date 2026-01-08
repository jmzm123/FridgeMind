#import "DishListViewController.h"
#import "NetworkManager.h"
#import "Dish.h"
#import <Masonry/Masonry.h>
#import <YYModel/YYModel.h>
#import "AddDishViewController.h"

@interface DishListViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<Dish *> *dishes;
@property (nonatomic, strong) NSMutableArray<NSString *> *selectedDishIds;
@property (nonatomic, assign) BOOL isSelectionMode;
@end

@implementation DishListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Menu";
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
    UINavigationItem *navItem = self.tabBarController.navigationItem ?: self.navigationItem;
    
    if (self.isSelectionMode) {
        navItem.title = @"Select Dishes";
        navItem.rightBarButtonItems = @[
            [[UIBarButtonItem alloc] initWithTitle:@"Decide" style:UIBarButtonItemStyleDone target:self action:@selector(decideTapped)],
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cookTapped)]
        ];
    } else {
        navItem.title = @"Menu";
        UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTapped)];
        UIBarButtonItem *cookItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"flame"] style:UIBarButtonItemStylePlain target:self action:@selector(cookTapped)];
        navItem.rightBarButtonItems = @[addItem, cookItem];
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
    if (!self.familyId) return;
    
    [[NetworkManager sharedManager] fetchDishes:self.familyId success:^(id  _Nullable response) {
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
    AddDishViewController *vc = [[AddDishViewController alloc] init];
    vc.familyId = self.familyId;
    [self.navigationController pushViewController:vc animated:YES];
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
        [self showError:@"Select at least one dish!"];
        return;
    }
    
    NSMutableArray *ids = [NSMutableArray array];
    for (NSIndexPath *indexPath in selectedRows) {
        Dish *d = self.dishes[indexPath.row];
        if (d.dishId) [ids addObject:d.dishId];
    }
    
    // Call API
    UIAlertController *loading = [UIAlertController alertControllerWithTitle:@"Analyzing..." message:@"Checking your fridge..." preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:loading animated:YES completion:nil];
    
    [[NetworkManager sharedManager] makeCookDecision:self.familyId dishIds:ids success:^(id  _Nullable response) {
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
        [msg appendString:@"✅ Ready to Cook:\n"];
        for (NSDictionary *d in available) {
            [msg appendFormat:@"- %@\n", d[@"name"]];
        }
        [msg appendString:@"\n"];
    }
    
    if (needPrep.count > 0) {
        [msg appendString:@"❄️ Needs Defrost/Prep:\n"];
        for (NSDictionary *d in needPrep) {
            [msg appendFormat:@"- %@ (%@)\n", d[@"name"], d[@"action"]];
        }
    }
    
    if (available.count == 0 && needPrep.count == 0) {
        [msg appendString:@"❌ Missing ingredients for all selected dishes."];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Decision" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self cookTapped]; // Exit selection mode
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showError:(NSString *)msg {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
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
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu ingredients", (unsigned long)dish.ingredients.count];
    
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
