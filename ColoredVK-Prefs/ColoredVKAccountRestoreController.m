//
//  ColoredVKAccountRestoreController.m
//  ColoredVK2
//
//  Created by Даниил on 29/01/2018.
//

#import "ColoredVKAccountRestoreController.h"
#import "ColoredVKTextField.h"
#import "ColoredVKNewInstaller.h"
#import "ColoredVKHUD.h"
#import "PrefixHeader.h"
#import "ColoredVKPassResetController.h"

@interface ColoredVKAccountRestoreController () <UITextFieldDelegate, UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *restoreNavButton;
@property (assign, nonatomic) NSUInteger emailsSendCount;
@property (strong, nonatomic) NSDate *codeValidDate;
@property (strong, nonatomic) NSTimer *codeTimer;

@property (strong, nonatomic) IBOutlet UIStackView *resetStackView;
@property (strong, nonatomic) IBOutlet ColoredVKTextField *loginTextField;
@property (strong, nonatomic) IBOutlet ColoredVKTextField *emailTextField;
@property (strong, nonatomic) IBOutlet UILabel *footerLabel;

@property (strong, nonatomic) IBOutlet UIStackView *codeStackView;
@property (strong, nonatomic) IBOutlet UITextView *codeTextView;
@property (strong, nonatomic) IBOutlet UILabel *codeFooterLabel;
@property (strong, nonatomic) IBOutlet UIButton *codeResendButton;

@end

@implementation ColoredVKAccountRestoreController

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    self.loginTextField.text = self.login;
    self.loginTextField.delegate = self;
    self.emailTextField.delegate = self;
    self.codeTextView.delegate = self;
    
    self.navigationItem.title = @"Восстановление доступа";
    self.footerLabel.text = @"Если Вы пользуетесь бесплатной версией аккаунта, пожалуйста, напишите разработчику.";
    self.restoreNavButton.title = @"Далее";
    self.codeResendButton.userInteractionEnabled = NO;
    self.codeResendButton.titleLabel.numberOfLines = 0;
    self.codeFooterLabel.text = @"На Вашу почту было отправлено сообщение с кодом восстановления.";
    
    self.resetStackView.hidden = NO;
    self.codeStackView.hidden = YES;
    self.navigationItem.backBarButtonItem.title = @"";
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.emailsSendCount > 0) {
        [self.codeTextView becomeFirstResponder];
    } else {
        if (self.loginTextField.text.length > 0) {
            [self.emailTextField becomeFirstResponder];
        } else {
            [self.loginTextField becomeFirstResponder];
        }
    }
}

- (BOOL)controllerShouldPop
{
    [self.loginTextField endEditing:NO];
    [self.emailTextField endEditing:NO];
    [self.codeTextView endEditing:YES];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController popToRootViewControllerAnimated:YES];
    });
    
    return NO;
}


- (void)setCodeValidDate:(NSDate *)codeValidDate
{
    _codeValidDate = codeValidDate;
    
    if (self.codeTimer) {
        [self.codeTimer invalidate];
        self.codeTimer = nil;
    }
    
    self.codeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateCodeFooter:) userInfo:nil repeats:YES];
    [self.codeTimer fire];
}

