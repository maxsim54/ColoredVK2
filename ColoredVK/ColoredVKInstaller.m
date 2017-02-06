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
#import "NSData+AES.h"
#import "NSData+AESCrypt.h"
#import "NSDate+DateTools.h"


@interface ColoredVKInstaller()
@property (strong, nonatomic) UIAlertController *alertController;
@property (strong, nonatomic) UIAlertAction *loginAction;
@property (strong, nonatomic) UIAlertAction *cancelAction;
@property (strong, nonatomic) UIAlertAction *continueAction;
@property (strong, nonatomic) NSString *login;
@property (strong, nonatomic) NSString *password;
@property (copy, nonatomic) NSString *udid;
@end

@implementation ColoredVKInstaller

void(^installerCompletionBlock)(BOOL disableTweak);

+ (instancetype)startInstall
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
        self.cancelAction = [UIAlertAction actionWithTitle:CVKLocalizedString(@"CLOSE_APP") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [UIApplication.sharedApplication performSelector:@selector(suspend)];
            [NSThread sleepForTimeInterval:0.5];
            exit(0);
        }];
        self.udid = [NSString stringWithFormat:@"%@", MGCopyAnswer(CFSTR("UniqueDeviceID"))];
        
        void (^downloadBlock)() = ^{
            if (installerCompletionBlock) installerCompletionBlock(YES);
            [self beginDownload];
        };
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:kDRMLicencePath]) downloadBlock();
        else {            
            NSData *decryptedData = [[NSData dataWithContentsOfFile:kDRMLicencePath] AES128DecryptedDataWithKey:kDRMLicenceKeyOld];
            NSDictionary *dict = (NSDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
            if ([dict isKindOfClass:[NSDictionary class]] && (dict.allKeys.count>0)) downloadBlock();
            else {
                NSData *decryptedData = [[NSData dataWithContentsOfFile:kDRMLicencePath] AES128DecryptedDataWithKey:kDRMLicenceKey];
                NSDictionary *dict = (NSDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
                if ([dict isKindOfClass:[NSDictionary class]] && (dict.allKeys.count>0)) {
                    if (self.udid.length > 6) {
                        if (![dict[@"UDID"] isEqualToString:self.udid]) {
                            downloadBlock();
                        } else if (installerCompletionBlock) installerCompletionBlock(NO);
                    } else if (installerCompletionBlock) installerCompletionBlock(NO);
                } else downloadBlock();
            }
        }
    }
    return self;
}

- (void)showAlertWithText:(NSString *)text
{
    self.alertController = [UIAlertController alertControllerWithTitle:kDRMPackageName message:text preferredStyle:UIAlertControllerStyleAlert];
    [self.alertController addAction:self.cancelAction];
    [self.alertController addAction:[UIAlertAction actionWithTitle:UIKitLocalizedString(@"Login") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performSelectorOnMainThread:@selector(actionLogin) withObject:nil waitUntilDone:NO];
    }]];
    if ([self.alertController respondsToSelector:@selector(setPreferredAction:)]) self.alertController.preferredAction = self.cancelAction;
    [self presentViewController:self.alertController];
}

- (void)presentViewController:(UIViewController *)viewController
{
    [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:viewController animated:YES completion:nil]; 
}


- (void)beginDownload
{
    BOOL isJailed = YES;
#ifndef COMPILE_FOR_JAIL
    isJailed = NO;
#endif
    if ((self.udid.length <= 6) && isJailed) {
        self.alertController = [UIAlertController alertControllerWithTitle:kDRMPackageName message:CVKLocalizedString(@"GETTING_UDID_ERROR") preferredStyle:UIAlertControllerStyleAlert];
        __weak typeof(self) weakSelf = self;
        [self.alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"UDID";
            textField.tag = 9;
            [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(textFieldChanged:) name:UITextFieldTextDidChangeNotification object:textField];
        }];
        [self.alertController addAction:self.cancelAction];
        [self.alertController addAction:[UIAlertAction actionWithTitle:UIKitLocalizedString(@"Login") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self performSelectorOnMainThread:@selector(actionLogin) withObject:nil waitUntilDone:NO];
        }]];
        self.continueAction = [UIAlertAction actionWithTitle:CVKLocalizedString(@"CONTINUE") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self beginDownload];
        }];
        [self.alertController addAction:self.continueAction];
        if ([self.alertController respondsToSelector:@selector(setPreferredAction:)]) self.alertController.preferredAction = self.cancelAction;
        
        [self presentViewController:self.alertController];
        
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
    
    NSString *package = [[@"org.thebigboss.coloredvk2" dataUsingEncoding:NSUTF8StringEncoding] AES256EncryptWithKey:kDRMAuthorizeKey].base64Encoding;
    NSString *udid = [[self.udid dataUsingEncoding:NSUTF8StringEncoding] AES256EncryptWithKey:kDRMAuthorizeKey].base64Encoding;
    
    NSString *parameters = [NSString stringWithFormat:@"udid=%@&package=%@&version=%@", udid, package,kDRMPackageVersion];
    request.HTTPBody = [parameters dataUsingEncoding:NSUTF8StringEncoding];
    [self downloadLicenceWithRequest:request saveLogin:NO];
}

