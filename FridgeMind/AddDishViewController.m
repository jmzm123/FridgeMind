#import "AddDishViewController.h"
#import <Masonry/Masonry.h>
#import "NetworkManager.h"
#import "Dish.h"

@interface AddDishViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *nameTextField;
@property (nonatomic, strong) NSMutableArray<DishIngredient *> *ingredients;
@end

@implementation AddDishViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"添加菜品";
    self.view.backgroundColor = [UIColor whiteColor];
    self.ingredients = [NSMutableArray array];
    
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
}

- (void)saveTapped {
    NSString *name = self.nameTextField.text;
    if (name.length == 0) {
        [self showError:@"请输入菜品名称"];
        return;
    }
    
    if (self.ingredients.count == 0) {
        [self showError:@"请至少添加一种食材"];
        return;
    }
    
    NSMutableArray *ingredientsData = [NSMutableArray array];
    for (DishIngredient *ing in self.ingredients) {
        [ingredientsData addObject:@{
            @"name": ing.name,
            @"quantity": @(ing.quantity),
            @"unit": ing.unit ?: @"",
            @"storageType": ing.storageType ?: @"chilled"
        }];
    }
    
    NSDictionary *params = @{
        @"name": name,
        @"ingredients": ingredientsData
    };
    
    UIAlertController *loading = [UIAlertController alertControllerWithTitle:@"保存中..." message:nil preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:loading animated:YES completion:nil];
    
    [[NetworkManager sharedManager] createDish:params familyId:self.familyId success:^(id  _Nullable response) {
        [loading dismissViewControllerAnimated:YES completion:^{
            [self.navigationController popViewControllerAnimated:YES];
        }];
    } failure:^(NSError * _Nonnull error) {
        [loading dismissViewControllerAnimated:YES completion:^{
            [self showError:error.localizedDescription];
        }];
    }];
}

- (void)showError:(NSString *)msg {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)addIngredientTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add Ingredient" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Name (e.g. Tomato)";
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Quantity (e.g. 2)";
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Unit (e.g. pcs)";
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Storage (frozen/chilled/room)";
        textField.text = @"chilled";
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"添加" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *name = alert.textFields[0].text;
        NSString *qtyStr = alert.textFields[1].text;
        NSString *unit = alert.textFields[2].text;
        NSString *storage = alert.textFields[3].text;
        
        if (name.length > 0) {
            DishIngredient *ing = [[DishIngredient alloc] init];
            ing.name = name;
            ing.quantity = [qtyStr doubleValue];
            ing.unit = unit;
            ing.storageType = storage;
            
            [self.ingredients addObject:ing];
            [self.tableView reloadData];
        }
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    return self.ingredients.count + 1; // +1 for Add button
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"Dish Info";
    return @"食材";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NameCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NameCell"];
            self.nameTextField = [[UITextField alloc] init];
            self.nameTextField.placeholder = @"菜品名称";
            self.nameTextField.delegate = self;
            [cell.contentView addSubview:self.nameTextField];
            [self.nameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(cell.contentView).offset(16);
                make.right.equalTo(cell.contentView).offset(-16);
                make.top.bottom.equalTo(cell.contentView);
            }];
        }
        return cell;
    } else {
        if (indexPath.row == self.ingredients.count) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AddCell"];
                cell.textLabel.textColor = [UIColor systemBlueColor];
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                cell.textLabel.text = @"添加食材";
            }
            return cell;
        } else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IngCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"IngCell"];
            }
            DishIngredient *ing = self.ingredients[indexPath.row];
            cell.textLabel.text = ing.name;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f %@ (%@)", ing.quantity, ing.unit, ing.storageType];
            return cell;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1 && indexPath.row == self.ingredients.count) {
        [self addIngredientTapped];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == 1 && indexPath.row < self.ingredients.count);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.ingredients removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
