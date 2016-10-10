//
//  MtTheme.m
//  themeparser
//
//  Created by Richard Cooper on 22/09/2016.
//  Copyright © 2016 Mountainstorm. All rights reserved.
//

#import "MtTheme.h"
#import "MtThemeStyle.h"
#import "MtThemeAttribute.h"

@implementation MtTheme

+ (MtTheme*)sharedTheme
{
    static dispatch_once_t once;
    static MtTheme* theme = nil;
    dispatch_once(&once, ^{
        theme = [[MtTheme alloc] init];
    });
    return theme;
}

+ (id)themeFromFile:(NSString*)path error:(MtThemeParseError**)error
{
    MtTheme* retval = nil;
    NSError* nsError = nil;
    NSString* theme = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&nsError];
    if (theme == nil) {
        *error = [MtThemeParseError error];
        (*error).type = kMtThemeParseErrorTypeNSError;
        (*error).nsError = nsError;
    } else {
        retval = [MtTheme themeFromString:theme error:error];
    }
    return retval;
}

+ (id)themeFromString:(NSString*)text error:(MtThemeParseError**)error
{
    MtTheme* retval = nil;
    MtTheme* theme = [[MtTheme alloc] init];
    if ([theme parseFromString:text error:error]) {
        retval = theme;
    }
    return retval;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.styles = [NSMutableArray array];
    }
    return self;
}

- (BOOL)parseFromString:(NSString*)text error:(MtThemeParseError**)error
{
    NSRegularExpression* reSelector = [NSRegularExpression regularExpressionWithPattern:@"^[_a-zA-Z]"
                                                                                options:0
                                                                                  error:nil];
    NSRegularExpression* reAttribute = [NSRegularExpression regularExpressionWithPattern:@"^    [_a-zA-Z]"
                                                                                 options:0
                                                                                   error:nil];
    NSRegularExpression* reIgnore = [NSRegularExpression regularExpressionWithPattern:@"(^[ \t]*#)|(^[ \t]*$)"
                                                                              options:0
                                                                                error:nil];
    
    // parse each line
    NSUInteger lineNo = 1;
    MtThemeStyle* curStyle = nil;
    
    // expecting:
    // 0x01 selector
    // 0x02 attribute
    // 0x04 empty line
    long expecting = 0x01 | 0x04;
    for (NSString* line in [text componentsSeparatedByString:@"\n"]) {
        NSRange r = NSMakeRange(0, line.length);
        NSTextCheckingResult* mSelector = [reSelector firstMatchInString:line options:0 range:r];
        NSTextCheckingResult* mAttribute = [reAttribute firstMatchInString:line options:0 range:r];
        NSTextCheckingResult* mIgnore = [reIgnore firstMatchInString:line options:0 range:r];
        if (mSelector) {
            // we found a selector
            if ((expecting & 0x01) != 0x01) {
                // not actually expecting this
                *error = [self failedExpectation:@"unexpected selector" expecting:expecting line:line lineNo:lineNo];
                break;
            }
        
            if (curStyle == nil) {
                curStyle = [MtThemeStyle style];
            }
            //NSLog(@"sel : %@", line);
            NSUInteger end = 0;
            if (![curStyle parseSelector:line end:&end error:error]) {
                (*error).lineNo = lineNo;
                (*error).line = line;
                break;
            }
            // check if the rest of the line conforms to a comment - or nothing
            if (![reIgnore firstMatchInString:[line substringFromIndex:end] options:0 range:NSMakeRange(0, line.length-end)]) {
                *error = [MtThemeParseError error];
                (*error).type = kMtThemeParseErrorTypeNSString;
                (*error).stringError = @"unexpected data after selector";
                (*error).line = line;
                (*error).lineNo = lineNo;
                (*error).columns = NSMakeRange(end, line.length-end);
                break;
            }
            expecting = 0x1 | 0x02; // selector or attribute
            
        } else if (mAttribute) {
            // found an attribute
            if ((expecting & 0x02) != 0x02) {
                *error = [self failedExpectation:@"unexpected attribute" expecting:expecting line:line lineNo:lineNo];
                break;
            }
            
            //NSLog(@"attr: %@", line);
            NSUInteger off = 4; // size of the indent - makes the errors look better
            NSUInteger end = 0;
            if (![curStyle parseAttribute:[line substringFromIndex:off] end:&end error:error]) {
                (*error).columns = NSMakeRange(off + (*error).columns.location, (*error).columns.length);
                (*error).lineNo = lineNo;
                (*error).line = line;
                break;
            }
            // check if the rest of the line conforms to a comment - or nothing
            if (![reIgnore firstMatchInString:[line substringFromIndex:off+end] options:0 range:NSMakeRange(0, line.length-end-off)]) {
                *error = [MtThemeParseError error];
                (*error).type = kMtThemeParseErrorTypeNSString;
                (*error).stringError = @"unexpected data after attribute";
                (*error).line = line;
                (*error).lineNo = lineNo;
                (*error).columns = NSMakeRange(off+end, line.length-end-off);
                break;
            }
            expecting = 0x2 | 0x04; // attribute or empty
        } else if (line.length == 0) {
            // empty line
            if ((expecting & 0x04) != 0x04) {
                *error = [self failedExpectation:@"unexpected newline" expecting:expecting line:line lineNo:lineNo];
                break;
            }
            // we've completed the style - save it
            if (curStyle) {
                [self.styles addObject:curStyle];
            }
            curStyle = nil;
            expecting = 0x01 | 0x04; // attribute or empty
        } else if (mIgnore) {
            // skip - line length 0 must come before this
        } else {
            *error = [self failedExpectation:@"unexpected line" expecting:expecting line:line lineNo:lineNo];
            break;
        }
        
        lineNo++;
    }
    
    if (expecting != (0x01 | 0x04) && *error == nil) {
        // we're still in an attribute
        *error = [self failedExpectation:@"unexpected end of file" expecting:expecting line:nil lineNo:lineNo];
    }
    return *error == nil;
}