- (void)actionLogin
{
    self.alertController = [UIAlertController alertControllerWithTitle:kDRMPackageName message:UIKitLocalizedString(@"Login") preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [self.alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = UIKitLocalizedString(@"Name");
        textField.tag = 10;
        [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(textFieldChanged:) name:UITextFieldTextDidChangeNotification object:textField];
        
        if (weakSelf.login) textField.text = weakSelf.login;
    }];
    [self.alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = UIKitLocalizedString(@"Password");
        textField.tag = 11;
        textField.secureTextEntry = YES;
        [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(textFieldChanged:) name:UITextFieldTextDidChangeNotification object:textField];
    }];     
    
    
    self.cancelAction = [UIAlertAction actionWithTitle:UIKitLocalizedString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self performSelectorOnMainThread:@selector(beginDownload) withObject:nil waitUntilDone:NO];
    }];
    [self.alertController addAction:self.cancelAction];
    
    self.loginAction = [UIAlertAction actionWithTitle:UIKitLocalizedString(@"Login") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kDRMRemoteServerURL]];
        request.HTTPMethod = @"POST";
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
        self.password = [[self.password dataUsingEncoding:NSUTF8StringEncoding] AES256EncryptWithKey:kDRMAuthorizeKey].base64Encoding;
        NSString *device = [NSString stringWithFormat:@"%@(%@)", [UIDevice currentDevice].name, [UIDevice currentDevice].systemVersion];
        NSString *parameters = [NSString stringWithFormat:@"login=%@&password=%@&action=login&version=%@&device=%@", self.login, self.password, kDRMPackageVersion, device];
        request.HTTPBody = [parameters dataUsingEncoding:NSUTF8StringEncoding];
        [self downloadLicenceWithRequest:request saveLogin:YES];
    }];
    self.loginAction.enabled = NO;
    [self.alertController addAction:self.loginAction];
    [self presentViewController:self.alertController];
}

- (void)downloadLicenceWithRequest:(NSURLRequest *)request saveLogin:(BOOL)saveLogin
{
    void (^showAlertBlock)(NSString *error) = ^(NSString *error) {
        if (saveLogin) [self showAlertWithText:[NSString stringWithFormat:CVKLocalizedString(@"ERROR_LOGIN"), error, self.login]];
        else            self.alertController.message = [NSString stringWithFormat:CVKLocalizedString(@"ERROR_DOWNLOADING_LICENCE"), error, self.udid];
    };
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (!connectionError) {
            NSData *decrypted = [data AES256DecryptWithKey:kDRMAuthorizeKey];
            NSString *decryptedString = [[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding];
            decryptedString = [decryptedString stringByReplacingOccurrencesOfString:@"\0" withString:@""];
            
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:[decryptedString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            if (responseDict && !responseDict[@"error"]) {               
                if ([responseDict[@"Status"] isEqualToString:saveLogin?self.password:self.udid]) {
                    NSError *writingError = nil;
                    NSMutableDictionary *dict = @{@"UDID":self.udid}.mutableCopy;
                    if (saveLogin) [dict setValue:self.login forKey:@"Login"];
                    NSData *encrypterdData = [[NSKeyedArchiver archivedDataWithRootObject:dict.copy] AES128EncryptedDataWithKey:kDRMLicenceKey];
                    [encrypterdData writeToFile:kDRMLicencePath options:NSDataWritingAtomic error:&writingError];
                    
                    if (!writingError) {
                        [UIApplication.sharedApplication performSelector:@selector(suspend)];
                        [NSThread sleepForTimeInterval:0.5];
                        exit(0);
                    }
                    else showAlertBlock([NSString stringWithFormat:@"%@\n%@", CVKLocalizedString(@"ERROR"), writingError.localizedDescription]);
                    
                } else showAlertBlock(@"Unknown error (-1)");
                
            } else showAlertBlock(responseDict?responseDict[@"error"]:@"Unknown error (-2)");
        } else showAlertBlock(connectionError.localizedDescription);
        self.password = nil;
    }];

}

- (void)textFieldChanged:(NSNotification *)notification
{
    if (notification && [notification.object isKindOfClass:UITextField.class]) {
        UITextField *textField = notification.object;
        if (textField.tag == 9) self.udid = textField.text;
        else if (textField.tag == 10) self.login = textField.text;
        else if (textField.tag == 11) self.password = textField.text;
        
        if ((self.login.length > 0) && (self.password.length > 0)) self.loginAction.enabled = YES;
        else self.loginAction.enabled = NO;
        
        if (self.udid.length > 0) self.continueAction.enabled = YES;
        else self.continueAction.enabled = NO;
    }
}
@end