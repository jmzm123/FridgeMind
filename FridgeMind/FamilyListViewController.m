#import "FamilyListViewController.h"
#import "NetworkManager.h"
#import <Masonry/Masonry.h>
#import "IngredientListViewController.h"
#import "CreateFamilyViewController.h"

@interface FamilyListViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *families;
@end

@implementation FamilyListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"My Families";
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
    
    IngredientListViewController *vc = [[IngredientListViewController alloc] init];
    vc.familyId = family[@"_id"] ?: family[@"id"];
    vc.familyName = family[@"name"];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
