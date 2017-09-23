//
//  ColoredVKGeneralPrefs.m
//  ColoredVK
//
//  Created by Даниил on 14.04.17.
//
//

#import "ColoredVKGeneralPrefs.h"
#import "ColoredVKHUD.h"
#import "ColoredVKSettingsController.h"
#import "ColoredVKNewInstaller.h"
#import "ColoredVKImageProcessor.h"


@implementation ColoredVKGeneralPrefs

NSArray <NSString *> *specifiersToDisable;

- (NSArray *)specifiers
{
    if (!_specifiers) {
        NSMutableArray *specifiersArray = super.specifiers.mutableCopy;
        
        ColoredVKNewInstaller *newInstaller = [ColoredVKNewInstaller sharedInstaller]; 
        BOOL shouldDisable = (!newInstaller.tweakPurchased || !newInstaller.tweakActivated);
        
        for (PSSpecifier *specifier in specifiersArray) {
            if (([specifiersToDisable containsObject:specifier.identifier] && shouldDisable) || ![[self.specifier propertyForKey:@"enabled"] boolValue]) {
                [specifier setProperty:@NO forKey:@"enabled"];
            } else {
                [specifier setProperty:@YES forKey:@"enabled"];
            }
        }
        
        _specifiers = specifiersArray.copy;
    }
    return _specifiers;
}

- (void)loadView
{
    [super loadView];
    
    specifiersToDisable = @[];
}

#pragma mark -
#pragma mark UITableViewDelegate
#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PSSpecifier *specifier = [self specifierForIndexPath:indexPath];
    
    if (![[specifier propertyForKey:@"enabled"] boolValue]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        [self showPurchaseAlert];
    } else {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.userInteractionEnabled = YES;
    
    return cell;
}


- (void)showColorPicker:(PSSpecifier*)specifier
{
    ColoredVKColorPickerController *picker = [ColoredVKColorPickerController pickerWithIdentifier:specifier.identifier];
    picker.delegate = self;
    picker.dataSource = self;
    picker.statusBarNeedsHidden = NO;
    picker.backgroundStyle = ColoredVKWindowBackgroundStyleCustom;
    [picker show];
}


#pragma mark - 
#pragma mark ColoredVKColorPickerControllerDelegate
#pragma mark - 

- (void)colorPicker:(ColoredVKColorPickerController *)colorPicker willDismissWithColor:(UIColor *)color
{
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:self.prefsPath];
    
    if (color) {
        prefs[colorPicker.identifier] = color.stringValue;
    } else {
        if (prefs[colorPicker.identifier]) [prefs removeObjectForKey:colorPicker.identifier];
    }
    
    [prefs writeToFile:self.prefsPath atomically:YES];
    
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterPostNotification(center, CFSTR("com.daniilpashin.coloredvk2.prefs.changed"), NULL, NULL, YES);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.daniilpashin.coloredvk2.prefs.colorUpdate" object:nil userInfo:@{@"identifier":colorPicker.identifier}];
    
    NSArray *identificsToReloadMenu = @[@"MenuSeparatorColor", @"switchesTintColor", @"switchesOnTintColor", @"menuTextColor"];
    if ([identificsToReloadMenu containsObject:colorPicker.identifier])
        CFNotificationCenterPostNotification(center, CFSTR("com.daniilpashin.coloredvk2.reload.menu"), NULL, NULL, YES);
    
    if (self.app_is_vk) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UINavigationBar *navBar = self.navigationController.navigationBar;
            navBar.barTintColor = navBar.barTintColor;
            navBar.tintColor = navBar.tintColor;
            navBar.titleTextAttributes = navBar.titleTextAttributes;
            
            [self reloadSpecifiers];
        });
    }
}

