#import "IngredientListViewController.h"
#import <Masonry/Masonry.h>
#import "NetworkManager.h"
#import <YYModel/YYModel.h>
#import <SDWebImage/SDWebImage.h>
#import "AddIngredientViewController.h"

@interface Ingredient : NSObject
@property (nonatomic, copy) NSString *_id;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) double quantity;
@property (nonatomic, copy) NSString *unit;
@property (nonatomic, copy) NSString *expirationDate;
@property (nonatomic, copy) NSString *imageUrl;
@end

@implementation Ingredient
@end

@interface IngredientListViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<Ingredient *> *ingredients;
@end

@implementation IngredientListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.familyName ?: @"Ingredients";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadData];
}

- (void)setupUI {
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // Add Item Button (Right Bar Button)
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTapped)];
    self.navigationItem.rightBarButtonItem = addItem;
}

- (void)loadData {
    if (!self.familyId) return;
    
    [[NetworkManager sharedManager] fetchIngredients:self.familyId success:^(id  _Nullable response) {
        NSArray *dataArray = response;
        if ([response isKindOfClass:[NSDictionary class]]) {
            // Check if response has "data" field or is just the array
             if (response[@"data"]) {
                 dataArray = response[@"data"];
             }
        }
        
        // If dataArray is still not an array (e.g. wrapper object), we might need more logic.
        // But let's assume standard array for now.
        if ([dataArray isKindOfClass:[NSArray class]]) {
            self.ingredients = [NSArray yy_modelArrayWithClass:[Ingredient class] json:dataArray];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"Failed to fetch ingredients: %@", error);
    }];
}

- (void)addTapped {
    // Navigate to Add Ingredient VC
    // TODO: Implement AddIngredientViewController
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.ingredients.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"IngredientCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    
    Ingredient *ingredient = self.ingredients[indexPath.row];
    cell.textLabel.text = ingredient.name;
    
    // Format subtitle
    NSString *dateStr = @"";
    if (ingredient.expirationDate) {
        // Simple string extraction or formatting
        // Assuming backend sends ISO string
        if (ingredient.expirationDate.length >= 10) {
             dateStr = [NSString stringWithFormat:@" - Expires: %@", [ingredient.expirationDate substringToIndex:10]];
        }
    }
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f %@%@", ingredient.quantity, ingredient.unit ?: @"", dateStr];
    
    if (ingredient.imageUrl) {
         [cell.imageView sd_setImageWithURL:[NSURL URLWithString:ingredient.imageUrl] placeholderImage:[UIImage systemImageNamed:@"photo"]];
    } else {
        cell.imageView.image = [UIImage systemImageNamed:@"carrot"];
    }
    
    return cell;
}

@end
