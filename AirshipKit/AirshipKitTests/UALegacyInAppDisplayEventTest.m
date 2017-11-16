/* Copyright 2017 Urban Airship and Contributors */

#import "UABaseTest.h"
#import "UAAnalytics.h"
#import "UAirship.h"
#import "UALegacyInAppDisplayEvent+Internal.h"
#import "UALegacyInAppMessage.h"

@interface UALegacyInAppDisplayEventTest : UABaseTest
@property (nonatomic, strong) id analytics;
@property (nonatomic, strong) id airship;
@end

@implementation UALegacyInAppDisplayEventTest

- (void)setUp {
    [super setUp];

    self.analytics = [self mockForClass:[UAAnalytics class]];
    self.airship = [self mockForClass:[UAirship class]];

    [[[self.airship stub] andReturn:self.airship] shared];
    [[[self.airship stub] andReturn:self.analytics] analytics];
}

- (void)tearDown {
    [self.analytics stopMocking];
    [self.airship stopMocking];
    [super tearDown];
}

/**
 * Test events data.
 */
- (void)testValidEvent {

    UALegacyInAppMessage *message = [[UALegacyInAppMessage alloc] init];
    message.identifier = [NSUUID UUID].UUIDString;
    [[[self.analytics stub] andReturn:[NSUUID UUID].UUIDString] conversionSendID];
    [[[self.analytics stub] andReturn:@"base64metadataString"] conversionPushMetadata];


    NSDictionary *expectedData = @{ @"id": message.identifier,
                                    @"conversion_send_id": [self.analytics conversionSendID],
                                    @"conversion_metadata": [self.analytics conversionPushMetadata]};



    UALegacyInAppDisplayEvent *event = [UALegacyInAppDisplayEvent eventWithMessage:message];
    XCTAssertEqualObjects(event.data, expectedData, @"Event data is unexpected.");
    XCTAssertEqualObjects(event.eventType, @"in_app_display", @"Event type is unexpected.");
    XCTAssertNotNil(event.eventID, @"Event should have an ID");
    XCTAssertTrue([event isValid], @"Event should be valid if it has a in-app message ID.");
}

/**
 * Test event is invalid if it is missing the in-app message ID.
 */
- (void)testInvalidData {
    UALegacyInAppMessage *message = [[UALegacyInAppMessage alloc] init];

    [[[self.analytics stub] andReturn:[NSUUID UUID].UUIDString] conversionSendID];

    UALegacyInAppDisplayEvent *event = [UALegacyInAppDisplayEvent eventWithMessage:message];
    XCTAssertFalse([event isValid], @"Event should be valid if it has a in-app message ID.");
}

@end
