
#import "CookingViewController.h"
#import "NetworkManager.h"
#import <Masonry/Masonry.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "RecipeResultViewController.h"

@interface CookingViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UISegmentedControl *methodSegmentedControl;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *generateButton;
@property (nonatomic, strong) NSArray *ingredients;
@property (nonatomic, strong) NSMutableSet *selectedIngredientNames;

@end

@implementation CookingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"做饭助手";
    
    self.selectedIngredientNames = [NSMutableSet set];
    
    [self setupUI];
    [self fetchIngredients];
}

- (void)setupUI {
    // 1. Method Segmented Control
    NSArray *items = @[@"炒菜", @"做汤", @"凉拌", @"其他"];
    self.methodSegmentedControl = [[UISegmentedControl alloc] initWithItems:items];
    self.methodSegmentedControl.selectedSegmentIndex = 0; // Default to Stir-fry
    [self.view addSubview:self.methodSegmentedControl];
    
    [self.methodSegmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(20);
        make.centerX.equalTo(self.view);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
    }];
    
    // 2. Generate Button (Bottom)
    self.generateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.generateButton setTitle:@"AI 推荐菜谱" forState:UIControlStateNormal];
    self.generateButton.backgroundColor = [UIColor systemBlueColor];
    [self.generateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.generateButton.layer.cornerRadius = 8;
    self.generateButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.generateButton addTarget:self action:@selector(generateTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.generateButton];
    
    [self.generateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.height.mas_equalTo(50);
    }];
    
    // 3. Collection View (Middle)
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(100, 40);
    layout.minimumInteritemSpacing = 10;
    layout.minimumLineSpacing = 10;
    layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.allowsMultipleSelection = YES;
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [self.view addSubview:self.collectionView];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.methodSegmentedControl.mas_bottom).offset(20);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.generateButton.mas_top).offset(-20);
    }];
    
    UILabel *hintLabel = [[UILabel alloc] init];
    hintLabel.text = @"请选择冰箱里的食材：";
    hintLabel.font = [UIFont systemFontOfSize:14];
    hintLabel.textColor = [UIColor grayColor];
    [self.view addSubview:hintLabel];
    
    [hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.collectionView.mas_top).offset(-5);
        make.left.equalTo(self.view).offset(15);
    }];
}

- (void)fetchIngredients {
    NSString *familyId = [NetworkManager sharedManager].currentFamilyId;
    if (!familyId) return;
    
    [SVProgressHUD show];
    [[NetworkManager sharedManager] fetchIngredients:familyId success:^(id  _Nullable response) {
        [SVProgressHUD dismiss];
        if ([response isKindOfClass:[NSArray class]]) {
            self.ingredients = response;
            [self.collectionView reloadData];
        }
    } failure:^(NSError * _Nonnull error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }];
}

#pragma mark - Actions

- (void)generateTapped {
    if (self.selectedIngredientNames.count == 0) {
        [SVProgressHUD showInfoWithStatus:@"请至少选择一种食材"];
        return;
    }
    
    NSString *method = [self.methodSegmentedControl titleForSegmentAtIndex:self.methodSegmentedControl.selectedSegmentIndex];
    NSArray *ingredients = [self.selectedIngredientNames allObjects];
    
    [SVProgressHUD showWithStatus:@"AI 正在思考..."];
    [[NetworkManager sharedManager] suggestRecipeWithIngredients:ingredients cookingMethod:method success:^(id  _Nullable response) {
        [SVProgressHUD dismiss];
        [self showRecipeResult:response];
    } failure:^(NSError * _Nonnull error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }];
}

- (void)showRecipeResult:(NSDictionary *)recipeData {
    RecipeResultViewController *vc = [[RecipeResultViewController alloc] init];
    vc.recipeData = recipeData;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.ingredients.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    // Remove old views
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSDictionary *item = self.ingredients[indexPath.item];
    NSString *name = item[@"name"];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = name;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:14];
    label.layer.cornerRadius = 8;
    label.layer.masksToBounds = YES;
    label.layer.borderWidth = 1;
    
    if ([self.selectedIngredientNames containsObject:name]) {
        label.backgroundColor = [UIColor systemBlueColor];
        label.textColor = [UIColor whiteColor];
        label.layer.borderColor = [UIColor systemBlueColor].CGColor;
    } else {
        label.backgroundColor = [UIColor systemGray6Color];
        label.textColor = [UIColor blackColor];
        label.layer.borderColor = [UIColor systemGray4Color].CGColor;
    }
    
    [cell.contentView addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(cell.contentView);
    }];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = self.ingredients[indexPath.item];
    NSString *name = item[@"name"];
    
    if ([self.selectedIngredientNames containsObject:name]) {
        [self.selectedIngredientNames removeObject:name];
    } else {
        [self.selectedIngredientNames addObject:name];
    }
    
    [UIView performWithoutAnimation:^{
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }];
}

@end
