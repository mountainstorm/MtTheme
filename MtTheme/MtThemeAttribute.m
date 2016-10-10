//
//  MtThemeAttribute.m
//  themeparser
//
//  Created by Richard Cooper on 21/09/2016.
//  Copyright © 2016 Mountainstorm. All rights reserved.
//

#import "MtThemeAttribute.h"

@implementation MtThemeAttribute

+ (id)attribute
{
    return [[MtThemeAttribute alloc] init];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.name = [NSMutableArray array];
    }
    return self;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@=%@", [self.name componentsJoinedByString:@"."], [self valueString]];
}

- (NSString*)valueString
{
    NSString* retval = nil;
    switch (_type) {
        case kMtThemeAttributeTypeObject:
            retval = [_objectValue description];
            if ([_objectValue isKindOfClass:[NSString class]]) {
                NSMutableString* escaped = [NSMutableString stringWithString:retval];
                // XXX: this isn't quite right
                [escaped replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, escaped.length)];
                [escaped replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, escaped.length)];
                [escaped replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, escaped.length)];
                retval = [NSString stringWithFormat:@"\"%@\"", escaped];
            }
            break;
            
        case kMtThemeAttributeTypeBoolean:
            retval = [NSString stringWithFormat:@"%@", _booleanValue ? @"YES": @"NO"];
            break;
            
        default:
            break;
    }
    return retval;
}

- (BOOL)matchView:(NSView*)view
{
    BOOL retval = NO;
    // check if the view matches this attribute
    id obj = [self getObjectForView:view];
    if (obj) {
        SEL sel = NSSelectorFromString([_name objectAtIndex:_name.count-1]);
        IMP imp = [obj methodForSelector:sel];
        if (sel != nil && imp != nil && [obj respondsToSelector:sel]) {
            id (*funcObj)(id, SEL) = (void *)imp;
            BOOL (*funcBOOL)(id, SEL) = (void *)imp;
            switch (_type) {
                case kMtThemeAttributeTypeObject:
                    if ([funcObj(obj, sel) isEqual:_objectValue]) {
                        retval = YES;
                    }
                    break;
                    
                case kMtThemeAttributeTypeBoolean:
                    if (funcBOOL(obj, sel) == _booleanValue) {
                        retval = YES;
                    }
                    break;
                    
                default:
                    break;
            }
        }
    }
    return retval;
}

- (id)getObjectForView:(NSView*)view
{
    id retval = nil;
    if (_name.count > 0) {
        retval = view;
        if (_name.count > 1) {
            for (NSString* component in [_name subarrayWithRange:NSMakeRange(0, _name.count-1)]) {
                SEL sel = NSSelectorFromString(component);
                IMP imp = [retval methodForSelector:sel];
                if (sel == nil || imp == nil || [retval respondsToSelector:sel] == NO) {
                    retval = nil;
                    break;
                }
                id (*func)(id, SEL) = (void *)imp;
                retval = func(retval, sel);
                if (retval == nil) {
                    break;
                }
            }
        }
    }
    return retval;
}

- (void)applyToView:(NSView*)view
{
    id obj = [self getObjectForView:view];
    if (obj) {
        NSString* name = [_name objectAtIndex:_name.count-1];
        NSString* first = [name substringToIndex:1];
        NSString* attr = [name substringFromIndex:1];
        NSString* isPostfix = [name substringWithRange:NSMakeRange(2, 1)];
        NSString* selectorName = [NSString stringWithFormat:@"set%@%@:", [first uppercaseString], attr];
        if (   [[name substringToIndex:2] isEqualToString:@"is"]
            && [[isPostfix uppercaseString] isEqualToString:isPostfix]) {
            // it's an "is*" property - take off the is
            selectorName = [NSString stringWithFormat:@"set%@:", [name substringFromIndex:2]];
        }
        SEL sel = NSSelectorFromString(selectorName);
        IMP imp = [obj methodForSelector:sel];
        if (sel != nil && imp != nil && [obj respondsToSelector:sel]) {
            void (*funcObj)(id, SEL, id) = (void *)imp;
            void (*funcBOOL)(id, SEL, BOOL) = (void *)imp;
            switch (_type) {
                case kMtThemeAttributeTypeObject:
                    funcObj(obj, sel, _objectValue);
                    break;
                    
                case kMtThemeAttributeTypeBoolean:
                    funcBOOL(obj, sel, _booleanValue);
                    break;
                    
                default:
                    break;
            }
        }
    }
}

@end


