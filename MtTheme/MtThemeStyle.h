//
//  MtThemeStyle.h
//  themeparser
//
//  Created by Richard Cooper on 22/09/2016.
//  Copyright © 2016 Mountainstorm. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MtThemeParseError.h"

@interface MtThemeStyle : NSObject

+ (id)style;

- (BOOL)parseSelector:(NSString*)line end:(NSUInteger*)end error:(MtThemeParseError**)error;
- (BOOL)parseAttribute:(NSString*)line end:(NSUInteger*)end error:(MtThemeParseError**)error;

- (BOOL)matchView:(NSView*)view;

@property (retain) NSMutableArray* selectors;
@property (retain) NSMutableDictionary* attributes;

@end
