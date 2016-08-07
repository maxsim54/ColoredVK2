//
//  ColoredVKPrefsController.m
//  ColoredVK
//
//  Created by Даниил on 19.07.16.
//  Copyright (c) 2016 Daniil Pashin. All rights reserved.
//


#import "ColoredVKPrefsController.h"
#import "PrefixHeader.h"

@implementation ColoredVKPrefsController

- (id)specifiers
{
    
//    prefsPath = @"/var/mobile/Library/Preferences/com.daniilpashin.coloredvk.plist";
//    cvkBunlde = [NSBundle bundleWithPath:@"/Library/PreferenceBundles/ColoredVK.bundle"];
    
    prefsPath = CVK_PREFS_PATH;
    cvkBunlde = [NSBundle bundleWithPath:CVK_BUNDLE_PATH];

    
    
    NSMutableArray *specifiersArray = [[self loadSpecifiersFromPlistName:@"ColoredVKMainPrefs" target:self] mutableCopy];
    if (specifiersArray.count == 0) {
        [specifiersArray addObject:[self errorMessage]];
        [specifiersArray addObject:[self footer]];
    }  else {
        [specifiersArray insertObject:[self footer] atIndex:[specifiersArray indexOfObject:specifiersArray.lastObject]];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
            
            for (PSSpecifier *spec in specifiersArray) {                    
                if ([spec.identifier isEqualToString:@"prefsLink"]) {
                    [spec setProperty:@([prefs[@"enabled"] boolValue]) forKey:@"enabled"];
                }
            }
        });
    }
    
    _specifiers = [specifiersArray copy];
    
    [UISwitch appearanceWhenContainedIn:self.class, nil].tintColor = [UIColor colorWithRed:235.0/255.0f green:235.0/255.0f blue:235.0/255.0f alpha:1.0];
    [UISwitch appearanceWhenContainedIn:self.class, nil].onTintColor = [UIColor colorWithRed:90/255.0f green:130.0/255.0f blue:180.0/255.0f alpha:1.0];
    [UITableView appearanceWhenContainedIn:self.class, nil].separatorColor = [UIColor colorWithRed:220.0/255.0f green:221.0/255.0f blue:222.0/255.0f alpha:1];
    
    return _specifiers;
}


- (id) readPreferenceValue:(PSSpecifier*)specifier
{    
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
    
    if (!prefs[specifier.properties[@"key"]]) {
        return specifier.properties[@"default"];
    }
    return prefs[specifier.properties[@"key"]];
}


- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier
{
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] init];
    [prefs addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:prefsPath]];
    [prefs setValue:value forKey:specifier.properties[@"key"]];
    [prefs writeToFile:prefsPath atomically:YES];
    
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.daniilpashin.coloredvk.prefs.changed"), NULL, NULL, YES);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.daniilpashin.coloredvk.reload.menu"), NULL, NULL, YES);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.daniilpashin.coloredvk.reload.messages"), NULL, NULL, YES);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.daniilpashin.coloredvk.black.theme"), NULL, NULL, YES);
    
    [self reloadSpecifiers];
}


- (PSSpecifier *)footer
{
    NSString *footerText = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"TWEAK_FOOTER_TEXT", nil, cvkBunlde, nil), [self getTweakVersion], [self getVKVersion] ];
    
    PSSpecifier *footer = [PSSpecifier preferenceSpecifierNamed:@"" target:self set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
    [footer setProperty:[footerText stringByAppendingString:[NSString stringWithFormat:@"\n\n© Daniil Pashin %@", [self dynamicYear]]] forKey:@"footerText"];
    [footer setProperty:@"1" forKey:@"footerAlignment"];
    
    return footer;
}

- (PSSpecifier *)errorMessage
{
    PSSpecifier *errorMessage = [PSSpecifier preferenceSpecifierNamed:@"" target:self set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
    [errorMessage setProperty:[NSLocalizedStringFromTableInBundle(@"LOADING_TWEAK_FILES_ERROR_MESSAGE", nil, cvkBunlde, nil) stringByAppendingString:@"\n\nhttps://vk.com/danpashin"] forKey:@"footerText"];
    [errorMessage setProperty:@"1" forKey:@"footerAlignment"];
    return errorMessage;
}



- (NSString *)getTweakVersion
{
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
    return [prefs[@"cvkVersion"] stringByReplacingOccurrencesOfString:@"-" withString:@" "];
}

- (NSString *)getVKVersion
{
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
    return prefs[@"vkVersion"];
}


- (NSString *)dynamicYear
{
    NSString *dynamicYear = @"2015";
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yyyy";
    
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    
    if (![dynamicYear isEqual:dateString]) {   dynamicYear = [NSString stringWithFormat:@"%@ - %@", dynamicYear, dateString]; }
    return dynamicYear;
}



- (void)openProfie
{    
    NSURL *appURL = [NSURL URLWithString:@"vk://vk.com/danpashin"];
    NSURL *safariURL = [NSURL URLWithString:@"https://vk.com/danpashin"];
    if ( [[UIApplication sharedApplication] canOpenURL:appURL] ) {
        [[UIApplication sharedApplication] openURL:appURL];
    } else {
        [[UIApplication sharedApplication] openURL:safariURL];
    }
}

@end
