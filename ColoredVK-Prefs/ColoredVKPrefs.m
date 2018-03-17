//
//  ColoredVKPrefs.m
//  ColoredVK
//
//  Created by Даниил on 23.04.16.
//  Copyright (c) 2016 Daniil Pashin. All rights reserved.
//

#import "ColoredVKPrefs.h"
#import "ColoredVKAlertController.h"
#import "ColoredVKNewInstaller.h"
#import "UITableViewCell+ColoredVK.h"
#import <objc/runtime.h>

@implementation ColoredVKPrefs

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

- (void)commonInit
{
    _cvkBundle = [NSBundle bundleWithPath:CVK_BUNDLE_PATH];
    
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:CVK_PREFS_PATH];
    _vkAppVersion = prefs[@"vkVersion"] ? prefs[@"vkVersion"] : CVKLocalizedString(@"UNKNOWN");
    
    NSInteger themeType = [prefs[@"nightThemeType"] integerValue];
    self.nightThemeColorScheme = [ColoredVKNightThemeColorScheme sharedScheme];
    [self.nightThemeColorScheme updateForType:themeType];
    self.nightThemeColorScheme.enabled = ((themeType != -1) && [prefs[@"enabled"] boolValue]);
}

- (void)loadView
{
    [super loadView];
    
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[UITableView class]]) {
            self.prefsTableView = (UITableView *)view;
            self.prefsTableView.separatorColor = [UIColor clearColor];
            break;
        }
    }
    
    self.prefsTableView.emptyDataSetSource = self;
    self.prefsTableView.emptyDataSetDelegate = self;
    
    if ([ColoredVKNewInstaller sharedInstaller].application.isVKApp && self.nightThemeColorScheme.enabled) {
        self.prefsTableView.backgroundColor = self.nightThemeColorScheme.backgroundColor;
        self.navigationController.navigationBar.barTintColor = self.nightThemeColorScheme.navbackgroundColor;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = self.specifier ? self.specifier.name : @"";
}

#pragma mark -
#pragma mark Actions
#pragma mark -

- (void)reloadSpecifiers
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [super reloadSpecifiers];
    });
}

- (void)updateNightTheme
{
    if (![ColoredVKNewInstaller sharedInstaller].application.isVKApp)
        return;
    
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:CVK_PREFS_PATH];
    NSInteger themeType = [prefs[@"nightThemeType"] integerValue];
    [self.nightThemeColorScheme updateForType:themeType];
    self.nightThemeColorScheme.enabled = ((themeType != -1) && [prefs[@"enabled"] boolValue]);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.prefsTableView.separatorColor = [UIColor clearColor];
            self.prefsTableView.backgroundColor = [UIColor colorWithRed:0.937255f green:0.937255f blue:0.956863f alpha:1.0f];
            self.navigationController.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
        } completion:nil];
        
        
        for (PSSpecifier *specifier in self.specifiers) {
            PSTableCell *cell = [self cachedCellForSpecifier:specifier];
            [self updateNightThemeForCell:cell animated:YES];
        }
    });
}

- (void)updateNightThemeForCell:(UITableViewCell *)cell animated:(BOOL)animated
{
    if (![ColoredVKNewInstaller sharedInstaller].application.isVKApp)
        return;
    
    BOOL nightThemeEnabled = self.nightThemeColorScheme.enabled;
    ColoredVKCellBackgroundView *backgroundView = cell.customBackgroundView;
    
    void (^changeBlock)(void) = ^{
        backgroundView.backgroundColor = nightThemeEnabled ? self.nightThemeColorScheme.foregroundColor : nil;
        backgroundView.separatorColor = nightThemeEnabled ? self.nightThemeColorScheme.backgroundColor : nil;
        backgroundView.selectedBackgroundColor = nightThemeEnabled ? self.nightThemeColorScheme.backgroundColor : nil;
        cell.textLabel.textColor = nightThemeEnabled ? self.nightThemeColorScheme.textColor : [UIColor blackColor];  
        
        if (self.nightThemeColorScheme.enabled) {     
            if ([cell.accessoryView isKindOfClass:NSClassFromString(@"ColoredVKStepperButton")]) {
                ((UILabel *)[cell.accessoryView valueForKey:@"valueLabel"]).textColor = self.nightThemeColorScheme.textColor;
            }
        }
    };
    
    if (animated)
        [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionAllowUserInteraction animations:changeBlock completion:nil];
    else
        changeBlock();
}

