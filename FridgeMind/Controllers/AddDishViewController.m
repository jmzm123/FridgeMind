#import "AddDishViewController.h"
#import <Masonry/Masonry.h>
#import "NetworkManager.h"
#import "Dish.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface AddDishViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *nameTextField;
@property (nonatomic, strong) UITextField *descTextField;
@property (nonatomic, strong) UISegmentedControl *methodSegment;
@property (nonatomic, strong) NSMutableArray<DishIngredient *> *ingredients;
@property (nonatomic, strong) NSMutableArray<NSString *> *steps;
@end

@implementation AddDishViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.existingDish ? @"编辑菜品" : @"添加菜品";
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (self.existingDish) {
        self.ingredients = [self.existingDish.ingredients mutableCopy];
        self.steps = [self.existingDish.steps mutableCopy];
        if (!self.steps) self.steps = [NSMutableArray array];
    } else {
        self.ingredients = [NSMutableArray array];
        self.steps = [NSMutableArray array];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveTapped)];
    
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
    
    // Register Cells
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"InputCell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"MethodCell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"IngCell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"StepCell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"AddCell"];
}

- (void)saveTapped {
    NSString *name = self.nameTextField.text;
    if (name.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"请输入菜品名称"];
        return;
    }
    
    NSString *desc = self.descTextField.text ?: @"";
    NSString *method = [self.methodSegment titleForSegmentAtIndex:self.methodSegment.selectedSegmentIndex];
    
    if (self.ingredients.count == 0) {
        [SVProgressHUD showErrorWithStatus:@"请至少添加一种食材"];
        return;
    }
    
    NSMutableArray *ingredientsData = [NSMutableArray array];
    for (DishIngredient *ing in self.ingredients) {
        [ingredientsData addObject:@{
            @"name": ing.name,
            @"quantity": ing.quantity ?: @"",
            @"unit": ing.unit ?: @"",
            @"storageType": ing.storageType ?: @"chilled"
        }];
    }
    
    NSDictionary *params = @{
        @"name": name,
        @"description": desc,
        @"cookingMethod": method,
        @"ingredients": ingredientsData,
        @"steps": self.steps
    };
    
    [SVProgressHUD showWithStatus:@"保存中..."];
    
    if (self.existingDish) {
        [[NetworkManager sharedManager] updateDish:self.existingDish.dishId familyId:self.familyId params:params success:^(id  _Nullable response) {
            [SVProgressHUD dismiss];
            [SVProgressHUD showSuccessWithStatus:@"更新成功"];
            if (self.onSave) self.onSave();
            [self.navigationController popViewControllerAnimated:YES];
        } failure:^(NSError * _Nonnull error) {
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        }];
    } else {
        [[NetworkManager sharedManager] createDish:params familyId:self.familyId success:^(id  _Nullable response) {
            [SVProgressHUD dismiss];
            [SVProgressHUD showSuccessWithStatus:@"创建成功"];
            if (self.onSave) self.onSave();
            [self.navigationController popViewControllerAnimated:YES];
        } failure:^(NSError * _Nonnull error) {
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        }];
    }
}

