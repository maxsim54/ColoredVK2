//
//  ColoredVKImagePrefsCell.m
//  ColoredVK
//
//  Created by Даниил on 25.04.16.
//  Copyright (c) 2016 Daniil Pashin. All rights reserved.
//


#import "ColoredVKHUD.h"
#import "ColoredVKAlertController.h"

#import "ColoredVKImagePrefsCell.h"
#import "ColoredVKPrefs.h"

@interface ColoredVKImagePrefsCell ()

@property (strong, nonatomic, readonly) NSString *switchKey;
@property (strong, nonatomic) UIImageView *previewImageView;

@end

@implementation ColoredVKImagePrefsCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)specifier
{
    self = [super initWithStyle:style reuseIdentifier:identifier specifier:specifier];
    if (self) {
        _switchKey = [self switchKeyForIdentifier:specifier.identifier];
        self.switchView.enabled = NO;
        
        CGFloat imageViewSize = 32.0f;
        self.previewImageView = [UIImageView new];
        self.previewImageView.backgroundColor = [UIColor colorWithRed:239/255.0f green:239/255.0f blue:244/255.0f alpha:1.0f];
        self.previewImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.previewImageView.userInteractionEnabled = YES;
        self.previewImageView.layer.masksToBounds = YES;
        self.previewImageView.layer.cornerRadius = imageViewSize / 4.0f;
        [self.contentView addSubview:self.previewImageView];
        
        self.previewImageView.translatesAutoresizingMaskIntoConstraints = NO;       
        [self.previewImageView.widthAnchor constraintEqualToConstant:imageViewSize].active = YES;
        [self.previewImageView.heightAnchor constraintEqualToConstant:imageViewSize].active = YES;
        [self.previewImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = YES;
        [self.previewImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8.0f].active = YES;
        
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showActionsController:)];
        longPress.minimumPressDuration = 1.0;
        [self addGestureRecognizer:longPress];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(notificationUpdateImage:) 
                                                   name:kPackageNotificationUpdateImage object:nil];
        [self updateImage];
    }
    return self;
}

- (NSString *)switchKeyForIdentifier:(NSString *)identifier
{
    if ([identifier isEqualToString:@"barImage"])                           return @"enabledBarImage"; 
    else if ([identifier isEqualToString:@"menuBackgroundImage"])           return @"enabledMenuImage"; 
    else if ([identifier isEqualToString:@"messagesBackgroundImage"])       return @"enabledMessagesImage"; 
    else if ([identifier isEqualToString:@"messagesListBackgroundImage"])   return @"enabledMessagesListImage";
    else if ([identifier isEqualToString:@"groupsListBackgroundImage"])     return @"enabledGroupsListImage";
    else if ([identifier isEqualToString:@"audioBackgroundImage"])          return @"enabledAudioImage";
    else if ([identifier isEqualToString:@"audioCoverImage"])               return @"enabledAudioCustomCover";
    else if ([identifier isEqualToString:@"friendsBackgroundImage"])        return @"enabledFriendsImage";
    else if ([identifier isEqualToString:@"videosBackgroundImage"])         return @"enabledVideosImage";
    else if ([identifier isEqualToString:@"settingsBackgroundImage"])       return @"enabledSettingsImage";
    else if ([identifier isEqualToString:@"settingsExtraBackgroundImage"])  return @"enabledSettingsExtraImage";
    
    return @"";
}

- (void)updateSwitchWithSpecifier:(PSSpecifier *)specifier
{
    if ([self.cellTarget isKindOfClass:[ColoredVKPrefs class]]) {
        ColoredVKPrefs *prefsController = self.cellTarget;
        NSDictionary *prefs = prefsController.cachedPrefs;
        self.switchView.on = prefs[self.switchKey] ? [prefs[self.switchKey] boolValue] : NO;
    }
}

- (void)switchTriggered:(UISwitch *)switchView
{
    if (self.switchKey.length == 0)
        return;
    
    [self setPreferenceValue:@(switchView.on) forKey:self.switchKey];
}

