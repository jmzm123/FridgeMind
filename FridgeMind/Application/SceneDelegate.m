//
//  SceneDelegate.m
//  FridgeMind
//
//  Created by leizhenhua on 2026/1/7.
//

#import "SceneDelegate.h"
#import "LoginViewController.h"
#import "NetworkManager.h"
#import "FamilyListViewController.h"
#import "DashboardViewController.h"
#import "IngredientListViewController.h"
#import "DishListViewController.h"
#import "ProfileViewController.h"
#import "SyncManager.h"

@interface SceneDelegate ()

@end

@implementation SceneDelegate


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) return;
    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
    // 直接进入主页，跳过登录
    [self showMainInterface];
    
    /*
    if ([[NetworkManager sharedManager] isLoggedIn]) {
        if ([NetworkManager sharedManager].currentFamilyId) {
            [self showMainInterface];
        } else {
            // Logged in but no family selected -> Go to Family List
            FamilyListViewController *familyVC = [[FamilyListViewController alloc] init];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:familyVC];
            self.window.rootViewController = nav;
        }
    } else {
        LoginViewController *loginVC = [[LoginViewController alloc] init];
        self.window.rootViewController = loginVC;
    }
    */
    
    [self.window makeKeyAndVisible];
}

- (void)showMainInterface {
    UITabBarController *tabBarVC = [[UITabBarController alloc] init];
    
    // 1. Home (Dashboard)
    DashboardViewController *homeVC = [[DashboardViewController alloc] init];
    UINavigationController *homeNav = [[UINavigationController alloc] initWithRootViewController:homeVC];
    homeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"首页" image:[UIImage systemImageNamed:@"house"] tag:0];
    
    // 2. Fridge (IngredientList)
    IngredientListViewController *fridgeVC = [[IngredientListViewController alloc] init];
    UINavigationController *fridgeNav = [[UINavigationController alloc] initWithRootViewController:fridgeVC];
    fridgeNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"冰箱" image:[UIImage systemImageNamed:@"snowflake"] tag:1];
    
    // 3. Cooking (DishList)
    DishListViewController *cookingVC = [[DishListViewController alloc] init];
    UINavigationController *cookingNav = [[UINavigationController alloc] initWithRootViewController:cookingVC];
    cookingNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"做饭" image:[UIImage systemImageNamed:@"flame"] tag:2];
    
    // 4. Me (Profile)
    ProfileViewController *meVC = [[ProfileViewController alloc] init];
    UINavigationController *meNav = [[UINavigationController alloc] initWithRootViewController:meVC];
    meNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"我的" image:[UIImage systemImageNamed:@"person"] tag:3];
    
    tabBarVC.viewControllers = @[homeNav, fridgeNav, cookingNav, meNav];
    tabBarVC.tabBar.tintColor = [UIColor systemBlueColor]; // Or user preferred color
    
    self.window.rootViewController = tabBarVC;
    
    // Trigger sync on launch/entry - Disabled for local mode
    // [[SyncManager sharedManager] sync];
}


- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
}


- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
}


@end
