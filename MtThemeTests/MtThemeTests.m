//
//  MtThemeTests.m
//  MtThemeTests
//
//  Created by cooper on 09/10/2016.
//  Copyright © 2016 cooper. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MtTheme/MtTheme.h>
#import <MtTheme/MtThemeStyle.h>


@interface MtThemeTests : XCTestCase
{
    NSBundle* _bundle;
}
@end

@implementation MtThemeTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    MtThemeParseError* error = nil;
    _bundle = [NSBundle bundleForClass:[self class]];
    if ([MtTheme.sharedTheme appendFromFile:[_bundle pathForResource:@"test" ofType:@"mttheme"]
                                      error:&error] == NO) {
        if (error.line != nil) {
            NSLog(@"%@", error.line);
            NSLog(@"%@", error.marker);
        }
        NSLog(@"%@", error);
    } else {
        
    }
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
