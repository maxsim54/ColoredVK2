//
//  ColoredVKNetwork.m
//  ColoredVK2
//
//  Created by Даниил on 02.08.17.
//
//

#import "ColoredVKNetwork.h"

#if TARGET_OS_IOS
#import <UIKit/UIDevice.h>
#import <UIKit/UIApplication.h>
#import <sys/utsname.h>
#endif

@interface ColoredVKNetwork  () <NSURLSessionDelegate>

@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) dispatch_queue_t parseQueue;

@end

@implementation ColoredVKNetwork
@synthesize defaultUserAgent = _defaultUserAgent;
static NSString *const kColoredVKNetworkErrorDomain = @"ru.danpashin.coloredvk2.network.error";

+ (instancetype)sharedNetwork
{
    static id instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.configuration.timeoutIntervalForResource = 90.0f;
        self.configuration.allowsCellularAccess = YES;
        self.configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        NSOperationQueue *delegateQueue = [[NSOperationQueue alloc] init];
        delegateQueue.name = @"ru.danpashin.coloredvk2.network";
        self.parseQueue = dispatch_queue_create("ru.danpashin.coloredvk2.network.parse-queue", DISPATCH_QUEUE_CONCURRENT);
        
        _session = [NSURLSession sessionWithConfiguration:self.configuration delegate:self delegateQueue:delegateQueue];
    }
    return self;
}

- (void)sendRequest:(NSURLRequest *)request 
            success:(void(^)(NSURLRequest *httpRequest, NSHTTPURLResponse *response, NSData *rawData))success 
            failure:(void(^)(NSURLRequest *httpRequest, NSHTTPURLResponse *response, NSError *error))failure
{
    [self performBackgroundBlock:^{
        NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            [self setStatusBarIndicatorActive:NO];
            dispatch_async(self.parseQueue, ^{
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                
                if (![httpResponse.URL isEqual:request.URL]) {
                    if (failure)
                        failure(request, httpResponse, [self errorWithCode:1002 description:@"Response URL is invalid"]);
                    
                    return;
                }
                
                if (!error && data) {
                    id expectedLengthHeader = httpResponse.allHeaderFields[@"Expected-Length"];
                    NSInteger expectedContentLength = expectedLengthHeader ? [expectedLengthHeader integerValue] : -1;
                    if ((expectedContentLength != -1)) {
                        if ((NSUInteger)expectedContentLength != data.length) {
                            if (failure)
                                failure(request, httpResponse, [self errorWithCode:1004 description:@"Response data has wrong size"]);
                            
                            return;
                        }
                    }
                    
                    if (success)
                        success(request, httpResponse, data);
                } else {
                    if (failure)
                        failure(request, httpResponse, error);
                }
            });
        }];
        [self setStatusBarIndicatorActive:YES];
        [task resume];
    }];
}

- (void)sendRequestWithMethod:(NSString *)method url:(NSString *)url parameters:(id)parameters 
                      success:(void(^)(NSURLRequest *request, NSHTTPURLResponse *response, NSData *rawData))success 
                      failure:(void(^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    [self performBackgroundBlock:^{
        NSError *requestError = nil;
        NSURLRequest *request = [self requestWithMethod:method url:url parameters:parameters error:&requestError];
        if (requestError) {
            failure(request, nil, requestError);
            return;
        }
        [self sendRequest:request success:success failure:failure];
    }];
}

- (void)sendJSONRequestWithMethod:(NSString *)method url:(NSString *)url parameters:(id)parameters
                          success:(void(^)(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *json))success 
                          failure:(void(^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    [self sendRequestWithMethod:method url:url parameters:parameters success:^(NSURLRequest *request, NSHTTPURLResponse *httpResponse, NSData *rawData) {
        
        NSDictionary *headers = httpResponse.allHeaderFields;
        NSString *contentType = headers[@"Content-Type"];
        if (![contentType isKindOfClass:[NSString class]] || ![contentType containsString:@"json"]) {
            if (failure)
                failure(request, httpResponse, [self errorWithCode:1003 description:@"Response has invalid header: 'Content-Type'"]);
            
            return;
        }
        
        NSError *jsonError = nil;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:rawData options:0 error:&jsonError];
        if ([jsonDict isKindOfClass:[NSDictionary class]] && !jsonError) {
            if (success)
                success(request, httpResponse, jsonDict);
        } else {
            if (failure)
                failure(request, httpResponse, jsonError);
        }
    } failure:failure];
}


- (void)uploadData:(NSData *)dataToUpload toRemoteURL:(NSString *)remoteURL 
           success:(void(^)(NSHTTPURLResponse *response, NSData *rawData))success 
           failure:(void(^)(NSHTTPURLResponse *response, NSError *error))failure
{
    if (!dataToUpload)
        return;
    
    dispatch_async(self.parseQueue, ^{
        NSError *requestError = nil;        
        NSMutableURLRequest *request = [self requestWithMethod:@"POST" url:remoteURL parameters:nil error:&requestError];
        if (requestError) {
            if (failure)
                failure(nil, requestError);
        }
        
        NSURLSessionDataTask *task = [self.session uploadTaskWithRequest:request fromData:dataToUpload completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            [self setStatusBarIndicatorActive:NO];
            dispatch_async(self.parseQueue, ^{
                if (!error) {
                    if (success)
                        success((NSHTTPURLResponse *)response, data);
                } else {
                    if (failure)
                        failure((NSHTTPURLResponse *)response, error);
                }
            });
        }];
        [self setStatusBarIndicatorActive:YES];
        [task resume];
    });
}

