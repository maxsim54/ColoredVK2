//
//  TweakVariables.m
//  ColoredVK2
//
//  Created by Даниил on 01.04.18.
//

#import "TweakVariables.h"
#import "PrefixHeader.h"
#import "UIColor+ColoredVK.h"
#import "ColoredVKMainController.h"
#import "ColoredVKNewInstaller.h"

@interface UIStatusBar : UIView
@property (nonatomic, strong) UIColor *foregroundColor;
@end
@interface VKMMainController : UIViewController
@property (strong, nonatomic) UITableView *tableView;
@end

void resetUISearchBar(UISearchBar *searchBar);


BOOL premiumEnabled = NO;
BOOL VKSettingsEnabled;

BOOL enableNightTheme;

BOOL showFastDownloadButton;
BOOL showMenuCell;

NSBundle *cvkBunlde;
NSBundle *vksBundle;

BOOL enabled;
BOOL enabledBarColor;
BOOL showBar;
BOOL enabledToolBarColor;
BOOL enabledBarImage;
BOOL enabledTabbarColor;


BOOL enabledMenuImage;
BOOL hideMenuSeparators;
BOOL hideMessagesListSeparators;
BOOL hideGroupsListSeparators;
BOOL hideAudiosSeparators;
BOOL hideFriendsSeparators;
BOOL hideVideosSeparators;
BOOL hideSettingsSeparators;
BOOL hideSettingsExtraSeparators;

BOOL enabledMessagesImage;
BOOL enabledMessagesListImage;
BOOL enabledGroupsListImage;
BOOL enabledAudioImage;
BOOL changeAudioPlayerAppearance;
BOOL enablePlayerGestures;
BOOL enabledFriendsImage;
BOOL enabledVideosImage;
BOOL enabledSettingsImage;
BOOL enabledSettingsExtraImage;

CGFloat menuImageBlackout;
CGFloat chatImageBlackout;
CGFloat chatListImageBlackout;
CGFloat groupsListImageBlackout;
CGFloat audioImageBlackout;
CGFloat navbarImageBlackout;
CGFloat friendsImageBlackout;
CGFloat videosImageBlackout;
CGFloat settingsImageBlackout;
CGFloat settingsExtraImageBlackout;


CGFloat appCornerRadius;


BOOL useMenuParallax;
BOOL useMessagesListParallax;
BOOL useMessagesParallax;
BOOL useGroupsListParallax;
BOOL useAudioParallax;
BOOL useFriendsParallax;
BOOL useVideosParallax;
BOOL useSettingsParallax;
BOOL useSettingsExtraParallax;

BOOL hideMessagesNavBarItems;

BOOL hideMenuSearch;
BOOL changeSwitchColor;
BOOL changeSBColors;
BOOL shouldCheckUpdates;

BOOL useMessageBubbleTintColor;
BOOL useCustomMessageReadColor;

BOOL showCommentSeparators;
BOOL disableGroupCovers;

BOOL changeMenuTextColor;
BOOL changeMessagesListTextColor;
BOOL changeMessagesTextColor;
BOOL changeGroupsListTextColor;
BOOL changeAudiosTextColor;
BOOL changeFriendsTextColor;
BOOL changeVideosTextColor;
BOOL changeSettingsTextColor;
BOOL changeSettingsExtraTextColor;
BOOL changeMessagesInput;

BOOL useCustomDialogsUnreadColor;
UIColor *dialogsUnreadColor;

UIColor *menuSeparatorColor;
UIColor *barBackgroundColor;
UIColor *barForegroundColor;
UIColor *toolBarBackgroundColor;
UIColor *toolBarForegroundColor;
UIColor *tabbarForegroundColor;
UIColor *tabbarBackgroundColor;
UIColor *tabbarSelForegroundColor;
UIColor *SBBackgroundColor;
UIColor *SBForegroundColor;
UIColor *switchesTintColor;
UIColor *switchesOnTintColor;

