#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SuccessBlock)(id _Nullable response);
typedef void(^FailureBlock)(NSError *error);

@interface NetworkManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, strong, nullable) NSString *authToken;
@property (nonatomic, strong, nullable) NSString *currentFamilyId;

- (BOOL)isLoggedIn;
- (void)logout;

// Auth
- (void)sendCodeToEmail:(NSString *)email
                success:(SuccessBlock)success
                failure:(FailureBlock)failure;

- (void)verifyCode:(NSString *)code
             email:(NSString *)email
           success:(SuccessBlock)success
           failure:(FailureBlock)failure;

// Family
- (void)createFamily:(NSString *)name
             success:(SuccessBlock)success
             failure:(FailureBlock)failure;

- (void)fetchFamiliesSuccess:(SuccessBlock)success
                     failure:(FailureBlock)failure;

- (void)fetchIngredients:(NSString *)familyId success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)addIngredient:(NSDictionary *)params success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)updateIngredient:(NSString *)ingredientId
                familyId:(NSString *)familyId
                  params:(NSDictionary *)params
                 success:(SuccessBlock)success
                 failure:(FailureBlock)failure;

#pragma mark - AI

- (void)suggestRecipeWithIngredients:(NSArray<NSString *> *)ingredients success:(SuccessBlock)success failure:(FailureBlock)failure;

- (void)identifyIngredientsWithImageBase64:(NSString *)imageBase64 success:(SuccessBlock)success failure:(FailureBlock)failure;

#pragma mark - Dish

- (void)fetchDishes:(NSString *)familyId success:(SuccessBlock)success failure:(FailureBlock)failure;

- (void)createDish:(NSDictionary *)params familyId:(NSString *)familyId success:(SuccessBlock)success failure:(FailureBlock)failure;

- (void)makeCookDecision:(NSString *)familyId dishIds:(NSArray *)dishIds success:(SuccessBlock)success failure:(FailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
