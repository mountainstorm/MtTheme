//
//  MtThemeParseError.m
//  themeparser
//
//  Created by Richard Cooper on 22/09/2016.
//  Copyright © 2016 Mountainstorm. All rights reserved.
//

#import "MtThemeParseError.h"

@implementation MtThemeParseError

+ (id)error
{
    return [[MtThemeParseError alloc] init];
}

- (NSString*)description
{
    NSString* retval = nil;
    switch (self.type) {
        case kMtThemeParseErrorTypeNSError:
            retval = [self.nsError description];
            break;
        case kMtThemeParseErrorTypeNSString:
            retval = self.stringError;
            break;
        default:
            break;
    }
    if (self.line) {
        retval = [NSString stringWithFormat:@"line %lu: %@", self.lineNo, retval];
    }
    return retval;
}

- (NSString*)marker
{
    NSMutableString* marker = [NSMutableString string];
    for (NSUInteger i = 0; i < self.line.length; i++) {
        if (i < self.columns.location) {
            [marker appendString:@"~"];
        } else if (i < (self.columns.location + self.columns.length)) {
            [marker appendString:@"^"];
        }
    }
    return marker;
}

@end
