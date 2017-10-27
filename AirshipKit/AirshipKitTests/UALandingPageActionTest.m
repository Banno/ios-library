/* Copyright 2017 Urban Airship and Contributors */

#import "UABaseTest.h"
#import "UALandingPageAction.h"
#import "UAURLProtocol.h"
#import "UAOverlayViewController.h"
#import "UAAction+Internal.h"
#import "UAirship.h"
#import "UAConfig.h"
#import "UAUtils.h"
#import "NSString+UAURLEncoding.h"

@interface UALandingPageActionTest : UABaseTest

@property (nonatomic, strong) id mockURLProtocol;
@property (nonatomic, strong) id mockOverlayViewController;
@property (nonatomic, strong) id mockAirship;
@property (nonatomic, strong) id mockConfig;
@property (nonatomic, strong) UALandingPageAction *action;


@end

@implementation UALandingPageActionTest

- (void)setUp {
    [super setUp];
    self.action = [[UALandingPageAction alloc] init];
    self.mockURLProtocol = [self mockForClass:[UAURLProtocol class]];
    self.mockOverlayViewController = [self mockForClass:[UAOverlayViewController class]];

    self.mockConfig = [self mockForClass:[UAConfig class]];
    self.mockAirship = [self mockForClass:[UAirship class]];
    [[[self.mockAirship stub] andReturn:self.mockAirship] shared];
    [[[self.mockAirship stub] andReturn:self.mockConfig] config];

    [[[self.mockConfig stub] andReturn:@"app-key"] appKey];
    [[[self.mockConfig stub] andReturn:kUAProductionLandingPageContentURL] landingPageContentURL];
    [[[self.mockConfig stub] andReturn:@"app-secret"] appSecret];
    [[[self.mockConfig stub] andReturnValue:OCMOCK_VALUE((NSUInteger)100)] cacheDiskSizeInMB];
}

- (void)tearDown {
    [self.mockOverlayViewController stopMocking];
    [self.mockURLProtocol stopMocking];
    [self.mockAirship stopMocking];
    [self.mockConfig stopMocking];
    [super tearDown];
}

/**
 * Test accepts arguments
 */
- (void)testAcceptsArguments {
    [self verifyAcceptsArgumentsWithValue:@"foo.urbanairship.com" shouldAccept:true];
    [self verifyAcceptsArgumentsWithValue:@"https://foo.urbanairship.com" shouldAccept:true];
    [self verifyAcceptsArgumentsWithValue:@"http://foo.urbanairship.com" shouldAccept:true];
    [self verifyAcceptsArgumentsWithValue:@"file://foo.urbanairship.com" shouldAccept:true];
    [self verifyAcceptsArgumentsWithValue:[NSURL URLWithString:@"https://foo.urbanairship.com"] shouldAccept:true];

    // Verify UA content ID urls
    [self verifyAcceptsArgumentsWithValue:@"u:content-id" shouldAccept:true];
}

/**
 * Test accepts arguments rejects argument values that are unable to parsed
 * as a URL
 */
- (void)testAcceptsArgumentsNo {
    [self verifyAcceptsArgumentsWithValue:nil shouldAccept:false];
    [self verifyAcceptsArgumentsWithValue:[[NSObject alloc] init] shouldAccept:false];
    [self verifyAcceptsArgumentsWithValue:@[] shouldAccept:false];
    [self verifyAcceptsArgumentsWithValue:@"u:" shouldAccept:false];
}

/**
 * Test perform in UASituationBackgroundPush
 */
- (void)testPerformInForeground {
    // Verify https is added to schemeless urls
    [self verifyPerformInForegroundWithValue:@"foo.urbanairship.com" expectedUrl:@"https://foo.urbanairship.com"];

    // Verify common scheme types
    [self verifyPerformInForegroundWithValue:@"http://foo.urbanairship.com" expectedUrl:@"http://foo.urbanairship.com"];
    [self verifyPerformInForegroundWithValue:@"https://foo.urbanairship.com" expectedUrl:@"https://foo.urbanairship.com"];
    [self verifyPerformInForegroundWithValue:[NSURL URLWithString:@"https://foo.urbanairship.com"] expectedUrl:@"https://foo.urbanairship.com"];
    [self verifyPerformInForegroundWithValue:@"file://foo.urbanairship.com" expectedUrl:@"file://foo.urbanairship.com"];

    // Verify content urls - https://dl.urbanairship.com/<app>/<id>
    // u:<id> where id is ascii85 encoded... so it needs to be url encoded
    [self verifyPerformInForegroundWithValue:@"u:<~@rH7,ASuTABk.~>"
                                 expectedUrl:@"https://dl.urbanairship.com/aaa/app-key/%3C~%40rH7,ASuTABk.~%3E"
                             expectedHeaders:@{@"Authorization": [UAUtils appAuthHeaderString]}];
}