- (void)presentPopover:(UIViewController *)controller
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (IS_IPAD) {
            controller.modalPresentationStyle = UIModalPresentationPopover;
            controller.popoverPresentationController.permittedArrowDirections = 0;
            controller.popoverPresentationController.sourceView = self.view;
            controller.popoverPresentationController.sourceRect = self.view.bounds;
        }
        [self presentViewController:controller animated:YES completion:nil];
    });
}

- (void)showPurchaseAlert
{
    ColoredVKAlertController *alertController = [ColoredVKAlertController alertControllerWithTitle:kPackageName message:CVKLocalizedString(@"AVAILABLE_IN_FULL_VERSION")
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:CVKLocalizedString(@"THINK_LATER") style:UIAlertActionStyleCancel 
                                                      handler:^(UIAlertAction *action) {}]];
    [alertController addAction:[UIAlertAction actionWithTitle:CVKLocalizedString(@"OF_COURSE") style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          [[ColoredVKNewInstaller sharedInstaller] actionPurchase];
                                                      }]];
    [alertController presentFromController:self];
}


#pragma mark -
#pragma mark Getters
#pragma mark -

- (UIStatusBarStyle)preferredStatusBarStyle
{    
    BOOL vkApp = [ColoredVKNewInstaller sharedInstaller].application.isVKApp;
    return vkApp ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (NSArray *)specifiers
{
    if (!_specifiers) {
        NSString *plistName = [@"plists/" stringByAppendingString:self.specifier.properties[@"plistToLoad"]];
        _specifiers = [self specifiersForPlistName:plistName localize:YES];
    }
    return _specifiers;
}

- (NSArray <PSSpecifier*> *)specifiersForPlistName:(NSString *)plistName localize:(BOOL)localize 
{
    NSMutableArray *specifiersArray = [NSMutableArray new];
    if ([self respondsToSelector:@selector(setBundle:)] && [self respondsToSelector:@selector(loadSpecifiersFromPlistName:target:)]) {
        self.bundle = self.cvkBundle;
        specifiersArray = [[self loadSpecifiersFromPlistName:plistName target:self] mutableCopy];
    } else if ([self respondsToSelector:@selector(loadSpecifiersFromPlistName:target:bundle:)]) {
        specifiersArray = [[self loadSpecifiersFromPlistName:plistName target:self bundle:self.cvkBundle] mutableCopy];
    } 
    else if ([self respondsToSelector:@selector(loadSpecifiersFromPlistName:target:)]) {
        specifiersArray = [[self loadSpecifiersFromPlistName:plistName target:self] mutableCopy];
    }
    
    @autoreleasepool {
        if (localize) {
            NSString *path = [self.cvkBundle pathForResource:@"ColoredVK" ofType:@"strings"];
            __block NSDictionary *localizable = [NSDictionary dictionaryWithContentsOfFile:path];
            NSString *(^localizedStringForKey)(NSString *key) = ^NSString *(NSString *key) {
                if (!key)
                    return @"";
                
                return localizable[key] ? localizable[key] : key;
            };
            
            for (PSSpecifier *specifier in specifiersArray) {
                specifier.name = localizedStringForKey(specifier.name);
                
                if (specifier.properties[@"footerText"]) {
                    if ([specifier.properties[@"footerText"] isEqualToString:@"AVAILABLE_IN_%@_AND_HIGHER"]) {
                        NSString *string = [NSString stringWithFormat:localizedStringForKey(specifier.properties[@"footerText"]), specifier.properties[@"requiredVersion"]];
                        [specifier setProperty:string forKey:@"footerText"];
                    } else
                        [specifier setProperty:localizedStringForKey(specifier.properties[@"footerText"]) forKey:@"footerText"];
                }
                if (specifier.properties[@"label"])
                    [specifier setProperty:localizedStringForKey(specifier.properties[@"label"]) forKey:@"label"];
                if (specifier.properties[@"detailedLabel"])
                    [specifier setProperty:localizedStringForKey(specifier.properties[@"detailedLabel"]) forKey:@"detailedLabel"];
                
                if (specifier.properties[@"validTitles"]) {
                    NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
                    for (NSString *key in specifier.titleDictionary.allKeys) {
                        [tempDict setValue:localizedStringForKey(specifier.titleDictionary[key]) forKey:key];
                    }
                    specifier.titleDictionary = [tempDict copy];
                }
                
                if ([specifier.identifier isEqualToString:@"manageSettingsFooter"] && specifier.properties[@"footerText"])
                    [specifier setProperty:[NSString stringWithFormat:localizedStringForKey(specifier.properties[@"footerText"]), CVK_BACKUP_PATH] forKey:@"footerText"];
            }
        }
    }
    
    if (specifiersArray.count == 0) {
        specifiersArray = [NSMutableArray new];
    }
    
    return [specifiersArray copy];
}

- (id)readPreferenceValue:(PSSpecifier *)specifier
{
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:CVK_PREFS_PATH];
    if (!prefs) {
        prefs = [NSDictionary new];
        [prefs writeToFile:CVK_PREFS_PATH atomically:YES];
    }
    if (!specifier.properties[@"key"])
        return nil;
    
    if (!prefs[specifier.properties[@"key"]])
        return specifier.properties[@"default"];
    
    return prefs[specifier.properties[@"key"]];
}