- (MtThemeParseError*)failedExpectation:(NSString*)desc expecting:(long)expecting line:(NSString*)line lineNo:(NSUInteger)lineNo
{
    NSMutableArray* expected = [NSMutableArray array];
    if ((expecting & 0x01) == 0x01) {
        [expected addObject:@"selector"];
    }
    if ((expecting & 0x02) == 0x02) {
        [expected addObject:@"attribute"];
    }
    if ((expecting & 0x04) == 0x04) {
        [expected addObject:@"newline"];
    }

    MtThemeParseError* retval = [MtThemeParseError error];
    retval.type = kMtThemeParseErrorTypeNSString;
    retval.stringError = [NSString stringWithFormat:@"%@; expecting [%@]", desc, [expected componentsJoinedByString:@", "]];
    retval.line = line;
    retval.lineNo = lineNo;
    retval.columns = NSMakeRange(0, line.length);
    return retval;
}

- (void)updateWindow:(NSWindow*)window
{
    [self updateView:window.contentView];
}

- (void)updateViewAndSubviews:(NSView*)view
{
    for (NSView* child in view.subviews) {
        [self updateViewAndSubviews:child];
    }

    // walk style and create a dictionary of the style which applies to view
    [self updateView:view];
}

- (void)updateView:(NSView*)view
{
    [self applyStyles:[self matchView:view] toView:view];
}

- (NSDictionary*)matchView:(NSView*)view
{
    NSMutableDictionary* retval = [NSMutableDictionary dictionary];
    for (MtThemeStyle* style in _styles) {
        if ([style matchView:view]) {
            [retval addEntriesFromDictionary:style.attributes];
        }
    }
    return retval;
}

- (void)applyStyles:(NSDictionary*)styles toView:(NSView*)view
{
    for (id key in styles) {
        MtThemeAttribute* attr = [styles objectForKey:key];
        [attr applyToView:view];
    }
}

- (BOOL)appendFromFile:(NSString*)path error:(MtThemeParseError**)error
{
    BOOL retval = NO;
    NSError* nsError = nil;
    NSString* theme = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&nsError];
    if (theme == nil) {
        *error = [MtThemeParseError error];
        (*error).type = kMtThemeParseErrorTypeNSError;
        (*error).nsError = nsError;
    } else {
        retval = [self appendFromString:theme error:error];
    }
    return retval;
}

- (BOOL)appendFromString:(NSString*)text error:(MtThemeParseError**)error
{
    BOOL retval = NO;
    if ([self parseFromString:text error:error]) {
        retval = YES;
    }
    return retval;
}

- (void)appendStyles:(NSArray*)styles
{
    [self.styles addObjectsFromArray:styles];
}

@end
