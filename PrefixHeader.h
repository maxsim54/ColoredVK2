//
//  PrefixHeader.pch
//  ColoredVK
//
//  Created by Даниил on 25.07.16.
//
//

#import "NSString+ColoredVK.h"
#import "UIColor+ColoredVK.h"
#import "UIImage+ColoredVK.h"



#ifdef  COMPILE_FOR_JAIL
#define CVK_BUNDLE_PATH     @"/Library/PreferenceBundles/ColoredVK2.bundle"
#define VKS_BUNDLE_PATH     @"/Library/PreferenceBundles/vksprefs.bundle"
#define CVK_PREFS_PATH      @"/var/mobile/Library/Preferences/com.daniilpashin.coloredvk2.plist"
#define CVK_FOLDER_PATH     @"/var/mobile/Library/Preferences/ColoredVK2"
#else
#define CVK_BUNDLE_PATH     [NSBundle.mainBundle pathForResource: @"ColoredVK2" ofType: @"bundle"]
#define VKS_BUNDLE_PATH     [NSBundle.mainBundle pathForResource: @"vksprefs" ofType: @"bundle"]
#define CVK_PREFS_PATH      [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.daniilpashin.coloredvk2.plist"]
#define CVK_FOLDER_PATH     [NSHomeDirectory() stringByAppendingString:@"/Documents/ColoredVK2"]
#endif

#define IS_IPAD  UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
#define UIKitLocalizedString(key) [[NSBundle bundleWithIdentifier:@"com.apple.UIKit"] localizedStringForKey:key value:@"" table:nil]
#define CVKLocalizedString(key) [[NSBundle bundleWithPath:CVK_BUNDLE_PATH] localizedStringForKey:key value:@"" table:nil]
#define CVKLocalizedStringFromTable(key, tbl) [[NSBundle bundleWithPath:CVK_BUNDLE_PATH] localizedStringForKey:key value:@"" table:tbl]
#define IS_IOS_10_OR_LATER    ([UIDevice currentDevice].systemVersion.floatValue >= 10.0)

#define kColoredVKVersion @"3.2.0.2"

#ifdef CHAppName
    #undef CHAppName
#endif 
#define CHAppName "[COLOREDVK2]"

#define API_VERSION @"1.2"
