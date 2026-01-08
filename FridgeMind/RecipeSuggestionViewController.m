#import "RecipeSuggestionViewController.h"
#import <Masonry/Masonry.h>

@interface RecipeSuggestionViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *steps;
@property (nonatomic, strong) NSArray *missingIngredients;
@end

@implementation RecipeSuggestionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.recipeData[@"name"] ?: @"Suggested Recipe";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.steps = self.recipeData[@"steps"] ?: @[];
    self.missingIngredients = self.recipeData[@"missingIngredients"] ?: @[];
    
    [self setupUI];
}

- (void)setupUI {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // Header View for Description
    NSString *desc = self.recipeData[@"description"];
    if (desc) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 100)];
        UILabel *label = [[UILabel alloc] init];
        label.text = desc;
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:16];
        [header addSubview:label];
        
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(header).insets(UIEdgeInsetsMake(10, 20, 10, 20));
        }];
        
        // Simple height calculation
        CGSize size = [label sizeThatFits:CGSizeMake(self.view.frame.size.width - 40, CGFLOAT_MAX)];
        header.frame = CGRectMake(0, 0, self.view.frame.size.width, size.height + 20);
        
        self.tableView.tableHeaderView = header;
    }
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; // Missing Ingredients + Steps
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return self.missingIngredients.count;
    return self.steps.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return self.missingIngredients.count > 0 ? @"Missing Ingredients" : nil;
    return @"Steps";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.textLabel.numberOfLines = 0;
    }
    
    if (indexPath.section == 0) {
        cell.textLabel.text = self.missingIngredients[indexPath.row];
        cell.textLabel.textColor = [UIColor systemRedColor];
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"%ld. %@", (long)indexPath.row + 1, self.steps[indexPath.row]];
        if (@available(iOS 13.0, *)) {
            cell.textLabel.textColor = [UIColor labelColor];
        } else {
            cell.textLabel.textColor = [UIColor blackColor];
        }
    }
    
    return cell;
}

@end
