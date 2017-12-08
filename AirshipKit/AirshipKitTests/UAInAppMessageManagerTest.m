/* Copyright 2017 Urban Airship and Contributors */

#import "UABaseTest.h"

#import "UAirship+Internal.h"
#import "UAInAppMessageAdapterProtocol.h"
#import "UAInAppMessageManager+Internal.h"
#import "UASchedule+Internal.h"
#import "UAPreferenceDataStore+Internal.h"
#import "UARemoteDataManager+Internal.h"

@interface UAInAppMessageManagerTest : UABaseTest
@property(nonatomic, strong) UAInAppMessageManager *manager;
@property(nonatomic, strong) id mockAdapter;
@property(nonatomic, strong) id mockAutomationEngine;
@property(nonatomic, strong) UAInAppMessageScheduleInfo *scheduleInfo;
@property (nonatomic, strong) UAPreferenceDataStore *dataStore;

@end

@implementation UAInAppMessageManagerTest

- (void)setUp {
    [super setUp];

    self.mockAdapter = [self mockForProtocol:@protocol(UAInAppMessageAdapterProtocol)];
    self.mockAutomationEngine = [self mockForClass:[UAAutomationEngine class]];
    self.dataStore = [UAPreferenceDataStore preferenceDataStoreWithKeyPrefix:@"UAInAppMessageManagerTest."];
    [self.dataStore removeAll];
    self.manager = [UAInAppMessageManager managerWithAutomationEngine:self.mockAutomationEngine
                                                    remoteDataManager:[self mockForClass:[UARemoteDataManager class]]
                                                            dataStore:self.dataStore];

    self.scheduleInfo = [UAInAppMessageScheduleInfo inAppMessageScheduleInfoWithBuilderBlock:^(UAInAppMessageScheduleInfoBuilder * _Nonnull builder) {
        UAInAppMessage *message = [UAInAppMessage messageWithBuilderBlock:^(UAInAppMessageBuilder * _Nonnull builder) {
            builder.identifier = @"test identifier";
            builder.displayType = @"banner";
        }];

        builder.message = message;
    }];
}

- (void)tearDown {
    [self.mockAdapter stopMocking];

    [super tearDown];
}

- (void)testIsScheduleReady {
    // Set factory for banner type
    UA_WEAKIFY(self)
    [self.manager setFactoryBlock:^id<UAInAppMessageAdapterProtocol> _Nonnull(NSString *displayType) {
        UA_STRONGIFY(self)
        return self.mockAdapter;
    } forDisplayType:@"banner"];

    [[[self.mockAdapter expect] andDo:^(NSInvocation *invocation) {
        void (^prepareBlock)(void);
        [invocation getArgument:&prepareBlock atIndex:2];

        // Expect schedule conditions changed when prepare completes/prep block runs
        [[self.mockAutomationEngine expect] scheduleConditionsChanged];

        prepareBlock();

    }] prepare:OCMOCK_ANY];

    UASchedule *schedule = [UASchedule scheduleWithIdentifier:@"test IAM schedule" info:self.scheduleInfo];
    XCTAssertFalse([self.manager isScheduleReadyToExecute:schedule]);

    [self.mockAdapter verify];
    [self.mockAutomationEngine verify];
}

- (void)testIsScheduleReadyNoFactorySet {
    [[self.mockAdapter reject] prepare:OCMOCK_ANY];

    UASchedule *schedule = [UASchedule scheduleWithIdentifier:@"test IAM schedule" info:self.scheduleInfo];
    XCTAssertFalse([self.manager isScheduleReadyToExecute:schedule]);

    [self.mockAutomationEngine verify];
    [self.mockAdapter verify];
}