- (void)addIngredientTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加食材" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"名称 (例如: 西红柿)";
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"用量 (例如: 2个)";
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"单位 (可选)";
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"存储方式 (frozen/chilled/pantry)";
        textField.text = @"chilled";
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"添加" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *name = alert.textFields[0].text;
        NSString *qty = alert.textFields[1].text;
        NSString *unit = alert.textFields[2].text;
        NSString *storage = alert.textFields[3].text;
        
        if (name.length > 0) {
            DishIngredient *ing = [[DishIngredient alloc] init];
            ing.name = name;
            ing.quantity = qty;
            ing.unit = unit;
            ing.storageType = storage;
            [self.ingredients addObject:ing];
            [self.tableView reloadData];
        }
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)addStepTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"添加步骤" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"描述步骤...";
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"添加" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *step = alert.textFields[0].text;
        if (step.length > 0) {
            [self.steps addObject:step];
            [self.tableView reloadData];
        }
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3; // Info, Ingredients, Steps
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 3; // Name, Desc, Method
    if (section == 1) return self.ingredients.count + 1;
    if (section == 2) return self.steps.count + 1;
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"基本信息";
    if (section == 1) return @"食材";
    if (section == 2) return @"步骤";
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"InputCell"];
            if (!self.nameTextField) {
                self.nameTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 0, 300, 44)];
                self.nameTextField.placeholder = @"菜品名称";
                if (self.existingDish) self.nameTextField.text = self.existingDish.name;
            }
            [cell.contentView addSubview:self.nameTextField];
            [self.nameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(cell.contentView).offset(16);
                make.right.equalTo(cell.contentView).offset(-16);
                make.top.bottom.equalTo(cell.contentView);
            }];
            return cell;
        } else if (indexPath.row == 1) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"InputCell"];
            if (!self.descTextField) {
                self.descTextField = [[UITextField alloc] init];
                self.descTextField.placeholder = @"描述 (可选)";
                if (self.existingDish) self.descTextField.text = self.existingDish.desc;
            }
            [cell.contentView addSubview:self.descTextField];
            [self.descTextField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(cell.contentView).offset(16);
                make.right.equalTo(cell.contentView).offset(-16);
                make.top.bottom.equalTo(cell.contentView);
            }];
            return cell;
        } else {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MethodCell"];
            if (!self.methodSegment) {
                self.methodSegment = [[UISegmentedControl alloc] initWithItems:@[@"炒菜", @"做汤", @"凉拌", @"其他"]];
                self.methodSegment.selectedSegmentIndex = 0;
                if (self.existingDish && self.existingDish.cookingMethod) {
                    NSArray *methods = @[@"炒菜", @"做汤", @"凉拌", @"其他"];
                    NSUInteger idx = [methods indexOfObject:self.existingDish.cookingMethod];
                    if (idx != NSNotFound) self.methodSegment.selectedSegmentIndex = idx;
                }
            }
            [cell.contentView addSubview:self.methodSegment];
            [self.methodSegment mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(cell.contentView).offset(16);
                make.right.equalTo(cell.contentView).offset(-16);
                make.centerY.equalTo(cell.contentView);
            }];
            return cell;
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == self.ingredients.count) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddCell" forIndexPath:indexPath];
            cell.textLabel.text = @"添加食材";
            cell.textLabel.textColor = [UIColor systemBlueColor];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            return cell;
        } else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IngCell" forIndexPath:indexPath];
            if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"IngCell"];
            DishIngredient *ing = self.ingredients[indexPath.row];
            cell.textLabel.text = ing.name;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ (%@)", ing.quantity, ing.unit, ing.storageType];
            return cell;
        }
    } else {
        if (indexPath.row == self.steps.count) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddCell" forIndexPath:indexPath];
            cell.textLabel.text = @"添加步骤";
            cell.textLabel.textColor = [UIColor systemBlueColor];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            return cell;
        } else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StepCell" forIndexPath:indexPath];
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.text = [NSString stringWithFormat:@"%ld. %@", (long)indexPath.row + 1, self.steps[indexPath.row]];
            return cell;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1 && indexPath.row == self.ingredients.count) {
        [self addIngredientTapped];
    } else if (indexPath.section == 2 && indexPath.row == self.steps.count) {
        [self addStepTapped];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row < self.ingredients.count) return YES;
    if (indexPath.section == 2 && indexPath.row < self.steps.count) return YES;
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (indexPath.section == 1) {
            [self.ingredients removeObjectAtIndex:indexPath.row];
        } else if (indexPath.section == 2) {
            [self.steps removeObjectAtIndex:indexPath.row];
        }
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (indexPath.section == 2) {
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone]; // Update step numbers
        }
    }
}

@end
