//
//  MtThemeStyle.m
//  themeparser
//
//  Created by Richard Cooper on 22/09/2016.
//  Copyright © 2016 Mountainstorm. All rights reserved.
//

#import "MtThemeStyle.h"
#import "MtThemeSelector.h"
#import "MtThemeSelectorComponent.h"
#import "MtThemeAttribute.h"

@implementation MtThemeStyle

+ (id)style
{
    return [[MtThemeStyle alloc] init];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.selectors = [NSMutableArray array];
        self.attributes = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString*)description
{
    NSMutableString* retval = [NSMutableString string];
    for (MtThemeSelector* selector in self.selectors) {
        [retval appendFormat:@"%@\n", [selector description]];
    }
    for (MtThemeAttribute* attribute in self.attributes.allValues) {
        [retval appendFormat:@"    %@\n", [attribute description]];
    }
    return retval;
}

- (BOOL)parseSelector:(NSString*)line end:(NSUInteger*)end error:(MtThemeParseError**)error
{
    NSMutableCharacterSet* nameSet = [NSMutableCharacterSet alphanumericCharacterSet];
    [nameSet addCharactersInString:@"_"];
    NSMutableCharacterSet* firstSet = [NSMutableCharacterSet letterCharacterSet];
    [firstSet addCharactersInString:@"_"];

    NSScanner* scanner = [NSScanner scannerWithString:line];
    scanner.charactersToBeSkipped = nil;

    MtThemeSelector* selector = [MtThemeSelector selector];
    MtThemeSelectorComponent* component = nil;
    
    BOOL firstName = YES;
    NSString* className = nil;
    while (!scanner.atEnd) {
        if (!firstName) {
            // should have a '.'
            unichar next = [line characterAtIndex:scanner.scanLocation];
            if (next != '.') {
                // dont error - assume is whitespace/comment etc so just stop
                break;
            }
            scanner.scanLocation++;
        }

        // we always need one name or a name after a '.'
        if (![scanner scanCharactersFromSet:nameSet intoString:&className]) {
            *error = [MtThemeParseError error];
            (*error).type = kMtThemeParseErrorTypeNSString;
            (*error).stringError = @"invalid class name";
            (*error).columns = NSMakeRange(scanner.scanLocation, scanner.string.length-scanner.scanLocation);
            break;
        }
        unichar first = [className characterAtIndex:0];
        if (![firstSet characterIsMember:first]) {
            *error = [MtThemeParseError error];
            (*error).type = kMtThemeParseErrorTypeNSString;
            (*error).stringError = @"invalid class name first character";
            (*error).columns = NSMakeRange(scanner.scanLocation-className.length, 1);
            break;
        }
        component = [MtThemeSelectorComponent component];
        component.classObj = NSClassFromString(className);
        if (!component.classObj) {
            *error = [MtThemeParseError error];
            (*error).type = kMtThemeParseErrorTypeNSString;
            (*error).stringError = @"invalid class name";
            (*error).columns = NSMakeRange(scanner.scanLocation-className.length, 1);
            break;
        }
        // do we have attributes
        if (scanner.atEnd) {
            break;
        }
        unichar next = [line characterAtIndex:scanner.scanLocation];
        if (next == L'>') {
            // derrived class check
            component.isKindOfClass = YES;
            scanner.scanLocation++; // skip '>'
            next = [line characterAtIndex:scanner.scanLocation];
        }
        if (scanner.atEnd) {
            break;
        }
        if (next == L'[') {
            scanner.scanLocation++; // skip '['
            NSUInteger end = 0;
            component.attributes = [self parseInlineAttributes:[line substringFromIndex:scanner.scanLocation] end:&end error:error];
            if (component.attributes == nil) {
                (*error).columns = NSMakeRange(scanner.scanLocation + (*error).columns.location, (*error).columns.length);
                break;
            }
            scanner.scanLocation += end;
        }
        [selector.components insertObject:component atIndex:0];
        component = nil;
        firstName = NO;
    }
    if (*error == nil) {
        if (component) {
            [selector.components insertObject:component atIndex:0];
        }
        [self.selectors addObject:selector];
        *end = scanner.scanLocation;
    }
    return *error == nil;
}