- (void)colorPicker:(ColoredVKColorPickerController *)colorPicker didSaveColor:(NSString *)hexColor
{
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:self.prefsPath];
    NSMutableArray <NSString *> *savedColors = prefs[@"savedColors"] ? prefs[@"savedColors"] : [NSMutableArray new];
    
    if (![savedColors containsObject:hexColor])
        [savedColors addObject:hexColor];
    
    prefs[@"savedColors"] = savedColors;
    [prefs writeToFile:self.prefsPath atomically:YES];
}

- (void)colorPicker:(ColoredVKColorPickerController *)colorPicker didDeleteColor:(NSString *)hexColor
{
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:self.prefsPath];
    NSMutableArray <NSString *> *savedColors = prefs[@"savedColors"] ? prefs[@"savedColors"] : [NSMutableArray new];
    
    if ([savedColors containsObject:hexColor])
        [savedColors removeObject:hexColor];
    
    prefs[@"savedColors"] = savedColors;
    [prefs writeToFile:self.prefsPath atomically:YES];
}


#pragma mark - 
#pragma mark ColoredVKColorPickerControllerDataSource
#pragma mark - 

- (NSArray <NSString *> *)savedColorsForColorPicker:(ColoredVKColorPickerController *)colorPicker
{
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:self.prefsPath];
    NSArray <NSString *> *savedColors = prefs[@"savedColors"] ? prefs[@"savedColors"] : [NSArray new];
    
    return savedColors;
}


#pragma mark - 
#pragma mark UIImagePickerControllerDelegate
#pragma mark - 

- (void)chooseImage:(PSSpecifier*)specifier
{
    self.lastImageIdentifier = specifier.identifier;
    UIImagePickerController *picker = [UIImagePickerController new];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    [self presentPopover:picker];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    ColoredVKHUD *hud = [ColoredVKHUD showHUDForView:picker.view];
    hud.didHiddenBlock = ^{
        [picker dismissViewControllerAnimated:YES completion:nil];
    };
    
    ColoredVKImageProcessor *processor = [ColoredVKImageProcessor new];
    NSString *stringPath = [CVK_FOLDER_PATH stringByAppendingString:[NSString stringWithFormat:@"/%@.png", self.lastImageIdentifier]];
    [processor processImage:image identifier:self.lastImageIdentifier andSaveToURL:[NSURL fileURLWithPath:stringPath] 
                   completionBlock:^(BOOL success, NSError *error) {
                       success ? [hud showSuccess] : [hud showFailureWithStatus:error.localizedDescription];
                       
                       [[NSNotificationCenter defaultCenter] postNotificationName:@"com.daniilpashin.coloredvk2.image.update" object:nil userInfo:@{@"identifier" : self.lastImageIdentifier}];
                       
                       if ([self.lastImageIdentifier isEqualToString:@"menuBackgroundImage"]) {
                           CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.daniilpashin.coloredvk2.reload.menu"), NULL, NULL, YES);
                       }
                   }];
}


#pragma mark -
- (void)clearCoversCache
{
    ColoredVKHUD *hud = [ColoredVKHUD showHUD];
    hud.operation = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:CVK_CACHE_PATH error:&error];
        if (success && !error) [hud showSuccess];
        else [hud showFailureWithStatus:[NSString stringWithFormat:@"%@\n%@", error.localizedDescription, error.localizedFailureReason]];
        [self reloadSpecifiers];
    }];
}

- (NSString *)cacheSize
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    float size = 0;
    for (NSString *fileName in [fileManager subpathsOfDirectoryAtPath:CVK_CACHE_PATH error:nil]) {
        size += [[fileManager attributesOfItemAtPath:[CVK_CACHE_PATH stringByAppendingPathComponent:fileName] error:nil][NSFileSize] floatValue];
    }
    size = size / 1024.0f / 1024.0f;
    return [NSString stringWithFormat:@"%.1f MB", size];
}

- (void)resetSettings
{
    [[ColoredVKSettingsController new] actionReset];
}

- (void)backupSettings
{
    [[ColoredVKSettingsController new] actionBackup];
}
@end