- (void)testExecuteSchedule {
    UASchedule *testSchedule = [UASchedule scheduleWithIdentifier:@"expected_id" info:self.scheduleInfo];

    //Set factory block with banner display type
    UA_WEAKIFY(self)
    [self.manager setFactoryBlock:^id<UAInAppMessageAdapterProtocol> _Nonnull(NSString *displayType) {
        UA_STRONGIFY(self)
        return self.mockAdapter;
    } forDisplayType:@"banner"];

    //Check Schedule to set current schedule ID
    [self.manager isScheduleReadyToExecute:testSchedule];

    XCTestExpectation *displayBlockCalled = [self expectationWithDescription:@"display block should be called"];

    [[[self.mockAdapter expect] andDo:^(NSInvocation *invocation) {
        void (^displayBlock)(void);
        [invocation getArgument:&displayBlock atIndex:2];

        displayBlock();

        [displayBlockCalled fulfill];
    }] display:OCMOCK_ANY];

    __block BOOL executeCompletionCalled = NO;

    // Call to executeSchedule should execute display block
    [self.manager executeSchedule:testSchedule completionHandler:^{
        executeCompletionCalled = YES;
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];

    // Ensure the delegate calls the execute completion block
    XCTAssertTrue(executeCompletionCalled);
    [self.mockAdapter verify];
}

- (void)testDisplayLock {
    UASchedule *testSchedule = [UASchedule scheduleWithIdentifier:@"expected_id" info:self.scheduleInfo];

    //Set factory block with banner display type
    UA_WEAKIFY(self)
    [self.manager setFactoryBlock:^id<UAInAppMessageAdapterProtocol> _Nonnull(NSString *displayType) {
        UA_STRONGIFY(self)
        return self.mockAdapter;
    } forDisplayType:@"banner"];

    //Check Schedule to set current schedule ID
    XCTAssertFalse([self.manager isScheduleReadyToExecute:testSchedule]);

    // Shorten the display interval to 1 second
    self.manager.displayInterval = 1;

    XCTestExpectation *displayBlockCalled = [self expectationWithDescription:@"display block should be called"];

    [[[self.mockAdapter expect] andDo:^(NSInvocation *invocation) {
        void (^displayBlock)(void);
        [invocation getArgument:&displayBlock atIndex:2];

        displayBlock();

        // Schedule should not be ready immediately after display (2nd call to isScheduleReady)
        XCTAssertFalse([self.manager isScheduleReadyToExecute:testSchedule]);

        [displayBlockCalled fulfill];
    }] display:OCMOCK_ANY];

    // Call to executeSchedule should execute display block and lock display
    [self.manager executeSchedule:testSchedule completionHandler:^{}];

    [self waitForExpectationsWithTimeout:5 handler:nil];

    // Expect update to schedule conditions changed on unlock
    [[self.mockAutomationEngine expect] scheduleConditionsChanged];

    // Wait for unlock interval
    XCTestExpectation *unlockInterval = [self expectationWithDescription:@"wait interval"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.manager.displayInterval+1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [unlockInterval fulfill];
    });
    [self waitForExpectationsWithTimeout:5 handler:nil];

    [[[self.mockAdapter expect] andDo:^(NSInvocation *invocation) {
        void (^prepareBlock)(void);
        [invocation getArgument:&prepareBlock atIndex:2];

        // Expect schedule conditions changed when prepare completes/prep block runs
        [[self.mockAutomationEngine expect] scheduleConditionsChanged];

        prepareBlock();

        // Schedule should be ready after prep block (4th call to isScheduleReady)
        XCTAssertTrue([self.manager isScheduleReadyToExecute:testSchedule]);
    }] prepare:OCMOCK_ANY];

    // Schedule should be return false but prepare once screen unlocks (3rd call to isScheduleReady)
    XCTAssertFalse([self.manager isScheduleReadyToExecute:testSchedule]);

    [self.mockAdapter verify];
    [self.mockAutomationEngine verify];
}

- (void)testCancelMessage {
    UAInAppMessageManager *manager = [UAInAppMessageManager managerWithAutomationEngine:self.mockAutomationEngine
                                                                      remoteDataManager:[self mockForClass:[UARemoteDataManager class]]
                                                                              dataStore:self.dataStore];

    [[self.mockAutomationEngine expect] cancelSchedulesWithGroup:self.scheduleInfo.message.identifier];

    [manager cancelMessageWithID:self.scheduleInfo.message.identifier];

    [self.mockAutomationEngine verify];
}

- (void)testCancelSchedule {
    UAInAppMessageManager *manager = [UAInAppMessageManager managerWithAutomationEngine:self.mockAutomationEngine
                                                                              remoteDataManager:[self mockForClass:[UARemoteDataManager class]]
                                                                              dataStore:self.dataStore];

    UASchedule *testSchedule = [UASchedule scheduleWithIdentifier:@"expected_id" info:self.scheduleInfo];

    [[self.mockAutomationEngine expect] cancelScheduleWithIdentifier:testSchedule.identifier];

    [manager cancelMessageWithScheduleID:testSchedule.identifier];

    [self.mockAutomationEngine verify];
}

