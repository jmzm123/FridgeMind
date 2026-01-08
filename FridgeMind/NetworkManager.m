#import "NetworkManager.h"
#import <AFNetworking/AFNetworking.h>

static NSString * const kBaseURL = @"http://localhost:3000/api/v1";
static NSString * const kAuthTokenKey = @"kAuthTokenKey";
static NSString * const kCurrentFamilyIdKey = @"kCurrentFamilyIdKey";

@interface NetworkManager ()
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@end

@implementation NetworkManager

+ (instancetype)sharedManager {
    static NetworkManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[NetworkManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:kBaseURL]];
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        _sessionManager.requestSerializer.timeoutInterval = 120.0; // Increase timeout for AI calls
        _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        
        // Load stored token
        NSString *token = [[NSUserDefaults standardUserDefaults] stringForKey:kAuthTokenKey];
        if (token) {
            self.authToken = token;
        }
        
        // Load stored familyId
        self.currentFamilyId = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentFamilyIdKey];
    }
    return self;
}

- (void)setAuthToken:(NSString *)authToken {
    _authToken = authToken;
    if (authToken) {
        NSString *header = [NSString stringWithFormat:@"Bearer %@", authToken];
        [_sessionManager.requestSerializer setValue:header forHTTPHeaderField:@"Authorization"];
        [[NSUserDefaults standardUserDefaults] setObject:authToken forKey:kAuthTokenKey];
    } else {
        [_sessionManager.requestSerializer setValue:nil forHTTPHeaderField:@"Authorization"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kAuthTokenKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setCurrentFamilyId:(NSString *)currentFamilyId {
    _currentFamilyId = currentFamilyId;
    if (currentFamilyId) {
        [[NSUserDefaults standardUserDefaults] setObject:currentFamilyId forKey:kCurrentFamilyIdKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCurrentFamilyIdKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isLoggedIn {
    return self.authToken.length > 0;
}

- (void)logout {
    self.authToken = nil;
    self.currentFamilyId = nil;
}

#pragma mark - Auth

- (void)sendCodeToEmail:(NSString *)email success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSDictionary *params = @{@"email": email};
    [_sessionManager POST:@"auth/send-code" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)verifyCode:(NSString *)code email:(NSString *)email success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSDictionary *params = @{@"email": email, @"code": code};
    [_sessionManager POST:@"auth/verify-code" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // 保存 Token
        if (responseObject[@"token"]) {
            self.authToken = responseObject[@"token"];
        }
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

#pragma mark - Family

- (void)fetchFamiliesSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    [_sessionManager GET:@"families" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)createFamily:(NSString *)name success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSDictionary *params = @{@"name": name};
    [_sessionManager POST:@"families" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)fetchIngredients:(NSString *)familyId success:(SuccessBlock)success failure:(FailureBlock)failure {
    [self fetchIngredients:familyId updatedSince:nil success:success failure:failure];
}

- (void)fetchIngredients:(NSString *)familyId updatedSince:(NSString * _Nullable)since success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSString *url = [NSString stringWithFormat:@"families/%@/ingredients", familyId];
    NSDictionary *params = nil;
    if (since) {
        params = @{@"updated_since": since};
    }
    
    [_sessionManager GET:url parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)addIngredient:(NSDictionary *)params success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSString *familyId = params[@"familyId"];
    if (!familyId) {
        // Fallback or error handling if familyId is missing
        if (failure) failure([NSError errorWithDomain:@"com.fridgemind" code:400 userInfo:@{NSLocalizedDescriptionKey: @"Missing familyId"}]);
        return;
    }
    
    NSMutableDictionary *bodyParams = [params mutableCopy];
    [bodyParams removeObjectForKey:@"familyId"]; // Clean up body
    
    NSString *url = [NSString stringWithFormat:@"families/%@/ingredients", familyId];
    
    [_sessionManager POST:url parameters:bodyParams headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)updateIngredient:(NSString *)ingredientId
                familyId:(NSString *)familyId
                  params:(NSDictionary *)params
                 success:(SuccessBlock)success
                 failure:(FailureBlock)failure {
    // Backend route is /api/v1/ingredients/:id
    NSString *url = [NSString stringWithFormat:@"ingredients/%@", ingredientId];
    
    NSMutableDictionary *bodyParams = [params mutableCopy];
    [bodyParams removeObjectForKey:@"familyId"];
    
    [_sessionManager PUT:url parameters:bodyParams headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Update failed: %@", error);
        if (failure) failure(error);
    }];
}

- (void)deleteIngredient:(NSString *)ingredientId success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSString *url = [NSString stringWithFormat:@"ingredients/%@", ingredientId];
    [_sessionManager DELETE:url parameters:nil headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

#pragma mark - AI

- (void)suggestRecipeWithIngredients:(NSArray<NSString *> *)ingredients cookingMethod:(NSString *)method success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSDictionary *params = @{
        @"ingredients": ingredients,
        @"cookingMethod": method ?: @"炒菜"
    };
    [_sessionManager POST:@"ai/suggest-recipe" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)identifyIngredientsWithImageBase64:(NSString *)imageBase64 success:(SuccessBlock)success failure:(FailureBlock)failure {
    // Backend expects full Data URI scheme
    NSString *dataURI = [NSString stringWithFormat:@"data:image/jpeg;base64,%@", imageBase64];
    NSDictionary *params = @{@"imageUrl": dataURI};
    
    [_sessionManager POST:@"ai/identify-ingredients" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

#pragma mark - Dish

- (void)fetchDishes:(NSString *)familyId success:(SuccessBlock)success failure:(FailureBlock)failure {
    // GET /api/v1/families/:familyId/dishes
    NSString *url = [NSString stringWithFormat:@"families/%@/dishes", familyId];
    [_sessionManager GET:url parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)fetchDish:(NSString *)dishId familyId:(NSString *)familyId success:(SuccessBlock)success failure:(FailureBlock)failure {
    // GET /api/v1/families/:familyId/dishes/:id
    NSString *url = [NSString stringWithFormat:@"families/%@/dishes/%@", familyId, dishId];
    [_sessionManager GET:url parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)createDish:(NSDictionary *)params familyId:(NSString *)familyId success:(SuccessBlock)success failure:(FailureBlock)failure {
    // POST /api/v1/families/:familyId/dishes
    NSString *url = [NSString stringWithFormat:@"families/%@/dishes", familyId];
    [_sessionManager POST:url parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)updateDish:(NSString *)dishId familyId:(NSString *)familyId params:(NSDictionary *)params success:(SuccessBlock)success failure:(FailureBlock)failure {
    // PUT /api/v1/families/:familyId/dishes/:id
    NSString *url = [NSString stringWithFormat:@"families/%@/dishes/%@", familyId, dishId];
    [_sessionManager PUT:url parameters:params headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)deleteDish:(NSString *)dishId familyId:(NSString *)familyId success:(SuccessBlock)success failure:(FailureBlock)failure {
    // DELETE /api/v1/families/:familyId/dishes/:id
    NSString *url = [NSString stringWithFormat:@"families/%@/dishes/%@", familyId, dishId];
    [_sessionManager DELETE:url parameters:nil headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)makeCookDecision:(NSString *)familyId dishIds:(NSArray *)dishIds success:(SuccessBlock)success failure:(FailureBlock)failure {
    // POST /api/v1/families/:familyId/dishes/cook-decision
    NSString *url = [NSString stringWithFormat:@"families/%@/dishes/cook-decision", familyId];
    NSDictionary *params = @{@"dishIds": dishIds};
    [_sessionManager POST:url parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

@end
