//
//  MtThemeSelector.m
//  themeparser
//
//  Created by Richard Cooper on 21/09/2016.
//  Copyright © 2016 Mountainstorm. All rights reserved.
//

#import "MtThemeSelector.h"
#import "MtThemeSelectorComponent.h"

@implementation MtThemeSelector

+ (id)selector
{
    return [[MtThemeSelector alloc] init];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.components = [NSMutableArray array];
    }
    return self;
}

- (NSString*)description
{
    NSArray* components = [[_components reverseObjectEnumerator] allObjects];
    return [components componentsJoinedByString:@"."];
}

- (BOOL)matchView:(NSView*)view
{
    BOOL retval = YES;
    NSView* cur = view;
    for (MtThemeSelectorComponent* component in _components) {
        if ([component matchView:cur] == NO) {
            retval = NO;
            break;
        }
        cur = view.superview;
    }
    return retval;
}

@end