- (void)updateCodeFooter:(NSTimer *)timer
{
    if (self.codeValidDate.timeIntervalSinceNow <= 0) {
        [timer invalidate];
        self.codeTimer = nil;
        self.codeResendButton.userInteractionEnabled = YES;
        [self.codeResendButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [self.codeResendButton setTitleColor:[UIColor blueColor] forState:UIControlStateFocused];
        [self.codeResendButton setTitleColor:[UIColor blueColor] forState:UIControlStateSelected];
        [self.codeResendButton setTitle:@"Отправить код заново" forState:UIControlStateNormal];
        return;
    }
    NSString *resendButtonTitle = [NSString stringWithFormat:@"До окончания действия пароля осталось %i секунд.", (int)self.codeValidDate.timeIntervalSinceNow];
    [self.codeResendButton setTitle:resendButtonTitle forState:UIControlStateNormal];
}


#pragma mark -
#pragma mark UITextFieldDelegate
#pragma mark -

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@" "]) {
        if ([textField isKindOfClass:[ColoredVKTextField class]]) {
            [(ColoredVKTextField *)textField shake];
        }
        return NO;
    }
    
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if ([textField isEqual:self.emailTextField]) {
        NSString *expression = @"([\\w\\.\\-_]+)?\\w+@[\\w-_]+(\\.\\w+){1,}";
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", expression];
        
        ((ColoredVKTextField *)textField).error = ![predicate evaluateWithObject:newString];
        return YES;
    }
    
    if ([textField isKindOfClass:[ColoredVKTextField class]]) {
        ((ColoredVKTextField *)textField).error = (newString.length == 0);
    }    
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([textField isEqual:self.loginTextField]) {
        [self.loginTextField endEditing:YES];
        [self.emailTextField becomeFirstResponder];
    }
    
    if ([textField isEqual:self.emailTextField]) {
        [self actionRestore:nil];
    }
    
    return YES;
}


#pragma mark -
#pragma mark UITextViewDelegate
#pragma mark -

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([textView isEqual:self.codeTextView]) {
        if ([text rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet].invertedSet].location != NSNotFound)
            return NO;
        
        BOOL shouldRemove = (text.length == 0);
        NSString *pattern = shouldRemove ? @"([0-9])" : @"([-])";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        NSArray <NSTextCheckingResult *> *allResults = [regex matchesInString:textView.text options:0 range:NSMakeRange(0, textView.text.length)];
        if (allResults.count > 0) {
            NSRange changeRange = shouldRemove ? allResults.lastObject.range : allResults.firstObject.range;
            NSString *changeString = shouldRemove ? @"-" : text;
            textView.text = [textView.text stringByReplacingCharactersInRange:changeRange withString:changeString];
        }
        if (allResults.count == 1 && !shouldRemove)
            [self actionCheckCode];
        
        return NO;
    }
    
    return YES;
}


#pragma mark -
#pragma mark Actions
#pragma mark -

- (IBAction)actionRestore:(UIBarButtonItem *)sender
{    
    if (self.emailsSendCount > 0)
        return;
    
    if (self.loginTextField.error || self.loginTextField.text.length == 0) {
        [self.loginTextField shake];
        return;
    }
    
    if (self.emailTextField.error || self.emailTextField.text.length == 0) {
        [self.emailTextField shake];
        return;
    }
    
    NSDictionary *params = @{@"login":self.loginTextField.text, @"email":self.emailTextField.text};
    [self sendRequestWithName:@"reset.php" params:params successBlock:^(NSDictionary *response) {
        self.emailsSendCount++;
        self.codeValidDate = [NSDate dateWithTimeIntervalSince1970:[response[@"valid_until"] doubleValue]];
        self.login = response[@"message"];
        self.navigationItem.rightBarButtonItem = nil;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.loginTextField endEditing:NO];
            [self.emailTextField endEditing:NO];
            
            self.codeTextView.tintColor = [[UIColor redColor] colorWithAlphaComponent:0.0f];
            self.codeTextView.editable = YES;
            self.codeTextView.autocorrectionType = UITextAutocorrectionTypeNo;
            [self.codeTextView becomeFirstResponder];
        });
        
        __block CGRect codeStackViewFrame = self.codeStackView.frame;
        codeStackViewFrame.origin.x = CGRectGetWidth(self.view.frame) + 8.0f;
        self.codeStackView.frame = codeStackViewFrame;
        self.codeStackView.hidden = NO;
        
        __block CGRect resetStackViewFrame = self.resetStackView.frame;
        resetStackViewFrame.origin.x = 20.0f;
        self.resetStackView.hidden = NO;
        self.resetStackView.frame = resetStackViewFrame;
        
        [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionAllowUserInteraction 
                         animations:^{                             
                             codeStackViewFrame.origin.x = 20.0f;
                             self.codeStackView.frame = codeStackViewFrame;
                             
                             resetStackViewFrame.origin.x = -resetStackViewFrame.size.width - 8.0f;
                             self.resetStackView.frame = resetStackViewFrame;
                         } completion:^(BOOL finished) {
                             self.resetStackView.hidden = YES;
                         }];
    }];
}

