//
//  MtThemeSelector.h
//  themeparser
//
//  Created by Richard Cooper on 21/09/2016.
//  Copyright © 2016 Mountainstorm. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MtThemeParseError.h"

@interface MtThemeSelector : NSObject

+ (id)selector;

- (BOOL)matchView:(NSView*)view;

@property (retain) NSMutableArray* components;

@end
