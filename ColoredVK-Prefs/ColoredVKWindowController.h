//
//  ColoredVKWindowController.h
//  ColoredVK2
//
//  Created by Даниил on 11.05.17.
//
//

#import <UIKit/UIKit.h>
#import "ColoredVKNightThemeColorScheme.h"

typedef NS_ENUM(NSUInteger, ColoredVKWindowBackgroundStyle) {
    ColoredVKWindowBackgroundStyleBlurred,
    ColoredVKWindowBackgroundStyleDarkened,
    ColoredVKWindowBackgroundStyleCustom
};

@interface ColoredVKWindowController : UIViewController <UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic, readonly) UIWindow *window;
@property (strong, nonatomic) UINavigationBar *contentViewNavigationBar;
/**
 *  Default ColoredVKWindowBackgroundStyleDarkened
 */
@property (assign, nonatomic) ColoredVKWindowBackgroundStyle backgroundStyle;
/**
 *  Default YES
 */
@property (assign, nonatomic) BOOL hideByTouch;
/**
 *  Default YES
 */
@property (assign, nonatomic) BOOL statusBarNeedsHidden;
/**
 *  Default NO
 */
@property (assign, nonatomic) BOOL contentViewWantsShadow;

/**
 *  Default 0.3
 */
@property (assign, nonatomic) NSTimeInterval animationDuration;

@property (weak, nonatomic) ColoredVKNightThemeColorScheme *nightThemeColorScheme;
@property (assign, nonatomic) BOOL enableNightTheme;
@property (assign, nonatomic) BOOL app_is_vk;

- (void)hide;
- (void)show;

- (void)setupDefaultContentView;

@end