- (BOOL)openURL:(NSURL *)url
{
    UIApplication *application = [UIApplication sharedApplication];
    
    if ([application canOpenURL:url]) {
        BOOL urlIsOpen = [application openURL:url];
        
        return urlIsOpen;
    }
    
    return NO;
}

- (BOOL)edgeToEdgeCells
{
    return YES;
}


#pragma mark -
#pragma mark Setters
#pragma mark -

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier
{
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:CVK_PREFS_PATH];
    if (value)
        [prefs setValue:value forKey:specifier.properties[@"key"]];
    else
        [prefs removeObjectForKey:specifier.properties[@"key"]];
    
    [prefs writeToFile:CVK_PREFS_PATH atomically:YES];
    
    NSArray *identificsToReloadMenu = @[@"enableTweakSwitch", @"menuSelectionStyle", @"hideMenuSeparators", 
                                        @"changeSwitchColor", @"useMenuParallax", @"changeMenuTextColor", 
                                        @"showMenuCell", @"menuUseBackgroundBlur"];
    
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    
    if ([specifier.identifier isEqualToString:@"nightThemeType"]) {
        [self updateNightTheme];
        CFNotificationCenterPostNotification(center, CFSTR("com.daniilpashin.coloredvk2.reload.menu"), nil, nil, YES);
        CFNotificationCenterPostNotification(center, CFSTR("com.daniilpashin.coloredvk2.night.theme"), nil, nil, YES);
    }
    
    CFNotificationCenterPostNotification(center, CFSTR("com.daniilpashin.coloredvk2.prefs.changed"), nil, nil, YES);
    
    if ([identificsToReloadMenu containsObject:specifier.identifier] && ![specifier.identifier isEqualToString:@"nightThemeType"])
        CFNotificationCenterPostNotification(center, CFSTR("com.daniilpashin.coloredvk2.reload.menu"), nil, nil, YES);
    
    if ([specifier.identifier isEqualToString:@"enableTweakSwitch"]) {
        [self updateNightTheme];
        CFNotificationCenterPostNotification(center, CFSTR("com.daniilpashin.coloredvk2.night.theme"), nil, nil, YES);
        CFNotificationCenterPostNotification(center, CFSTR("com.daniilpashin.coloredvk2.update.corners"), nil, nil, YES);
    }
}


#pragma mark -
#pragma mark UITableViewDelegate
#pragma mark -

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.userInteractionEnabled = YES;
    cell.layoutMargins = UIEdgeInsetsMake(0, 18, 0, 18);
    
    BOOL vkApp = [ColoredVKNewInstaller sharedInstaller].application.isVKApp;
    objc_setAssociatedObject(cell, "app_is_vk", @(vkApp), OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(cell, "nightThemeColorScheme", self.nightThemeColorScheme, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(cell, "enableNightTheme", @(self.nightThemeColorScheme.enabled), OBJC_ASSOCIATION_ASSIGN);
    
    NSDictionary *userPrefs = [NSDictionary dictionaryWithContentsOfFile:CVK_PREFS_PATH];
    BOOL changeSwitchColor = ([userPrefs[@"enabled"] boolValue] && [userPrefs[@"changeSwitchColor"] boolValue]);
    objc_setAssociatedObject(cell, "change_switch_color", @(changeSwitchColor), OBJC_ASSOCIATION_ASSIGN);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell renderBackgroundWithColor:nil separatorColor:nil forTableView:tableView indexPath:indexPath];
    [self updateNightThemeForCell:cell animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 48.0f;
}


#pragma mark -
#pragma mark DZNEmptyDataSetSource
#pragma mark -

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"WarningIcon" inBundle:self.cvkBundle compatibleWithTraitCollection:nil];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = NSLocalizedStringFromTableInBundle(@"LOADING_TWEAK_FILES_ERROR_MESSAGE", nil, self.cvkBundle, nil);
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    if (self.prefsTableView.tableHeaderView) {
        return -100.0f;
    }
    return -150.0f;
}

@end