UIColor *messageBubbleTintColor;
UIColor *messageBubbleSentTintColor;
UIColor *messageUnreadColor;

UIColor *menuTextColor;
UIColor *messagesListTextColor;
UIColor *messagesTextColor;
UIColor *groupsListTextColor;
UIColor *audiosTextColor;
UIColor *friendsTextColor;
UIColor *videosTextColor;
UIColor *settingsTextColor;
UIColor *settingsExtraTextColor;

UIColor *messagesInputTextColor;
UIColor *messagesInputBackColor;

UIColor *audioPlayerTintColor;
UIColor *menuSelectionColor;


UIColor *messagesBlurTone;
UIColor *messagesListBlurTone;
UIColor *groupsListBlurTone;
UIColor *audiosBlurTone;
UIColor *friendsBlurTone;
UIColor *videosBlurTone;
UIColor *settingsBlurTone;
UIColor *settingsExtraBlurTone;
UIColor *menuBlurTone;

BOOL messagesUseBlur;
BOOL messagesListUseBlur;
BOOL groupsListUseBlur;
BOOL audiosUseBlur;
BOOL friendsUseBlur;
BOOL videosUseBlur;
BOOL settingsUseBlur;
BOOL settingsExtraUseBlur;
BOOL menuUseBlur;

BOOL messagesUseBackgroundBlur;
BOOL messagesListUseBackgroundBlur;
BOOL groupsListUseBackgroundBlur;
BOOL audiosUseBackgroundBlur;
BOOL friendsUseBackgroundBlur;
BOOL videosUseBackgroundBlur;
BOOL settingsUseBackgroundBlur;
BOOL settingsExtraUseBackgroundBlur;
BOOL menuUseBackgroundBlur;


CVKCellSelectionStyle menuSelectionStyle;
UIKeyboardAppearance keyboardStyle;

UIBlurEffectStyle menuBlurStyle;
UIBlurEffectStyle messagesBlurStyle;
UIBlurEffectStyle messagesListBlurStyle;
UIBlurEffectStyle groupsListBlurStyle;
UIBlurEffectStyle audiosBlurStyle;
UIBlurEffectStyle friendsBlurStyle;
UIBlurEffectStyle videosBlurStyle;
UIBlurEffectStyle settingsBlurStyle;
UIBlurEffectStyle settingsExtraBlurStyle;

    //NSString *customFontName;

ColoredVKMainController *cvkMainController;


