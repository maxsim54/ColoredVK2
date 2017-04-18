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
#define CVK_CACHE_PATH      @"/var/mobile/Library/Caches/com.daniilpashin.coloredvk2/"
#define CVK_CACHE_PATH_OLD  @"/var/mobile/Library/Preferences/ColoredVK2/Cache"
#define CVK_BACKUP_PATH     @"/var/mobile/Documents/ColoredVK2_Backups/"

#elif defined COMPILE_APP

#define CVK_BUNDLE_PATH     [NSBundle mainBundle].bundlePath
#define CVK_PREFS_PATH      @"/var/mobile/Library/Preferences/com.daniilpashin.coloredvk2.plist"
#define CVK_FOLDER_PATH     @"/var/mobile/Library/Preferences/ColoredVK2"
#define CVK_CACHE_PATH      @"/var/mobile/Library/Caches/com.daniilpashin.coloredvk2/"
#define CVK_BACKUP_PATH     @"/var/mobile/Documents/ColoredVK2_Backups/"

#else

#define CVK_BUNDLE_PATH     [[NSBundle mainBundle] pathForResource: @"ColoredVK2" ofType: @"bundle"]
#define VKS_BUNDLE_PATH     [[NSBundle mainBundle] pathForResource: @"vksprefs" ofType: @"bundle"]
#define CVK_PREFS_PATH      [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.daniilpashin.coloredvk2.plist"]
#define CVK_FOLDER_PATH     [NSHomeDirectory() stringByAppendingString:@"/Documents/ColoredVK2"]
#define CVK_CACHE_PATH      [NSHomeDirectory() stringByAppendingString:@"/Library/Caches/ColoredVK2/Cache"]
#define CVK_BACKUP_PATH     [NSHomeDirectory() stringByAppendingString:@"/Documents/ColoredVK2_Backups"]

#endif

#define IS_IPAD                               (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define UIKitLocalizedString(key)             [[NSBundle bundleWithIdentifier:@"com.apple.UIKit"] localizedStringForKey:key value:@"" table:nil]
#define CVKLocalizedStringFromTableInBundle(key, tbl, bndl) [bndl localizedStringForKey:key value:@"" table:tbl]
#define CVKLocalizedStringFromTable(key, tbl) CVKLocalizedStringFromTableInBundle(key, tbl, [NSBundle bundleWithPath:CVK_BUNDLE_PATH])
#define CVKLocalizedString(key)               CVKLocalizedStringFromTable(key, nil)
#define SYSTEM_VERSION                        [UIDevice currentDevice].systemVersion
#define SYSTEM_VERSION_IS_MORE_THAN(version)  ([SYSTEM_VERSION compare:version options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_IS_EQUAL(version)      ([SYSTEM_VERSION compare:version options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_IS_LESS_THAN(version)  ([SYSTEM_VERSION compare:version options:NSNumericSearch] != NSOrderedDescending)
#define CLASS_NAME(obj)                       NSStringFromClass([obj class])

#define CVKTableViewSeparatorColor [UIColor colorWithRed:220.0/255.0f green:221.0/255.0f blue:222.0/255.0f alpha:1]
#define CVKMainColor [UIColor colorWithRed:90/255.0f green:130/255.0f blue:180/255.0f alpha:1]

#define kColoredVKVersion @"3.2.7-beta-3"

#ifdef CHAppName
    #undef CHAppName
#endif 
#define CHAppName "[COLOREDVK 2]"

#define API_VERSION @"1.2"
