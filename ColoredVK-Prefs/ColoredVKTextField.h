//
//  ColoredVKTextField.h
//  ColoredVK2
//
//  Created by Даниил on 06/01/2018.
//

#import <UIKit/UIKit.h>


@interface ColoredVKTextField : UITextField

@property (assign, nonatomic) BOOL error;

- (void)shake;
- (void)clear;

@end