void reloadPrefs(void(^completion)(void))
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:CVK_PREFS_PATH];
        
        enabled = [prefs[@"enabled"] boolValue];
        hideMenuSearch = [prefs[@"hideMenuSearch"] boolValue];
        enabledMenuImage = [prefs[@"enabledMenuImage"] boolValue];
        menuImageBlackout = [prefs[@"menuImageBlackout"] floatValue];
        useMenuParallax = [prefs[@"useMenuParallax"] boolValue];
        useMessagesParallax = [prefs[@"useMessagesParallax"] boolValue];
        barForegroundColor = [UIColor savedColorForIdentifier:@"BarForegroundColor" fromPrefs:prefs];
        showBar = [prefs[@"showBar"] boolValue];
        SBBackgroundColor = [UIColor savedColorForIdentifier:@"SBBackgroundColor" fromPrefs:prefs];
        SBForegroundColor = [UIColor savedColorForIdentifier:@"SBForegroundColor" fromPrefs:prefs];
        
        shouldCheckUpdates = prefs[@"checkUpdates"]?[prefs[@"checkUpdates"] boolValue]:YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIStatusBar *statusBar = [[UIApplication sharedApplication] valueForKey:@"statusBar"];
            if (statusBar != nil) {
                if (enabled && enableNightTheme) {
                    statusBar.foregroundColor = [UIColor whiteColor];
                } else if (enabled && changeSBColors) {
                    statusBar.foregroundColor = SBForegroundColor;
                    statusBar.backgroundColor = SBBackgroundColor;
                } else {
                    statusBar.foregroundColor = nil;
                    statusBar.backgroundColor = nil;
                }
            }
        });
        
        enabledBarImage = [prefs[@"enabledBarImage"] boolValue];
        enabledBarColor = [prefs[@"enabledBarColor"] boolValue];
        enabledToolBarColor = [prefs[@"enabledToolBarColor"] boolValue];
        enabledTabbarColor = [prefs[@"enabledTabbarColor"] boolValue];
        
        enabledMessagesImage = [prefs[@"enabledMessagesImage"] boolValue];
        hideMenuSeparators = [prefs[@"hideMenuSeparators"] boolValue];
        messagesUseBlur = [prefs[@"messagesUseBlur"] boolValue];
        messagesUseBackgroundBlur = [prefs[@"messagesUseBackgroundBlur"] boolValue];
        useCustomMessageReadColor = [prefs[@"useCustomMessageReadColor"] boolValue];
        useCustomDialogsUnreadColor = [prefs[@"useCustomDialogsUnreadColor"] boolValue];
        menuUseBlur = [prefs[@"menuUseBlur"] boolValue];
        menuUseBackgroundBlur = [prefs[@"menuUseBackgroundBlur"] boolValue];
        changeMessagesInput = [prefs[@"changeMessagesInput"] boolValue];
        
        navbarImageBlackout = [prefs[@"navbarImageBlackout"] floatValue];
        chatImageBlackout = [prefs[@"chatImageBlackout"] floatValue];
        hideMessagesNavBarItems = [prefs[@"hideMessagesNavBarItems"] boolValue];
        changeMenuTextColor = [prefs[@"changeMenuTextColor"] boolValue];
        changeMessagesTextColor = [prefs[@"changeMessagesTextColor"] boolValue];
        useMessageBubbleTintColor = [prefs[@"useMessageBubbleTintColor"] boolValue];
        menuSelectionStyle = prefs[@"menuSelectionStyle"]?[prefs[@"menuSelectionStyle"] integerValue]:CVKCellSelectionStyleTransparent;
        messagesBlurStyle = prefs[@"messagesBlurStyle"]?[prefs[@"messagesBlurStyle"] integerValue]:UIBlurEffectStyleLight;
        menuBlurStyle = prefs[@"menuBlurStyle"]?[prefs[@"menuBlurStyle"] integerValue]:UIBlurEffectStyleLight;
        
        menuSeparatorColor =         [UIColor savedColorForIdentifier:@"MenuSeparatorColor"         fromPrefs:prefs];
        menuSelectionColor =        [[UIColor savedColorForIdentifier:@"menuSelectionColor"         fromPrefs:prefs] colorWithAlphaComponent:0.3f];
        barBackgroundColor =         [UIColor savedColorForIdentifier:@"BarBackgroundColor"         fromPrefs:prefs];
        toolBarBackgroundColor =     [UIColor savedColorForIdentifier:@"ToolBarBackgroundColor"     fromPrefs:prefs];
        toolBarForegroundColor =     [UIColor savedColorForIdentifier:@"ToolBarForegroundColor"     fromPrefs:prefs];
        messageBubbleTintColor =     [UIColor savedColorForIdentifier:@"messageBubbleTintColor"     fromPrefs:prefs];
        messageBubbleSentTintColor = [UIColor savedColorForIdentifier:@"messageBubbleSentTintColor" fromPrefs:prefs];
        menuTextColor =              [UIColor savedColorForIdentifier:@"menuTextColor"              fromPrefs:prefs];
        messagesTextColor =          [UIColor savedColorForIdentifier:@"messagesTextColor"          fromPrefs:prefs];
        messagesBlurTone =          [[UIColor savedColorForIdentifier:@"messagesBlurTone"           fromPrefs:prefs] colorWithAlphaComponent:0.3f];
        menuBlurTone =              [[UIColor savedColorForIdentifier:@"menuBlurTone"               fromPrefs:prefs] colorWithAlphaComponent:0.3f];
        tabbarBackgroundColor =     [UIColor savedColorForIdentifier:@"TabbarBackgroundColor"       fromPrefs:prefs];
        tabbarForegroundColor =     [UIColor savedColorForIdentifier:@"TabbarForegroundColor"       fromPrefs:prefs];
        tabbarSelForegroundColor =  [UIColor savedColorForIdentifier:@"TabbarSelForegroundColor"    fromPrefs:prefs];
        messagesInputTextColor =    [UIColor savedColorForIdentifier:@"messagesInputTextColor"      fromPrefs:prefs];
        messagesInputBackColor =    [UIColor savedColorForIdentifier:@"messagesInputBackColor"      fromPrefs:prefs];
        dialogsUnreadColor =        [[UIColor savedColorForIdentifier:@"dialogsUnreadColor"         fromPrefs:prefs] colorWithAlphaComponent:0.3f];
        messageUnreadColor =        [[UIColor savedColorForIdentifier:@"messageReadColor"           fromPrefs:prefs] colorWithAlphaComponent:0.2f];
        
        ColoredVKVersionCompare compareResult = [[ColoredVKNewInstaller sharedInstaller].application compareAppVersionWithVersion:@"3.0"];
        if (!hideMenuSeparators && !prefs[@"MenuSeparatorColor"] && (compareResult == ColoredVKVersionCompareMore)) {
            menuSeparatorColor  = [UIColor colorWithRed:215/255.0f green:216/255.0f blue:217/255.0f alpha:1.0f];
        }
        
        showFastDownloadButton = prefs[@"showFastDownloadButton"] ? [prefs[@"showFastDownloadButton"] boolValue] : YES;
        showMenuCell = prefs[@"showMenuCell"] ? [prefs[@"showMenuCell"] boolValue] : YES;
        
        if (prefs && premiumEnabled) {
            
            enableNightTheme = prefs[@"nightThemeType"] ? ([prefs[@"nightThemeType"] integerValue] != -1) : NO;
            [cvkMainController.nightThemeScheme updateForType:[prefs[@"nightThemeType"] integerValue]];
            cvkMainController.nightThemeScheme.enabled = (enabled && enableNightTheme);
            
            if (enableNightTheme && (compareResult == ColoredVKVersionCompareLess)) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    cvkMainController.menuBackgroundView.alpha = 0.0f;
                    resetUISearchBar((UISearchBar*)cvkMainController.vkMainController.tableView.tableHeaderView);
                });
            }
            
            changeSBColors = [prefs[@"changeSBColors"] boolValue];
            changeSwitchColor = [prefs[@"changeSwitchColor"] boolValue];
            showCommentSeparators = prefs[@"showCommentSeparators"] ? ![prefs[@"showCommentSeparators"] boolValue] : NO;
            
            disableGroupCovers = [prefs[@"disableGroupCovers"] boolValue];
            
            enabledMessagesListImage = [prefs[@"enabledMessagesListImage"] boolValue];
            enabledGroupsListImage = [prefs[@"enabledGroupsListImage"] boolValue];
            enabledAudioImage = [prefs[@"enabledAudioImage"] boolValue];
            changeAudioPlayerAppearance = [prefs[@"changeAudioPlayerAppearance"] boolValue];
            enablePlayerGestures = prefs[@"enablePlayerGestures"] ? [prefs[@"enablePlayerGestures"] boolValue] : YES;
            enabledFriendsImage = [prefs[@"enabledFriendsImage"] boolValue];
            enabledVideosImage = [prefs[@"enabledVideosImage"] boolValue];
            enabledSettingsImage = [prefs[@"enabledSettingsImage"] boolValue];
            enabledSettingsExtraImage = [prefs[@"enabledSettingsExtraImage"] boolValue];
            
            hideMessagesListSeparators = [prefs[@"hideMessagesListSeparators"] boolValue];
            hideGroupsListSeparators = [prefs[@"hideGroupsListSeparators"] boolValue];
            hideAudiosSeparators = [prefs[@"hideAudiosSeparators"] boolValue];
            hideFriendsSeparators = [prefs[@"hideFriendsSeparators"] boolValue];
            hideVideosSeparators = [prefs[@"hideVideosSeparators"] boolValue];
            hideSettingsSeparators = [prefs[@"hideSettingsSeparators"] boolValue];
            hideSettingsExtraSeparators = [prefs[@"hideSettingsExtraSeparators"] boolValue];
            
            messagesListUseBlur = [prefs[@"messagesListUseBlur"] boolValue];
            groupsListUseBlur = [prefs[@"groupsListUseBlur"] boolValue];
            audiosUseBlur = [prefs[@"audiosUseBlur"] boolValue];
            friendsUseBlur = [prefs[@"friendsUseBlur"] boolValue];
            videosUseBlur = [prefs[@"videosUseBlur"] boolValue];
            settingsUseBlur = [prefs[@"settingsUseBlur"] boolValue];
            settingsExtraUseBlur = [prefs[@"settingsExtraUseBlur"] boolValue];
            
            messagesListUseBackgroundBlur = [prefs[@"messagesListUseBackgroundBlur"] boolValue];
            groupsListUseBackgroundBlur = [prefs[@"groupsListUseBackgroundBlur"] boolValue];
            audiosUseBackgroundBlur = [prefs[@"audiosUseBackgroundBlur"] boolValue];
            friendsUseBackgroundBlur = [prefs[@"friendsUseBackgroundBlur"] boolValue];
            videosUseBackgroundBlur = [prefs[@"videosUseBackgroundBlur"] boolValue];
            settingsUseBackgroundBlur = [prefs[@"settingsUseBackgroundBlur"] boolValue];
            settingsExtraUseBackgroundBlur = [prefs[@"settingsExtraUseBackgroundBlur"] boolValue];
            
            
            useMessagesListParallax = [prefs[@"useMessagesListParallax"] boolValue];
            useGroupsListParallax = [prefs[@"useGroupsListParallax"] boolValue];
            useAudioParallax = [prefs[@"useAudioParallax"] boolValue];
            useFriendsParallax = [prefs[@"useFriendsParallax"] boolValue];
            useVideosParallax = [prefs[@"useVideosParallax"] boolValue];
            useSettingsParallax = [prefs[@"useSettingsParallax"] boolValue];
            useSettingsExtraParallax = [prefs[@"useSettingsExtraParallax"] boolValue];
            
            chatListImageBlackout = [prefs[@"chatListImageBlackout"] floatValue];
            groupsListImageBlackout = [prefs[@"groupsListImageBlackout"] floatValue];
            audioImageBlackout = [prefs[@"audioImageBlackout"] floatValue];
            friendsImageBlackout = [prefs[@"friendsImageBlackout"] floatValue];
            videosImageBlackout = [prefs[@"videosImageBlackout"] floatValue];
            settingsImageBlackout = [prefs[@"settingsImageBlackout"] floatValue];
            settingsExtraImageBlackout = [prefs[@"settingsExtraImageBlackout"] floatValue];
            
            appCornerRadius = [prefs[@"appCornerRadius"] floatValue];
            
            
            changeMessagesListTextColor = [prefs[@"changeMessagesListTextColor"] boolValue];
            changeGroupsListTextColor = [prefs[@"changeGroupsListTextColor"] boolValue];
            changeAudiosTextColor = [prefs[@"changeAudiosTextColor"] boolValue];
            changeFriendsTextColor = [prefs[@"changeFriendsTextColor"] boolValue];
            changeVideosTextColor = [prefs[@"changeVideosTextColor"] boolValue];
            changeSettingsTextColor = [prefs[@"changeSettingsTextColor"] boolValue];
            changeSettingsExtraTextColor = [prefs[@"changeSettingsExtraTextColor"] boolValue];
            
            keyboardStyle = prefs[@"keyboardStyle"]?[prefs[@"keyboardStyle"] integerValue]:UIKeyboardAppearanceDefault;
            
            messagesListBlurStyle = prefs[@"messagesListBlurStyle"]?[prefs[@"messagesListBlurStyle"] integerValue]:UIBlurEffectStyleLight;
            groupsListBlurStyle = prefs[@"groupsListBlurStyle"]?[prefs[@"groupsListBlurStyle"] integerValue]:UIBlurEffectStyleLight;
            audiosBlurStyle = prefs[@"audiosBlurStyle"]?[prefs[@"audiosBlurStyle"] integerValue]:UIBlurEffectStyleLight;
            friendsBlurStyle = prefs[@"friendsBlurStyle"]?[prefs[@"friendsBlurStyle"] integerValue]:UIBlurEffectStyleLight;
            videosBlurStyle = prefs[@"videosBlurStyle"]?[prefs[@"videosBlurStyle"] integerValue]:UIBlurEffectStyleLight;
            settingsBlurStyle = prefs[@"settingsBlurStyle"]?[prefs[@"settingsBlurStyle"] integerValue]:UIBlurEffectStyleLight;
            settingsExtraBlurStyle = prefs[@"settingsExtraBlurStyle"]?[prefs[@"settingsExtraBlurStyle"] integerValue]:UIBlurEffectStyleLight;
            
            
            switchesTintColor =          [UIColor savedColorForIdentifier:@"switchesTintColor"          fromPrefs:prefs];
            switchesOnTintColor =        [UIColor savedColorForIdentifier:@"switchesOnTintColor"        fromPrefs:prefs];
            
            messagesListTextColor =      [UIColor savedColorForIdentifier:@"messagesListTextColor"      fromPrefs:prefs];
            groupsListTextColor =        [UIColor savedColorForIdentifier:@"groupsListTextColor"        fromPrefs:prefs];
            audiosTextColor =            [UIColor savedColorForIdentifier:@"audiosTextColor"            fromPrefs:prefs];
            friendsTextColor =           [UIColor savedColorForIdentifier:@"friendsTextColor"           fromPrefs:prefs];
            videosTextColor =            [UIColor savedColorForIdentifier:@"videosTextColor"            fromPrefs:prefs];
            settingsTextColor =          [UIColor savedColorForIdentifier:@"settingsTextColor"          fromPrefs:prefs];
            settingsExtraTextColor =     [UIColor savedColorForIdentifier:@"settingsExtraTextColor"     fromPrefs:prefs];
            
            messagesListBlurTone =      [[UIColor savedColorForIdentifier:@"messagesListBlurTone"       fromPrefs:prefs] colorWithAlphaComponent:0.3f];
            groupsListBlurTone =        [[UIColor savedColorForIdentifier:@"groupsListBlurTone"         fromPrefs:prefs] colorWithAlphaComponent:0.3f];
            audiosBlurTone =            [[UIColor savedColorForIdentifier:@"audiosBlurTone"             fromPrefs:prefs] colorWithAlphaComponent:0.3f];
            friendsBlurTone =           [[UIColor savedColorForIdentifier:@"friendsBlurTone"            fromPrefs:prefs] colorWithAlphaComponent:0.3f];
            videosBlurTone =            [[UIColor savedColorForIdentifier:@"videosBlurTone"             fromPrefs:prefs] colorWithAlphaComponent:0.3f];
            settingsBlurTone =          [[UIColor savedColorForIdentifier:@"settingsBlurTone"           fromPrefs:prefs] colorWithAlphaComponent:0.3f];
            settingsExtraBlurTone =     [[UIColor savedColorForIdentifier:@"settingsExtraBlurTone"      fromPrefs:prefs] colorWithAlphaComponent:0.3f];
            
                //        customFontName = prefs[@"customFontName"] ? prefs[@"customFontName"] : @".SFUIText";
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (cvkMainController.navBarImageView)
                [cvkMainController.navBarImageView updateViewWithBlackout:navbarImageBlackout];
            
            if (completion)
                completion();
        });
    });
}
