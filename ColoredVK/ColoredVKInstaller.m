//
//  ColoredVKInstaller.m
//  ColoredVK
//
//  Created by Даниил on 11/09/16.
//
//

#import "ColoredVKInstaller.h"

#import <MobileGestalt/MobileGestalt.h>
#import "PrefixHeader.h"
#import "NSData+AESCrypt.h"
#import "NSDate+DateTools.h"
#import <CommonCrypto/CommonCryptor.h>
#import <sys/utsname.h>


NSData *AES256Decrypt(NSData *data, NSString *key)
{
        // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
    bzero( keyPtr, sizeof( keyPtr ) ); // fill with zeroes (for padding)
    
        // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = data.length;
    
        //See the doc: For block ciphers, the output size will always be less than or 
        //equal to the input size plus the size of one block.
        //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc( bufferSize );
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          data.bytes, dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesDecrypted);
    
    if (cryptStatus == kCCSuccess) {
            //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    
    free(buffer); //free the buffer
    return nil;
}

NSData *AES256Encrypt(NSData *data, NSString *key)
{
        // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256 + 1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
        // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = data.length;
    
        //See the doc: For block ciphers, the output size will always be less than or 
        //equal to the input size plus the size of one block.
        //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          data.bytes, dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
            //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer); //free the buffer
    return nil;
}

NSData *AES256EncryptString(NSString *string, NSString *key)
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return AES256Encrypt(data, key);
}


@interface ColoredVKInstaller()
@end

@implementation ColoredVKInstaller

void(^installerCompletionBlock)(BOOL disableTweak);
UIAlertController *alertController;
UIAlertAction *loginAction;
UIAlertAction *continueAction;
NSString *login;
NSString *password;
NSString *udid;
NSString *key;
struct utsname systemInfo;


+ (instancetype)sharedInstaller
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            udid = [NSString stringWithFormat:@"%@", CFBridgingRelease(MGCopyAnswer(CFSTR("UniqueDeviceID")))];
            key = AES256EncryptString([NSProcessInfo processInfo].globallyUniqueString, kDRMAuthorizeKey).base64Encoding;
            uname(&systemInfo);
            
            void (^downloadBlock)() = ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (installerCompletionBlock) installerCompletionBlock(YES);
                    [self beginDownload];
                });
            };
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:kDRMLicencePath]) downloadBlock();
            else {
                NSData *decryptedData = AES256Decrypt([NSData dataWithContentsOfFile:kDRMLicencePath], kDRMLicenceKey);
                NSMutableDictionary *dict = [(NSDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:decryptedData] mutableCopy];
                if ([dict isKindOfClass:[NSDictionary class]] && (dict.allKeys.count>0)) {
//                    if (dict[@"key"]) { 
//                        [dict removeObjectForKey:@"key"];
//                        NSData *encrypterdData = AES256Encrypt([NSKeyedArchiver archivedDataWithRootObject:dict], kDRMLicenceKey);
//                        [encrypterdData writeToFile:kDRMLicencePath options:NSDataWritingAtomic error:nil];
//                    }
                    
                    if (!dict[@"Device"]) downloadBlock();
                    else {                        
                        if (![dict[@"Device"] isEqualToString:@(systemInfo.machine)]) downloadBlock();
                        else {
                            if (udid.length > 6) {
                                if (![dict[@"UDID"] isEqualToString:udid]) downloadBlock();
                                else if (installerCompletionBlock) installerCompletionBlock(NO);
                            } else if (installerCompletionBlock) installerCompletionBlock(NO);
                        }
                    }
                } else downloadBlock();
            }
            
            [self setupFiles];
            [self sendStats];
        });
        
    }
    return self;
}

- (void)setupFiles
{
    NSFileManager *fileManager = [NSFileManager defaultManager]; 
#ifdef COMPILE_FOR_JAIL
    if ([fileManager fileExistsAtPath:CVK_CACHE_PATH_OLD]) [fileManager removeItemAtPath:CVK_CACHE_PATH_OLD error:nil];
#endif
    if (![fileManager fileExistsAtPath:CVK_FOLDER_PATH])  [fileManager createDirectoryAtPath:CVK_FOLDER_PATH withIntermediateDirectories:NO attributes:nil error:nil];
    if (![fileManager fileExistsAtPath:CVK_CACHE_PATH])   [fileManager createDirectoryAtPath:CVK_CACHE_PATH  withIntermediateDirectories:NO attributes:nil error:nil];
    if (![fileManager fileExistsAtPath:CVK_BACKUP_PATH])  [fileManager createDirectoryAtPath:CVK_BACKUP_PATH withIntermediateDirectories:NO attributes:nil error:nil];
}


