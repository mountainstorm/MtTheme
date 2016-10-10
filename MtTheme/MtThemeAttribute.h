//
//  MtThemeAttribute.h
//  themeparser
//
//  Created by Richard Cooper on 21/09/2016.
//  Copyright © 2016 Mountainstorm. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/* XXX: other types we should support
Point - translates to a CGPoint property - CGPoint(0, 0)
Size - translates to a CGSize property
Rect - translates to a CGRect property
Range - translates to an NSRange property
*/

typedef enum _MtThemeAttributeType {
    kMtThemeAttributeTypeObject,
    kMtThemeAttributeTypeBoolean,
    
} MtThemeAttributeType;

@interface MtThemeAttribute : NSObject

+ (id)attribute;

- (NSString*)description;
- (NSString*)valueString;

- (BOOL)matchView:(NSView*)view;
- (void)applyToView:(NSView*)view;

@property (retain) NSMutableArray* name;
@property MtThemeAttributeType type;
@property (retain) id objectValue;
@property BOOL booleanValue;

@end