/**
 * Helper method to verify perform in foreground situations
 */
- (void)commonVerifyPerformInForegroundWithValue:(id)value expectedUrl:(NSString *)expectedUrl expectedHeaders:(NSDictionary *)headers mockedViewController:(id)mockedViewController {
    NSArray *situations = @[[NSNumber numberWithInteger:UASituationWebViewInvocation],
                            [NSNumber numberWithInteger:UASituationForegroundPush],
                            [NSNumber numberWithInteger:UASituationLaunchedFromPush],
                            [NSNumber numberWithInteger:UASituationManualInvocation],
                            [NSNumber numberWithInteger:UASituationAutomation]];
    
    for (NSNumber *situationNumber in situations) {
        [[[mockedViewController expect] ignoringNonObjectArgs] showURL:[OCMArg checkWithBlock:^(id obj) {
            return (BOOL)([obj isKindOfClass:[NSURL class]] && [((NSURL *)obj).absoluteString isEqualToString:expectedUrl]);
        }] withHeaders:[OCMArg checkWithBlock:^(id obj) {
            return (BOOL) ([headers count] ? [headers isEqualToDictionary:obj] : [obj count] == 0);
        }] size:CGSizeZero aspectLock:false];

        UAActionArguments *args = [UAActionArguments argumentsWithValue:value withSituation:[situationNumber integerValue]];
        [self verifyPerformWithArgs:args withExpectedUrl:expectedUrl withExpectedFetchResult:UAActionFetchResultNewData mockedViewController:mockedViewController];
    }
}

- (void)verifyPerformInForegroundWithValue:(id)value expectedUrl:(NSString *)expectedUrl expectedHeaders:(NSDictionary *)headers {
    [self commonVerifyPerformInForegroundWithValue:value expectedUrl:expectedUrl expectedHeaders:headers mockedViewController:self.mockOverlayViewController];
}

/**
 * Helper method to verify perform in foreground situations with no expected headers
 */
- (void)verifyPerformInForegroundWithValue:(id)value expectedUrl:(NSString *)expectedUrl {
    [self verifyPerformInForegroundWithValue:value expectedUrl:expectedUrl expectedHeaders:nil];
}

/**
 * Helper method to verify perform
 */
- (void)verifyPerformWithArgs:(UAActionArguments *)args withExpectedUrl:(NSString *)expectedUrl withExpectedFetchResult:(UAActionFetchResult)fetchResult mockedViewController:(id)mockedViewController {

    __block BOOL finished = NO;

    [[self.mockURLProtocol expect] addCachableURL:[OCMArg checkWithBlock:^(id obj) {
        return (BOOL)([obj isKindOfClass:[NSURL class]] && [((NSURL *)obj).absoluteString isEqualToString:expectedUrl]);
    }]];

    [self.action performWithArguments:args completionHandler:^(UAActionResult *result) {
        finished = YES;
        XCTAssertEqual(result.fetchResult, fetchResult,
                       @"fetch result %ld should match expect result %ld", result.fetchResult, fetchResult);
    }];

    [self.mockURLProtocol verify];
    [mockedViewController verify];

    XCTAssertTrue(finished, @"action should have completed");
}

/**
 * Helper method to verify accepts arguments
 */
- (void)verifyAcceptsArgumentsWithValue:(id)value shouldAccept:(BOOL)shouldAccept {
    NSArray *situations = @[[NSNumber numberWithInteger:UASituationWebViewInvocation],
                                     [NSNumber numberWithInteger:UASituationForegroundPush],
                                     [NSNumber numberWithInteger:UASituationBackgroundPush],
                                     [NSNumber numberWithInteger:UASituationLaunchedFromPush],
                                     [NSNumber numberWithInteger:UASituationManualInvocation]];

    for (NSNumber *situationNumber in situations) {
        UAActionArguments *args = [UAActionArguments argumentsWithValue:value
                                                          withSituation:[situationNumber integerValue]];

        BOOL accepts = [self.action acceptsArguments:args];
        if (shouldAccept) {
            XCTAssertTrue(accepts, @"landing page action should accept value %@ in situation %@", value, situationNumber);
        } else {
            XCTAssertFalse(accepts, @"landing page action should not accept value %@ in situation %@", value, situationNumber);
        }
    }
}

@end