- (void)sendStats
{
    if ([[NSBundle mainBundle].executablePath.lastPathComponent containsString:@"vkclient"]) {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:CVK_PREFS_PATH];
        BOOL sendStatistics = prefs[@"sendStatistics"]?[prefs[@"sendStatistics"] boolValue]:YES;
        if (sendStatistics) {
            UIDevice *device = [UIDevice currentDevice];
            NSString *stringURL = [NSString stringWithFormat:@"http://danpashin.ru/api/v%@/stats/?product=%@&version=%@&device=%@&ios_version=%@&device_language=%@&vk_version=%@&identifier=%@", 
                                   API_VERSION, kDRMPackage, kDRMPackageVersion, @(systemInfo.machine), 
                                   device.systemVersion, [NSLocale preferredLanguages].firstObject, prefs[@"vkVersion"], device.identifierForVendor.UUIDString];
            
            [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:stringURL]] 
                                               queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {}];
        }
    }
}


- (void)showAlertWithText:(NSString *)text
{
    alertController = [UIAlertController alertControllerWithTitle:kDRMPackageName message:text preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:UIKitLocalizedString(@"Login") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performSelectorOnMainThread:@selector(actionLogin) withObject:nil waitUntilDone:NO];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:CVKLocalizedString(@"CLOSE_APP") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [UIApplication.sharedApplication performSelector:@selector(suspend)];
        [NSThread sleepForTimeInterval:0.5];
        exit(0);
    }]];
    [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
}


- (void)beginDownload
{
    BOOL isJailed = NO;
#ifdef COMPILE_FOR_JAIL
    isJailed = YES;
#endif
    if ((udid.length <= 6) && isJailed) {
        alertController = [UIAlertController alertControllerWithTitle:kDRMPackageName message:CVKLocalizedString(@"GETTING_PRIVATE_INFO_ERROR") preferredStyle:UIAlertControllerStyleAlert];
        
        if ([[NSBundle mainBundle].executablePath.lastPathComponent containsString:@"vkclient"]) {
            [alertController addAction:[UIAlertAction actionWithTitle:CVKLocalizedString(@"OPEN_PREFERENCES") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:"]];
                [self showAlertWithText:@"Downloading licence..."];
            }]];
        } else {
            alertController.message = CVKLocalizedString(@"GETTING_UDID_ERROR");
            [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"UDID";
            }];
            [alertController addAction:[UIAlertAction actionWithTitle:CVKLocalizedString(@"CLOSE_APP") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [UIApplication.sharedApplication performSelector:@selector(suspend)];
                [NSThread sleepForTimeInterval:0.5];
                exit(0);
            }]];            
            [alertController addAction:[UIAlertAction actionWithTitle:UIKitLocalizedString(@"Login") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self performSelectorOnMainThread:@selector(actionLogin) withObject:nil waitUntilDone:NO];
            }]];
            continueAction = [UIAlertAction actionWithTitle:CVKLocalizedString(@"CONTINUE") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                udid = alertController.textFields[0].text;
                [self beginDownload];
            }];
            [alertController addAction:continueAction];
        }
        
        [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
        
        return;
    } else if (!isJailed) {
        [self actionLogin];
        return;
    } else {
        [self showAlertWithText:@"Downloading licence..."];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kDRMRemoteServerURL]];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    
    NSString *package = AES256EncryptString(@"org.thebigboss.coloredvk2", kDRMAuthorizeKey).base64Encoding;
    NSString *encryptedUDID = AES256EncryptString(udid, kDRMAuthorizeKey).base64Encoding;
    
    NSString *parameters = [NSString stringWithFormat:@"udid=%@&package=%@&version=%@&key=%@", encryptedUDID, package, kDRMPackageVersion, key];
    request.HTTPBody = [parameters dataUsingEncoding:NSUTF8StringEncoding];
    download(request, NO);
}

