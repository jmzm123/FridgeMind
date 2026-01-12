#import "DashboardViewController.h"
#import "NetworkManager.h"
#import <Masonry/Masonry.h>
#import "Ingredient.h"
#import "Dish.h"
#import <YYModel/NSObject+YYModel.h>

@interface DashboardViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<Ingredient *> *expiringIngredients;
@property (nonatomic, strong) NSArray<Ingredient *> *frozenIngredients;
@property (nonatomic, strong) NSArray *recommendedDishes;

@end

@implementation DashboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"首页";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadData];
}

- (void)setupUI {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)loadData {
    NSString *familyId = [NetworkManager sharedManager].currentFamilyId;
    if (!familyId) {
        // Handle no family selected case
        return;
    }
    
    dispatch_group_t group = dispatch_group_create();
    
    // Fetch Ingredients
    dispatch_group_enter(group);
    [[NetworkManager sharedManager] fetchIngredients:familyId success:^(id  _Nullable response) {
        NSArray *items = [NSArray yy_modelArrayWithClass:[Ingredient class] json:response];
        [self processIngredients:items];
        dispatch_group_leave(group);
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"Failed to fetch ingredients: %@", error);
        dispatch_group_leave(group);
    }];
    
    // Fetch Dishes (Recommendations)
    // Ideally we have a specific recommendation API, but for now we fetch all dishes and pick random or simple logic
    dispatch_group_enter(group);
    [[NetworkManager sharedManager] fetchDishes:familyId success:^(id  _Nullable response) {
        self.recommendedDishes = response; // Simplify for now
        dispatch_group_leave(group);
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"Failed to fetch dishes: %@", error);
        dispatch_group_leave(group);
    }];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)processIngredients:(NSArray<Ingredient *> *)ingredients {
    NSMutableArray *expiring = [NSMutableArray array];
    NSMutableArray *frozen = [NSMutableArray array];
    
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    for (Ingredient *item in ingredients) {
        // Check expiring (Today/Tomorrow)
        // Parse date string (assuming yyyy-MM-dd)
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd";
        NSDate *expDate = [formatter dateFromString:item.expirationDate];
        
        if (expDate) {
            NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:now toDate:expDate options:0];
            if (components.day <= 1 && components.day >= -1) { // -1 for expired yesterday/today? Let's say <= 1
                [expiring addObject:item];
            }
        }
        
        // Check frozen
        if ([item.storageType isEqualToString:@"frozen"]) {
            [frozen addObject:item];
        }
    }
    
    // Sort expiring by date
    [expiring sortUsingComparator:^NSComparisonResult(Ingredient *obj1, Ingredient *obj2) {
        return [obj1.expirationDate compare:obj2.expirationDate];
    }];
    
    // Limit to max 3
    if (expiring.count > 3) {
        self.expiringIngredients = [expiring subarrayWithRange:NSMakeRange(0, 3)];
    } else {
        self.expiringIngredients = expiring;
    }
    
    self.frozenIngredients = frozen;
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.expiringIngredients.count + self.frozenIngredients.count;
    } else {
        return MIN(self.recommendedDishes.count, 2); // Show max 2 recommendations
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"今日提醒";
    } else {
        return @"推荐做菜";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    if (indexPath.section == 0) {
        if (indexPath.row < self.expiringIngredients.count) {
            Ingredient *item = self.expiringIngredients[indexPath.row];
            cell.textLabel.text = [NSString stringWithFormat:@"%@ 明天过期", item.name]; // Simplify logic for demo
            cell.detailTextLabel.text = @"请尽快处理";
            cell.imageView.image = [UIImage systemImageNamed:@"exclamationmark.circle"];
            cell.imageView.tintColor = [UIColor redColor];
        } else {
            Ingredient *item = self.frozenIngredients[indexPath.row - self.expiringIngredients.count];
            cell.textLabel.text = [NSString stringWithFormat:@"%@ 需提前解冻", item.name];
            cell.imageView.image = [UIImage systemImageNamed:@"thermometer.snowflake"];
            cell.imageView.tintColor = [UIColor orangeColor];
        }
    } else {
        NSDictionary *dish = self.recommendedDishes[indexPath.row];
        cell.textLabel.text = dish[@"name"];
        cell.detailTextLabel.text = @"推荐尝试";
        cell.imageView.image = [UIImage systemImageNamed:@"hand.thumbsup"];
        cell.imageView.tintColor = [UIColor systemGreenColor];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        // Ingredients -> Go to Fridge Tab (Index 1)
        self.tabBarController.selectedIndex = 1;
    } else {
        // Dishes -> Go to Cooking Tab (Index 2)
        self.tabBarController.selectedIndex = 2;
    }
}

@end