- (IBAction)actionResendCode
{
    [self.codeResendButton setTitleColor:self.footerLabel.textColor forState:UIControlStateNormal];
    
    NSDictionary *params = @{@"login":self.loginTextField.text, @"email":self.emailTextField.text};
    [self sendRequestWithName:@"reset.php" params:params successBlock:^(NSDictionary *response) {
        self.emailsSendCount++;
        self.codeValidDate = [NSDate dateWithTimeIntervalSince1970:[response[@"valid_until"] doubleValue]];
        self.login = response[@"message"];
    }];
}

- (void)actionCheckCode
{    
    NSString *code = [self.codeTextView.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSDictionary *params = @{@"code":code, @"login":self.login};
    [self sendRequestWithName:@"check.php" params:params successBlock:^(NSDictionary *response) {        
        ColoredVKPassResetController *passController = [self.storyboard instantiateViewControllerWithIdentifier:@"passResetController"];
        passController.token = response[@"token"];
        passController.email = self.emailTextField.text;
        passController.login = self.login;
        
        [self.codeTextView endEditing:NO];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController pushViewController:passController animated:YES];
            
            NSMutableArray *allViewControllers = [self.navigationController.viewControllers mutableCopy];
            [allViewControllers removeObjectIdenticalTo:self];
            
            [self.codeTimer invalidate];
            self.codeTimer = nil;
            
            self.navigationController.viewControllers = allViewControllers;
        });
    }];
}

- (void)sendRequestWithName:(NSString *)scriptName params:(NSDictionary *)params successBlock:( void(^)(NSDictionary *response) )successBlock
{
//    if (successBlock)
//        dispatch_async(dispatch_get_main_queue(), ^{
//            successBlock(@{@"token":@"come_ctm_token", @"valid_until":@([NSDate date].timeIntervalSince1970 + 10), @"message":self.loginTextField.text});
//        });
//    
//    return;
    
    ColoredVKHUD *hud = [ColoredVKHUD showHUDForView:self.view];
    
    void (^intSuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *json) = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *json) {
        if (json[@"response"]) {
            NSDictionary *response = json[@"response"];
            NSInteger status = [response[@"status"] integerValue];
            if (status == 1) {   
                [hud hide];
                if (successBlock)
                    dispatch_async(dispatch_get_main_queue(), ^{
                        successBlock(response);
                    });
                
            } else {
                [hud showFailureWithStatus:[NSString stringWithFormat:@"При выполнении произошла внутренняя ошибка\n(%li)", (long)status]];
            }
        } else if (json[@"error"]) {
            NSDictionary *errorDict = json[@"error"];
            [hud showFailureWithStatus:[NSString stringWithFormat:@"%@\n(%@)", errorDict[@"message"], errorDict[@"code"]]];
        } else {
            NSLog(@"%@", json);
            [hud showFailureWithStatus:@"Internal error. See console."];
        }
    };
    
    NSString *url = [NSString stringWithFormat:@"%@/pass/%@", kPackageAPIURL, scriptName];
    [[ColoredVKNewInstaller sharedInstaller].networkController sendJSONRequestWithMethod:@"POST" stringURL:url parameters:params success:intSuccessBlock
                                                                                 failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                                                     [hud showFailureWithStatus:error.localizedDescription];
                                                                                 }];
}

@end