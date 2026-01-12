#import "ProfileViewController.h"
#import "FamilyListViewController.h"
#import "NetworkManager.h"
#import <Masonry/Masonry.h>
#import "SceneDelegate.h"
#import "LoginViewController.h"

@interface ProfileViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *menuItems;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"我的";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.menuItems = @[@"我的家庭", @"退出登录"];
    
    [self setupUI];
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

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text = self.menuItems[indexPath.row];
    
    if (indexPath.row == 1) { // Logout
        cell.textLabel.textColor = [UIColor redColor];
    } else {
        cell.textLabel.textColor = [UIColor labelColor];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 0) {
        // My Family
        FamilyListViewController *vc = [[FamilyListViewController alloc] init];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (indexPath.row == 1) {
        // Logout
        [[NetworkManager sharedManager] logout];
        
        // Navigate to Login
        SceneDelegate *sceneDelegate = (SceneDelegate *)[[UIApplication sharedApplication].connectedScenes.allObjects.firstObject delegate];
        LoginViewController *loginVC = [[LoginViewController alloc] init];
        sceneDelegate.window.rootViewController = loginVC;
        [sceneDelegate.window makeKeyAndVisible];
    }
}

@end
