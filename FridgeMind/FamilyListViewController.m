#import "FamilyListViewController.h"
#import "NetworkManager.h"
#import <Masonry/Masonry.h>
#import "IngredientListViewController.h"
#import "DishListViewController.h"
#import "CreateFamilyViewController.h"

@interface FamilyListViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *families;
@end

@implementation FamilyListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"我的家庭";
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 添加 "Create" 按钮
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createTapped)];
    
    [self setupUI];
    [self loadData];
}

- (void)setupUI {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)loadData {
    [[NetworkManager sharedManager] fetchFamiliesSuccess:^(id  _Nullable response) {
        self.families = response;
        [self.tableView reloadData];
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"Failed to load families: %@", error);
    }];
}

- (void)createTapped {
    CreateFamilyViewController *vc = [[CreateFamilyViewController alloc] init];
    // 刷新回调
    vc.completionBlock = ^{
        [self loadData];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.families.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSDictionary *family = self.families[indexPath.row];
    cell.textLabel.text = family[@"name"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *family = self.families[indexPath.row];
    
    NSString *familyId = family[@"_id"] ?: family[@"id"];
    NSString *familyName = family[@"name"];
    
    // Create TabBarController
    UITabBarController *tabBarVC = [[UITabBarController alloc] init];
    tabBarVC.title = familyName;
    
    // Fridge Tab
    IngredientListViewController *fridgeVC = [[IngredientListViewController alloc] init];
    fridgeVC.familyId = familyId;
    fridgeVC.familyName = familyName;
    fridgeVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"冰箱" image:[UIImage systemImageNamed:@"snow"] tag:0];
    
    // Menu Tab
    DishListViewController *menuVC = [[DishListViewController alloc] init];
    menuVC.familyId = familyId;
    menuVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"菜单" image:[UIImage systemImageNamed:@"book"] tag:1];
    
    tabBarVC.viewControllers = @[fridgeVC, menuVC];
    
    [self.navigationController pushViewController:tabBarVC animated:YES];
}

@end
