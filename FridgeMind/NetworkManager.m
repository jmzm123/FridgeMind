#import "NetworkManager.h"
#import <AFNetworking/AFNetworking.h>

static NSString * const kBaseURL = @"http://localhost:3000/api/v1";

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
        _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        // 允许非标准 JSON 响应 (可选)
        // _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", nil];
    }
    return self;
}

- (void)setAuthToken:(NSString *)authToken {
    _authToken = authToken;
    if (authToken) {
        NSString *header = [NSString stringWithFormat:@"Bearer %@", authToken];
        [_sessionManager.requestSerializer setValue:header forHTTPHeaderField:@"Authorization"];
    } else {
        [_sessionManager.requestSerializer setValue:nil forHTTPHeaderField:@"Authorization"];
    }
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
    NSString *url = [NSString stringWithFormat:@"ingredient?familyId=%@", familyId];
    [_sessionManager GET:url parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

- (void)addIngredient:(NSDictionary *)params success:(SuccessBlock)success failure:(FailureBlock)failure {
    [_sessionManager POST:@"ingredient" parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) failure(error);
    }];
}

@end
