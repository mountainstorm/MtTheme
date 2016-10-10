//
//  MtThemeParseError.h
//  themeparser
//
//  Created by Richard Cooper on 22/09/2016.
//  Copyright © 2016 Mountainstorm. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _MtThemeParseErrorType {
    kMtThemeParseErrorTypeNSError,
    kMtThemeParseErrorTypeNSString
} MtThemeParseErrorType;

@interface MtThemeParseError : NSObject

+ (id)error;
- (NSString*)marker;

@property MtThemeParseErrorType type;
@property NSUInteger lineNo;
@property NSRange columns;
@property (retain) NSString* line;
@property (retain) NSString* stringError;
@property (retain) NSError* nsError;

@end
