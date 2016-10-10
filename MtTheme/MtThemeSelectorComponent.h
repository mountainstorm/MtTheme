//
//  MtThemeSelectorComponent.h
//  themeparser
//
//  Created by Richard Cooper on 21/09/2016.
//  Copyright © 2016 Mountainstorm. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MtThemeParseError.h"

@interface MtThemeSelectorComponent : NSObject

+ (id)component;

- (BOOL)matchView:(NSView*)view;

@property (retain) Class classObj;
@property BOOL isKindOfClass;
@property (retain) NSMutableDictionary* attributes;

@end