- (void)updateImage
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSString *previewPath = [NSString stringWithFormat:@"%@/%@_preview.png", CVK_FOLDER_PATH, self.specifier.identifier];
        UIImage *image = [UIImage imageWithContentsOfFile:previewPath];
        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.switchView.enabled = YES;
                self.previewImageView.image = image;
            });
        }
    });
}

- (void)notificationUpdateImage:(NSNotification *)notification
{
    NSString *identifier = notification.userInfo[@"identifier"];
    if ([self.specifier.identifier isEqualToString:identifier])
        [self updateImage];
}


#pragma mark -
#pragma mark Actions
#pragma mark -

- (void)showActionsController:(UILongPressGestureRecognizer *)recognizer
{
    if ([self.specifier propertyForKey:@"enabled"] && ![[self.specifier propertyForKey:@"enabled"] boolValue])
        return;
    
    if (recognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    NSString *imagePath = [NSString stringWithFormat:@"%@/%@.png", CVK_FOLDER_PATH, self.specifier.identifier];
    if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath])
        return;
    
    ColoredVKAlertController *alertController = [ColoredVKAlertController alertControllerWithTitle:nil message:nil 
                                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addCancelAction];
    [alertController addAction:[UIAlertAction actionWithTitle:UIKitLocalizedString(@"Save to Camera Roll") 
                                                        style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                            [self actionSaveImage:imagePath];
                                                        }] image:@"prefs/SaveIconAlt"];
    
    [alertController addAction:[UIAlertAction actionWithTitle:UIKitLocalizedString(@"Share...")
                                                        style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                            [self actionShareImage:imagePath];
                                                        }] image:@"prefs/ShareIcon"];
    
    [alertController addAction:[UIAlertAction actionWithTitle:UIKitLocalizedString(@"Delete") 
                                                        style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                                                            [self actionRemoveImage];
                                                        }] image:@"prefs/RemoveIcon"];
    [alertController present];
}

- (void)actionSaveImage:(NSString *)imagePath
{
    ColoredVKHUD *hud = [ColoredVKHUD showHUD];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), (void *)CFBridgingRetain(hud));
}

- (void)actionShareImage:(NSString *)imagePath
{
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[image] 
                                                                             applicationActivities:nil];
    
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    if (IS_IPAD) {
        activityVC.popoverPresentationController.permittedArrowDirections = 0;
        activityVC.popoverPresentationController.sourceView = rootViewController.view;
        activityVC.popoverPresentationController.sourceRect = rootViewController.view.bounds;
    }
    [rootViewController presentViewController:activityVC animated:YES completion:nil];
}

- (void)actionRemoveImage
{
    ColoredVKAlertController *warningAlert = [ColoredVKAlertController alertControllerWithTitle:CVKLocalizedString(@"WARNING")  
                                                                                        message:CVKLocalizedString(@"REMOVE_IMAGE_WARNING")];
    [warningAlert addCancelAction];
    [warningAlert addAction:[UIAlertAction actionWithTitle:UIKitLocalizedString(@"Delete") style:UIAlertActionStyleDestructive  handler:^(UIAlertAction *warningAction) {
        NSString *imagePath = [NSString stringWithFormat:@"%@/%@.png", CVK_FOLDER_PATH, self.specifier.identifier];
        NSString *previewPath = [NSString stringWithFormat:@"%@/%@_preview.png", CVK_FOLDER_PATH, self.specifier.identifier];
        
        NSError *error = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if ([fileManager fileExistsAtPath:previewPath])
            [fileManager removeItemAtPath:previewPath error:&error];
        
        if ([fileManager fileExistsAtPath:imagePath])
            [fileManager removeItemAtPath:imagePath error:&error];
        
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.previewImageView.image = nil;
                [self.switchView setOn:NO animated:YES];
                self.switchView.enabled = NO;
                [self switchTriggered:self.switchView];
            });
        }
    }]];
    [warningAlert present];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    ColoredVKHUD *hud = CFBridgingRelease(contextInfo);
    error ? [hud showFailureWithStatus:error.localizedFailureReason] : [hud showSuccess];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

@end
