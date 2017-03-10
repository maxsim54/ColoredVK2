//
//  ColoredVKMainController.h
//  ColoredVK
//
//  Created by Даниил on 26/11/16.
//
//

#import "VKMethods.h"
#import "ColoredVKAudioLyricsView.h"
#import "ColoredVKAudioCoverView.h"
#import "ColoredVKBackgroundImageView.h"

@interface ColoredVKMainController : NSObject
+ (void)setImageToTableView:(UITableView *)tableView withName:(NSString *)name blackout:(CGFloat)blackout;
+ (void)setImageToTableView:(UITableView *)tableView withName:(NSString *)name blackout:(CGFloat)blackout flip:(BOOL)flip;
+ (void)setImageToTableView:(UITableView *)tableView withName:(NSString *)name blackout:(CGFloat)blackout parallaxEffect:(BOOL)parallaxEffect;
+ (void)setImageToTableView:(UITableView *)tableView withName:(NSString *)name blackout:(CGFloat)blackout flip:(BOOL)flip parallaxEffect:(BOOL)parallaxEffect;

- (void)reloadSwitch:(BOOL)on;
- (void)switchTriggered:(UISwitch*)switchView;
@property (strong, nonatomic) MenuCell *menuCell;

@property (strong, nonatomic) ColoredVKAudioLyricsView *audioLyricsView;
@property (strong, nonatomic) ColoredVKAudioCoverView *coverView;
@property (strong, nonatomic) ColoredVKBackgroundImageView *menuBackgroundView;
@property (strong, nonatomic) ColoredVKBackgroundImageView *navBarImageView;

@end