- (void)actionLogin
{
    alertController = [UIAlertController alertControllerWithTitle:kDRMPackageName message:UIKitLocalizedString(@"Login") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = UIKitLocalizedString(@"Name");
        if (login) textField.text = login;
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = UIKitLocalizedString(@"Password");
        textField.secureTextEntry = YES;
    }];
    
    [alertController addAction:[UIAlertAction actionWithTitle:CVKLocalizedString(@"CLOSE_APP") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [UIApplication.sharedApplication performSelector:@selector(suspend)];
        [NSThread sleepForTimeInterval:0.5];
        exit(0);
    }]];
    
    loginAction = [UIAlertAction actionWithTitle:UIKitLocalizedString(@"Login") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        login = alertController.textFields[0].text;
        password = alertController.textFields[1].text;
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kDRMRemoteServerURL]];
        request.HTTPMethod = @"POST";
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
        password = AES256EncryptString(password, kDRMAuthorizeKey).base64Encoding;
        NSString *device = [NSString stringWithFormat:@"%@ (%@)(%@)", @(systemInfo.machine), [UIDevice currentDevice].name, [UIDevice currentDevice].systemVersion];
        NSString *parameters = [NSString stringWithFormat:@"login=%@&password=%@&action=login&version=%@&device=%@&key=%@", login, password, kDRMPackageVersion, device, key];
        request.HTTPBody = [parameters dataUsingEncoding:NSUTF8StringEncoding];
        download(request, YES);
    }];
    [alertController addAction:loginAction];
    [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
}

static void download(NSURLRequest *request,BOOL authorise)
{
    void (^showAlertBlock)(NSError *error) = ^(NSError *error) {
        NSString *text = [NSString stringWithFormat:CVKLocalizedString(@"ERROR_DOWNLOADING_LICENCE"), error.localizedDescription];
        if (error.localizedRecoverySuggestion.length > 6) text = [NSString stringWithFormat:@"%@\n\n%@", text, error.localizedRecoverySuggestion];
        if (authorise) [[ColoredVKInstaller alloc] showAlertWithText:text];
        else            alertController.message = text;
    };
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (!connectionError) {
            NSData *decrypted = AES256Decrypt(data, kDRMAuthorizeKey);
            NSString *decryptedString = [[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding];
            decryptedString = [decryptedString stringByReplacingOccurrencesOfString:@"\0" withString:@""];
            
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:[decryptedString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            if (responseDict && !responseDict[@"error"]) {
                if ([responseDict[@"Status"] isEqualToString:authorise?password:udid]) {
                    if ([responseDict[@"key"] isEqualToString:key]) {
                        NSString *key = [NSProcessInfo processInfo].globallyUniqueString;
                        NSMutableDictionary *dict = @{@"UDID":udid, @"Device":@(systemInfo.machine), @"key":key}.mutableCopy;
                        if (authorise) [dict setValue:login forKey:@"Login"];
                        NSData *encrypterdData = AES256Encrypt([NSKeyedArchiver archivedDataWithRootObject:dict], kDRMLicenceKey);
                        
                        NSError *writingError = nil;
                        [encrypterdData writeToFile:kDRMLicencePath options:NSDataWritingAtomic error:&writingError];
                        
                        if (!writingError) {
                            [alertController dismissViewControllerAnimated:YES completion:nil];
                            if (installerCompletionBlock) installerCompletionBlock(NO);
                            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.daniilpashin.coloredvk2.reload.menu"), NULL, NULL, YES);
                        }
                        else showAlertBlock(writingError);
                        
                    } else showAlertBlock([NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Unknown error (-0)"}]);
                } else showAlertBlock([NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Unknown error (-1)"}]);
                
            } else {
                NSString *errorMessages = responseDict?responseDict[@"error"]:@"Unknown error (-2)";
                showAlertBlock([NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedDescriptionKey:errorMessages}]);
            }
        } else showAlertBlock(connectionError);
        password = nil;
    }]; 

}


BOOL licenceContainsKey(NSString *key)
{
    NSData *decryptedData = AES256Decrypt([NSData dataWithContentsOfFile:kDRMLicencePath], kDRMLicenceKey);
    NSMutableDictionary *dict = [(NSDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:decryptedData] mutableCopy];
    if ([dict isKindOfClass:[NSDictionary class]] && (dict.allKeys.count>0))
        return [dict.allKeys containsObject:key];
    else
        return NO;
}

id licenceValueForKey(NSString *key)
{
    NSData *decryptedData = AES256Decrypt([NSData dataWithContentsOfFile:kDRMLicencePath], kDRMLicenceKey);
    NSMutableDictionary *dict = [(NSDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:decryptedData] mutableCopy];
    if ([dict isKindOfClass:[NSDictionary class]] && (dict.allKeys.count>0))
        return dict[key];
    else
        return nil;
}

@end
