/* Copyright 2017 Urban Airship and Contributors */

#import "UABaseTest.h"

#import "UAirship+Internal.h"
#import "UAPreferenceDataStore+Internal.h"
#import "UAInAppMessage+Internal.h"
#import "UAInAppMessageBannerDisplayContent+Internal.h"
#import "UAInAppMessageAudience+Internal.h"

@interface UAInAppMessageTest : UABaseTest
@property(nonatomic, strong) NSDictionary *json;
@end

@implementation UAInAppMessageTest

- (void)testJSON {
    // setup
    NSDictionary *originalJSON = @{
                  @"message_id": @"blah",
                  @"display": @{@"body": @{
                                        @"text":@"the body"
                                        },
                                },
                  @"display_type": UAInAppMessageDisplayTypeBannerValue,
                  @"extras": @{@"foo":@"baz", @"baz":@"foo"},
                  @"audience": @{@"new_user" : @YES},
                  @"actions": @{@"cool":@"story"}
                  };
    
    // test
    NSError *error;
    UAInAppMessage *messageFromOriginalJSON = [UAInAppMessage messageWithJSON:originalJSON error:&error];
    XCTAssertNotNil(messageFromOriginalJSON);
    XCTAssertNil(error);
    
    XCTAssertEqualObjects(@"blah",messageFromOriginalJSON.identifier);
    XCTAssertEqualObjects(@"the body",((UAInAppMessageBannerDisplayContent *)(messageFromOriginalJSON.displayContent)).body.text);
    XCTAssertEqual(UAInAppMessageDisplayTypeBanner, messageFromOriginalJSON.displayType);
    XCTAssertEqualObjects(@"baz",messageFromOriginalJSON.extras[@"foo"]);
    XCTAssertEqualObjects(@"foo",messageFromOriginalJSON.extras[@"baz"]);
    XCTAssertEqualObjects(@"story",messageFromOriginalJSON.actions[@"cool"]);
    XCTAssertEqualObjects(@YES, messageFromOriginalJSON.audience.isNewUser);

    NSDictionary *toJSON = [messageFromOriginalJSON toJSON];
    XCTAssertNotNil(toJSON);
    UAInAppMessage *messageFromToJSON = [UAInAppMessage messageWithJSON:toJSON error:&error];
    XCTAssertNotNil(messageFromToJSON);
    XCTAssertNil(error);

    XCTAssertEqualObjects(messageFromOriginalJSON, messageFromToJSON);
}

@end