// Tests that componentEnabled switch pauses / resumes automation
- (void)testComponentEnabledSwitch {
    XCTAssertTrue(self.manager.componentEnabled);
    
    // setup
    __block XCTestExpectation *pauseCalledExpectation = nil;
    __block XCTestExpectation *resumeCalledExpectation = nil;
    
    [[[self.mockAutomationEngine stub] andDo:^(NSInvocation *invocation) {
        if (pauseCalledExpectation) {
            [pauseCalledExpectation fulfill];
        } else {
            XCTFail(@"Not expecting pause to be called");
        }
    }] pause];
    
    [[[self.mockAutomationEngine stub] andDo:^(NSInvocation *invocation) {
        if (resumeCalledExpectation) {
            [resumeCalledExpectation fulfill];
        } else {
            XCTFail(@"Not expecting resume to be called");
        }
    }] resume];

    pauseCalledExpectation = [self expectationWithDescription:@"automation engine pause called"];

    // test
    self.manager.componentEnabled = NO;
    XCTAssertFalse(self.manager.componentEnabled);

    // verify
    [self waitForExpectationsWithTimeout:5 handler:nil];
    XCTAssertFalse(self.manager.componentEnabled);

    //setup
    pauseCalledExpectation = nil;
    resumeCalledExpectation = [self expectationWithDescription:@"automation engine resume called"];

    // test
    self.manager.componentEnabled = YES;
    
    // verify
    [self waitForExpectationsWithTimeout:5 handler:nil];
    XCTAssertTrue(self.manager.componentEnabled);
}

- (void)testScheduleMessagesWithScheduleInfo {
    // setup
    UAInAppMessageScheduleInfo *anotherScheduleInfo = [UAInAppMessageScheduleInfo inAppMessageScheduleInfoWithBuilderBlock:^(UAInAppMessageScheduleInfoBuilder * _Nonnull builder) {
        UAInAppMessage *message = [UAInAppMessage messageWithBuilderBlock:^(UAInAppMessageBuilder * _Nonnull builder) {
            builder.identifier = @"another test identifier";
            builder.displayType = @"banner";
        }];
        
        builder.message = message;
    }];
    NSArray<UAInAppMessageScheduleInfo *> *submittedScheduleInfos = @[self.scheduleInfo,anotherScheduleInfo];
    
    // expectations
    [[[self.mockAutomationEngine expect] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        void (^completionHandler)(void) = (__bridge void (^)(void))arg;
        
        if (completionHandler) {
            completionHandler();
        }
    }] scheduleMultiple:[OCMArg checkWithBlock:^BOOL(NSArray<UAInAppMessageScheduleInfo *> *scheduleInfos) {
        return [scheduleInfos isEqualToArray:submittedScheduleInfos];
    }] completionHandler:OCMOCK_ANY];
    
    // test
    __block BOOL completionHandlerCalled = NO;
    [self.manager scheduleMessagesWithScheduleInfo:submittedScheduleInfos completionHandler:^(void) {
        completionHandlerCalled = YES;
    }];
    
    // verify
    XCTAssertTrue(completionHandlerCalled);
    [self.mockAutomationEngine verify];
}

- (void)testCancelMessagesWithIDs {
    // setup
    NSArray<NSString *> *messageIDsToCancel = @[[[NSUUID UUID] UUIDString], [[NSUUID UUID] UUIDString]];
    
    // expectations
    __block NSUInteger callsToCancelSchedulesWithGroup = 0;
    [[self.mockAutomationEngine stub] cancelSchedulesWithGroup:[OCMArg checkWithBlock:^BOOL(NSString *messageID) {
        XCTAssertEqualObjects(messageID,messageIDsToCancel[callsToCancelSchedulesWithGroup]);
        callsToCancelSchedulesWithGroup++;
        return YES;
    }]];
     
    // test
    [self.manager cancelMessagesWithIDs:messageIDsToCancel];
    
    // verify
    XCTAssertEqual(callsToCancelSchedulesWithGroup, messageIDsToCancel.count);
}

@end
