//
//  MtTheme.h
//  themeparser
//
//  Created by Richard Cooper on 22/09/2016.
//  Copyright © 2016 Mountainstorm. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MtThemeParseError.h"

@interface MtTheme : NSObject

+ (MtTheme*)sharedTheme;

+ (id)themeFromFile:(NSString*)path error:(MtThemeParseError**)error;
+ (id)themeFromString:(NSString*)text error:(MtThemeParseError**)error;

- (void)updateWindow:(NSWindow*)window;
- (void)updateViewAndSubviews:(NSView*)view;

- (void)updateView:(NSView*)view;
- (NSDictionary*)matchView:(NSView*)view;
- (void)applyStyles:(NSDictionary*)styles toView:(NSView*)view;

- (BOOL)appendFromFile:(NSString*)path error:(MtThemeParseError**)error;
- (BOOL)appendFromString:(NSString*)text error:(MtThemeParseError**)error;
- (void)appendStyles:(NSArray*)styles;

@property (retain) NSMutableArray* styles;

@end
