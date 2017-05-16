//
//  ColoredVKMainPrefsController.m
//  ColoredVK
//
//  Created by Даниил on 19.07.16.
//  Copyright (c) 2016 Daniil Pashin. All rights reserved.
//


#import "ColoredVKMainPrefsController.h"
#import "ColoredVKHeaderView.h"
#import "ColoredVKInstaller.h"
#import "ColoredVKHelpController.h"

@implementation ColoredVKMainPrefsController

- (NSArray *)specifiers
{
    if (!_specifiers) {
        NSMutableArray *specifiersArray = [self specifiersForPlistName:@"Main" localize:NO addFooter:YES].mutableCopy;
        
        PSSpecifier *specifierToRemove = nil;
        for (PSSpecifier *specifier in specifiersArray) {
            if ([specifier.identifier isEqualToString:@"manageAccount"]) {
                if (!licenceContainsKey(@"Login")) {
                    specifierToRemove = specifier;
                    break;
                }
            }
        }
        if (specifierToRemove) [specifiersArray removeObject:specifierToRemove];
        
        _specifiers = specifiersArray.copy;
    }
    return _specifiers;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
#ifndef COMPILE_APP
    [ColoredVKInstaller sharedInstaller];
#endif
    self.prefsTableView.tableHeaderView = [ColoredVKHeaderView headerForView:self.prefsTableView];
    self.navigationItem.title = @"";
    
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:self.prefsPath];
    
    if (![prefs[@"userAgreeWithCopyrights"] boolValue]) {
        ColoredVKHelpController *helpController = [ColoredVKHelpController new];
        helpController.backgroundStyle = ColoredVKWindowBackgroundStyleBlurred;
        [helpController show];
    }
}
@end
