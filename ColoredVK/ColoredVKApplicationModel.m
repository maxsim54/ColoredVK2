//
//  ColoredVKApplicationModel.m
//  ColoredVK2
//
//  Created by Даниил on 09.03.18.
//

#import "ColoredVKApplicationModel.h"

@implementation ColoredVKApplicationModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _teamIdentifier = @"";
        _teamName = @"";
        _version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        _detailedVersion = [NSString stringWithFormat:@"%@ (%@)", self.version, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];;
        
        [self updateTeamInformation];
    }
    return self;
}

- (void)updateTeamInformation
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSError *error = nil;
        NSString *provisionPath = [[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"];
        NSString *provisionString = [NSString stringWithContentsOfFile:provisionPath encoding:NSISOLatin1StringEncoding error:&error];
        
        if (!error) {         
            NSString *provisionDictString = @"";
            
            NSScanner *scanner = [NSScanner scannerWithString:provisionString];
            [scanner scanUpToString:@"<plist" intoString:nil];
            [scanner scanUpToString:@"</plist>" intoString:&provisionDictString];
            provisionDictString = [@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n" stringByAppendingString:provisionDictString];
            provisionDictString = [provisionDictString stringByAppendingString:@"</plist>"];
            
            NSString *tempPath = [NSTemporaryDirectory() stringByAppendingString:@"/embedded_mobileprovision.plist"];
            [[provisionDictString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:tempPath atomically:YES];
            
            NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:tempPath];
            if (dict) {
                self->_teamIdentifier = ((NSArray *)dict[@"TeamIdentifier"]).firstObject;
                self->_teamName = dict[@"TeamName"];
            }
            [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
        }
    });
}

- (ColoredVKVersionCompare)compareAppVersionWithVersion:(NSString *)second_version
{
    return [self compareVersion:self.version withVersion:second_version];
}

- (ColoredVKVersionCompare)compareVersion:(NSString *)first_version withVersion:(NSString *)second_version
{
    if ([first_version isEqualToString:second_version])
        return ColoredVKVersionCompareEqual;
    
    NSArray *first_version_components = [first_version componentsSeparatedByString:@"."];
    NSArray *second_version_components = [second_version componentsSeparatedByString:@"."];
    NSInteger length = MIN(first_version_components.count, second_version_components.count);
    
    
    for (int i = 0; i < length; i++) {
        NSInteger first_component = [first_version_components[i] integerValue];
        NSInteger second_component = [second_version_components[i] integerValue];
        
        if (first_component > second_component)
            return ColoredVKVersionCompareMore;
        
        if (first_component < second_component)
            return ColoredVKVersionCompareLess;
    }
    
    
    if (first_version_components.count > second_version_components.count)
        return ColoredVKVersionCompareMore;
    
    if (first_version_components.count < second_version_components.count)
        return ColoredVKVersionCompareLess;
    
    
    return ColoredVKVersionCompareEqual;
}

@end