- (NSMutableDictionary*)parseInlineAttributes:(NSString*)line end:(NSUInteger*)end error:(MtThemeParseError**)error
{
    NSMutableDictionary* retval = nil;
    
    NSScanner* scanner = [NSScanner scannerWithString:line];
    scanner.charactersToBeSkipped = nil;
    
    MtThemeStyle* parser = [MtThemeStyle style];
    while (!scanner.atEnd) {
        NSUInteger attrEnd = 0;
        if (![parser parseAttribute:[line substringFromIndex:scanner.scanLocation] end:&attrEnd error:error]) {
            (*error).columns = NSMakeRange(scanner.scanLocation + (*error).columns.location, (*error).columns.length);
            break;
        } else {
            // we scanned an attribute - should now have a closing ']' or a ','
            scanner.scanLocation += attrEnd;
            [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
            if (scanner.atEnd) {
                *error = [MtThemeParseError error];
                (*error).type = kMtThemeParseErrorTypeNSString;
                (*error).stringError = @"unexpected end of line, expecting ']' or ','";
                (*error).columns = NSMakeRange(line.length, 0);
                break;
            } else {
                unichar next = [line characterAtIndex:scanner.scanLocation];
                if (next == ']') {
                    scanner.scanLocation++; // skip ']'
                    retval = parser.attributes;
                    break; // done
                } else if (next == ',') {
                    scanner.scanLocation++; // skip ','
                    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
                } else {
                    *error = [MtThemeParseError error];
                    (*error).type = kMtThemeParseErrorTypeNSString;
                    (*error).stringError = @"unexpected end attribute, expecting ']' or ','";
                    (*error).columns = NSMakeRange(scanner.scanLocation, 0);
                    break;
                }
            }
        }
    }
    
    if (retval == nil && *error == nil && scanner.atEnd) {
        *error = [MtThemeParseError error];
        (*error).type = kMtThemeParseErrorTypeNSString;
        (*error).stringError = @"unexpected end of line, expecting an attribute";
        (*error).columns = NSMakeRange(line.length, 0);
    }
    
    if (retval) {
        *end = scanner.scanLocation;
    }
    return retval;
}

- (BOOL)parseAttribute:(NSString*)line end:(NSUInteger*)end error:(MtThemeParseError**)error
{
    MtThemeAttribute* attribute = [MtThemeAttribute attribute];
    
    NSMutableCharacterSet* nameSet = [NSMutableCharacterSet alphanumericCharacterSet];
    [nameSet addCharactersInString:@"_"];
    NSMutableCharacterSet* firstSet = [NSMutableCharacterSet letterCharacterSet];
    [firstSet addCharactersInString:@"_"];
    NSCharacterSet* dotSet = [NSCharacterSet characterSetWithCharactersInString:@"."];
    NSCharacterSet* equalSet = [NSCharacterSet characterSetWithCharactersInString:@"="];
    
    NSScanner* scanner = [NSScanner scannerWithString:line];
    scanner.charactersToBeSkipped = nil;
    
    // skip leading ws
    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
    
    // read name components
    NSString* nameComponent = nil;
    while ([scanner scanCharactersFromSet:nameSet intoString:&nameComponent]) {
        unichar first = [nameComponent characterAtIndex:0];
        if (![firstSet characterIsMember:first]) {
            *error = [MtThemeParseError error];
            (*error).type = kMtThemeParseErrorTypeNSString;
            (*error).stringError = @"invalid name component first character";
            (*error).columns = NSMakeRange(scanner.scanLocation-nameComponent.length, 1);
            break;
        }
        [attribute.name addObject:nameComponent];
        if (![scanner scanCharactersFromSet:dotSet intoString:nil]) {
            break; // not a dot seperator - perhaps we've hit the end of the name
        }
    }
    if (*error == nil) {
        if (attribute.name.count == 0) {
            *error = [MtThemeParseError error];
            (*error).type = kMtThemeParseErrorTypeNSString;
            (*error).stringError = @"unexpected character when looking for name component";
            (*error).columns = NSMakeRange(scanner.scanLocation, 1);
        } else {
            // skip ws between name and '='
            [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
            // scan '='
            if (![scanner scanCharactersFromSet:equalSet intoString:nil]) {
                *error = [MtThemeParseError error];
                (*error).type = kMtThemeParseErrorTypeNSString;
                if (scanner.atEnd) {
                    (*error).stringError = @"unexpected end of line when for '='";
                    (*error).columns = NSMakeRange(line.length, 0);
                } else {
                    (*error).stringError = @"unexpected character when looking for '='";
                    (*error).columns = NSMakeRange(scanner.scanLocation, 1);
                }
            } else {
                // skip ws between '=' and value
                [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
                [self parseAttributeValue:scanner attribute:attribute error:error];
            }
        }
    }
    
    if (*error == nil) {
        // success
        [self.attributes setObject:attribute forKey:[attribute.name componentsJoinedByString:@"."]];
        *end = scanner.scanLocation;
    }
    return *error == nil;
}

- (BOOL)parseAttributeValue:(NSScanner*)scanner attribute:(MtThemeAttribute*)attribute error:(MtThemeParseError**)error
{
    NSRegularExpression* reHex = [NSRegularExpression regularExpressionWithPattern:@"^0x[a-fA-F0-9]+"
                                                                           options:0
                                                                             error:nil];
    NSRegularExpression* reFloat = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]+\\.[0-9]+"
                                                                             options:0
                                                                               error:nil];
    NSRegularExpression* reDec = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]+"
                                                                           options:0
                                                                             error:nil];
    NSRegularExpression* reBoolean = [NSRegularExpression regularExpressionWithPattern:@"^(YES)|(NO)"
                                                                               options:0
                                                                                 error:nil];
    NSRegularExpression* reString = [NSRegularExpression regularExpressionWithPattern:@"^\\\""
                                                                              options:0
                                                                                error:nil];
    NSRegularExpression* reColor = [NSRegularExpression regularExpressionWithPattern:@"^#[a-zA-z0-9]+"
                                                                              options:0
                                                                                error:nil];
    NSRange r = NSMakeRange(scanner.scanLocation, scanner.string.length-scanner.scanLocation);
    NSTextCheckingResult* mHex = [reHex firstMatchInString:scanner.string
                                                   options:0
                                                     range:r];
    NSTextCheckingResult* mFloat = [reFloat firstMatchInString:scanner.string
                                                       options:0
                                                         range:r];
    NSTextCheckingResult* mDec = [reDec firstMatchInString:scanner.string
                                                   options:0
                                                     range:r];
    NSTextCheckingResult* mBoolean = [reBoolean firstMatchInString:scanner.string
                                                           options:0
                                                             range:r];
    NSTextCheckingResult* mString = [reString firstMatchInString:scanner.string
                                                         options:0
                                                           range:r];
    NSTextCheckingResult* mColor = [reColor firstMatchInString:scanner.string
                                                         options:0
                                                           range:r];
    if (mHex) {
        unsigned long long value = 0;
        [scanner scanHexLongLong:&value];
        attribute.type = kMtThemeAttributeTypeObject;
        attribute.objectValue = [NSNumber numberWithUnsignedLongLong:value];
    } else if (mFloat) {
        float value = 0.0;
        [scanner scanFloat:&value];
        attribute.type = kMtThemeAttributeTypeObject;
        attribute.objectValue = [NSNumber numberWithFloat:value];
    } else if (mDec) {
        long long value = 0;
        [scanner scanLongLong:&value];
        attribute.type = kMtThemeAttributeTypeObject;
        attribute.objectValue = [NSNumber numberWithLongLong:value];
    } else if (mBoolean) {
        attribute.type = kMtThemeAttributeTypeBoolean;
        NSString* boolean = [scanner.string substringWithRange:[mBoolean range]];
        attribute.booleanValue = [boolean isEqualToString:@"YES"] ? YES: NO;
        scanner.scanLocation += boolean.length;
    } else if (mString) {
        // string
        scanner.scanLocation++; // skip initial "
        NSMutableString* value = [NSMutableString string];
        NSCharacterSet* stop = [NSCharacterSet characterSetWithCharactersInString:@"\\\""];
        
        NSString* str = nil;
        while (YES) {
            if ([scanner scanUpToCharactersFromSet:stop intoString:&str]) {
                [value appendString:str];
            } else {
                unichar c = [scanner.string characterAtIndex:scanner.scanLocation];
                if (c == L'\\') {
                    scanner.scanLocation++; // skip escape
                    c = [scanner.string characterAtIndex:scanner.scanLocation];
                    if (c == L'n') {
                        [value appendString:@"\n"];
                    } else if (c == L'\\') {
                        [value appendString:@"\\"];
                    } else if (c == L'"') {
                        [value appendString:@"\""];
                    } else {
                        *error = [MtThemeParseError error];
                        (*error).type = kMtThemeParseErrorTypeNSString;
                        (*error).stringError = [NSString stringWithFormat:@"unexpected escape char"];
                        (*error).columns = NSMakeRange(scanner.scanLocation, 1);
                        break;
                    }
                    scanner.scanLocation++; // skip escaped
                } else {
                    scanner.scanLocation++; // skip final "
                    break; // done
                }
            }
        }
        attribute.type = kMtThemeAttributeTypeObject;
        attribute.objectValue = value;
    } else if (mColor) {
        // color value in hex
        scanner.scanLocation++; // skip the '#'
        unsigned int colorCode = 0;
        [scanner scanHexInt:&colorCode];
        attribute.objectValue = [NSColor colorWithDeviceRed:((colorCode >> 16) & 0xFF) / 255.0
                                                      green:((colorCode >> 8) & 0xFF) / 255.0
                                                       blue:((colorCode) & 0xFF) / 255.0
                                                      alpha:1.0];
    } else {
        *error = [MtThemeParseError error];
        (*error).type = kMtThemeParseErrorTypeNSString;
        (*error).stringError = [NSString stringWithFormat:@"invalid attribute type"];
        (*error).columns = NSMakeRange(scanner.scanLocation, scanner.string.length-scanner.scanLocation);
    }
    return *error == nil;
}

- (BOOL)matchView:(NSView*)view
{
    BOOL retval = NO;
    for (MtThemeSelector* selector in _selectors) {
        if ([selector matchView:view]) {
            retval = YES;
            break;
        }
    }
    return retval;
}

@end
