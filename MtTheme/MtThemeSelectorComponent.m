//
//  MtThemeSelectorComponent.m
//  themeparser
//
//  Created by Richard Cooper on 21/09/2016.
//  Copyright © 2016 Mountainstorm. All rights reserved.
//

#import "MtThemeSelectorComponent.h"
#import "MtThemeAttribute.h"


@implementation MtThemeSelectorComponent

+ (id)component
{
    return [[MtThemeSelectorComponent alloc] init];
}

- (NSString*)description
{
    NSMutableString* retval = [NSMutableString stringWithString:NSStringFromClass(self.classObj)];
    if (self.isKindOfClass) {
        [retval appendString:@">"];
    }
    if (self.attributes.count) {
        [retval appendFormat:@"[%@]", [self.attributes.allValues componentsJoinedByString:@","]];
    }
    return retval;
}

- (BOOL)matchView:(NSView*)view
{
    BOOL retval = NO;
    if (_isKindOfClass) {
        retval = [view isKindOfClass:_classObj];
    } else {
        retval = view.class == _classObj;
    }
    
    if (retval == YES) {
        // the class is right - check all attributes
        for (id name in _attributes) {
            MtThemeAttribute* attr = [_attributes objectForKey:name];
            if ([attr matchView:view] == NO) {
                retval = NO;
                break;
            }
        }
    }
    return retval;
}

@end