- (void)downloadDataFromURL:(NSString *)url
                    success:(void(^)(NSHTTPURLResponse *response, NSData *rawData))success 
                    failure:(void(^)(NSHTTPURLResponse *response, NSError *error))failure
{
    [self sendRequestWithMethod:@"GET" url:url parameters:nil success:^(NSURLRequest *request, NSHTTPURLResponse *httpResponse, NSData *rawData) {
        if (success)
            success(httpResponse, rawData);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *httpResponse, NSError *error) {
        if (failure)
            failure(httpResponse, error);
    }];
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method url:(NSString *)url parameters:(id)parameters error:(NSError *__autoreleasing *)error
{
    NSArray *methodsAvailable = @[@"GET", @"POST"];
    if (![methodsAvailable containsObject:method.uppercaseString]) {
        if (error)
            *error = [self errorWithCode:1000 description:@"Method is invalid. Must be 'POST' or 'GET'."];
        return nil;
    }
    
    NSMutableString *stringParameters = [NSMutableString string];
    
    if ([parameters isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictParameters = (NSDictionary *)parameters;
        for (NSString *key in [dictParameters.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]) {
            [stringParameters appendFormat:@"%@=%@&", key, dictParameters[key]];
        }
        
        if ([stringParameters hasSuffix:@"&"])
            [stringParameters replaceCharactersInRange:NSMakeRange(stringParameters.length-1, 1) withString:@""];
    } else if ([parameters isKindOfClass:[NSString class]]) {
        [stringParameters appendString:(NSString *)parameters];
    } else if (parameters) {
        if (error)
            *error = [self errorWithCode:1001 description:@"Parameters class is invalid. Use NSDictionary or NSString."];
        return nil;
    }
    
    if ([method.uppercaseString isEqualToString:@"GET"])
        url = [url stringByAppendingString:[NSString stringWithFormat:@"?%@", stringParameters]];
    
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:self.configuration.requestCachePolicy
                                                       timeoutInterval:self.configuration.timeoutIntervalForResource];
    
    if ([method.uppercaseString isEqualToString:@"POST"]) {
        request.HTTPBody = [stringParameters dataUsingEncoding:NSUTF8StringEncoding];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    }
    
    request.HTTPMethod = method.uppercaseString;
    [request setValue:self.defaultUserAgent forHTTPHeaderField:@"User-Agent"];
    
    return request;
}

- (NSString *)defaultUserAgent
{
    if (!_defaultUserAgent) {
        
#if TARGET_OS_IOS
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *deviceModelName = @(systemInfo.machine);
        NSString *systemVersion = [UIDevice currentDevice].systemVersion;
#elif TARGET_OS_OSX
        NSString *deviceModelName = @"macOS";
        NSString *systemVersion = [NSProcessInfo processInfo].operatingSystemVersionString;
#endif
        
        _defaultUserAgent = [NSString stringWithFormat:@"ColoredVK2/%@ (%@/%@ | %@/%@)", 
                             kPackageVersion, [NSBundle mainBundle].bundleIdentifier, 
                             [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], deviceModelName, 
                             systemVersion];
    }
    
    return _defaultUserAgent;
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    if ([challenge.protectionSpace.host containsString:@"danpashin.ru"] && [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)setStatusBarIndicatorActive:(BOOL)active
{
#if TARGET_OS_IOS
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = active;
    });
#endif
}

- (void)performBackgroundBlock:( void (^__nonnull)(void) )block
{
    const char *currentQueueLabel = dispatch_queue_get_label([NSOperationQueue currentQueue].underlyingQueue);
    const char *customQueueLabel = dispatch_queue_get_label(self.parseQueue);
    if (strcmp(currentQueueLabel, customQueueLabel) == 0) {
        block();
    } else {
        dispatch_async(self.parseQueue, block);
    }
}

- (NSError * __nonnull)errorWithCode:(NSInteger)code description:(NSString * _Nonnull)description
{
    return [NSError errorWithDomain:kColoredVKNetworkErrorDomain code:code 
                           userInfo:@{NSLocalizedDescriptionKey:description}];
}

@end
