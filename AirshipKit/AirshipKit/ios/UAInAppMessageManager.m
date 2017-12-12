/* Copyright 2017 Urban Airship and Contributors */

#import "UAInAppMessageManager+Internal.h"
#import "UAInAppMessageAdapterProtocol.h"
#import "UAInAppMessageScheduleInfo.h"
#import "UAScheduleInfo+Internal.h"
#import "NSJSONSerialization+UAAdditions.h"
#import "UAInAppMessageBannerAdapter.h"
#import "UAGlobal.h"
#import "UAConfig.h"
#import "UAInAppRemoteDataClient+Internal.h"
#import "UAPreferenceDataStore+Internal.h"

NS_ASSUME_NONNULL_BEGIN

NSTimeInterval const FetchRetryDelayMS = 30000;
NSTimeInterval const DefaultMessageDisplayInterval = 5000;
NSTimeInterval const MaxSchedules = 200;
NSString *const UAInAppAutomationStoreFileFormat = @"In-app-automation-%@.sqlite";

@interface UAInAppMessageManager ()

@property(nonatomic, assign) BOOL isCurrentMessagePrepared;
@property(nonatomic, assign) BOOL isDisplayLocked;
@property(nonatomic, strong, nullable) NSDictionary *adapterFactories;
@property(nonatomic, strong, nullable) NSString *currentScheduleID;
@property(nonatomic, strong, nullable) id<UAInAppMessageAdapterProtocol> currentAdapter;
@property(nonatomic, strong, nullable) UAAutomationEngine *automationEngine;
@property(nonatomic, strong) UAInAppRemoteDataClient *remoteDataClient;

@end

@implementation UAInAppMessageManager

+ (instancetype)managerWithAutomationEngine:(UAAutomationEngine *)automationEngine remoteDataManager:(UARemoteDataManager *)remoteDataManager dataStore:(UAPreferenceDataStore *)dataStore {
    return [[UAInAppMessageManager alloc] initWithAutomationEngine:automationEngine remoteDataManager:remoteDataManager dataStore:dataStore];
}

+ (instancetype)managerWithConfig:(UAConfig *)config remoteDataManager:(UARemoteDataManager *)remoteDataManager dataStore:(UAPreferenceDataStore *)dataStore {
    return [[UAInAppMessageManager alloc] initWithConfig:config remoteDataManager:remoteDataManager dataStore:dataStore];
}

- (instancetype)initWithConfig:(UAConfig *)config remoteDataManager:(UARemoteDataManager *)remoteDataManager dataStore:(UAPreferenceDataStore *)dataStore {
    self = [super initWithDataStore:dataStore];

    if (self) {
        NSString *storeName = [NSString stringWithFormat:UAInAppAutomationStoreFileFormat, config.appKey];
        self.automationEngine = [UAAutomationEngine automationEngineWithStoreName:storeName scheduleLimit:MaxSchedules];
        self.automationEngine.delegate = self;

        if (self.componentEnabled) {
            [self.automationEngine start];
        }

        self.displayInterval = DefaultMessageDisplayInterval;
        self.remoteDataClient = [UAInAppRemoteDataClient clientWithScheduler:self remoteDataManager:remoteDataManager dataStore:dataStore];
        [self setDefaultAdapterFactories];
    }

    return self;
}

- (instancetype)initWithAutomationEngine:(UAAutomationEngine *)automationEngine remoteDataManager:(UARemoteDataManager *)remoteDataManager dataStore:(UAPreferenceDataStore *)dataStore {
    self = [super initWithDataStore:dataStore];

    if (self) {
        self.automationEngine = automationEngine;
        self.displayInterval = DefaultMessageDisplayInterval;
        self.remoteDataClient = [UAInAppRemoteDataClient clientWithScheduler:self remoteDataManager:remoteDataManager dataStore:dataStore];
        [self setDefaultAdapterFactories];
    }

    return self;
}

// Sets the default adapter factories
- (void)setDefaultAdapterFactories {

    // Banner
    [self setFactoryBlock:^id<UAInAppMessageAdapterProtocol> _Nonnull(UAInAppMessage * _Nonnull message) {
        return [UAInAppMessageBannerAdapter adapterForMessage:message];
    } forDisplayType:UAInAppMessageDisplayTypeBanner];

    // TODO set factories for other display types here
}

- (void)getScheduleWithIdentifier:(NSString *)identifier completionHandler:(void (^)(UASchedule *))completionHandler {
    [self.automationEngine getScheduleWithIdentifier:identifier completionHandler:completionHandler];
}

- (void)scheduleMessageWithScheduleInfo:(UAInAppMessageScheduleInfo *)scheduleInfo
                      completionHandler:(void (^)(UASchedule *))completionHandler {
    [self.automationEngine schedule:scheduleInfo completionHandler:completionHandler];;
}

- (void)scheduleMessagesWithScheduleInfo:(NSArray<UAInAppMessageScheduleInfo *> *)scheduleInfos completionHandler:(void (^)(void))completionHandler {
    [self.automationEngine scheduleMultiple:scheduleInfos completionHandler:completionHandler];
}

- (void)cancelMessageWithID:(NSString *)identifier {
    [self.automationEngine cancelSchedulesWithGroup:identifier];
}

- (void)cancelMessagesWithIDs:(NSArray<NSString *> *)identifiers {
    for (NSString *messageID in identifiers) {
        [self cancelMessageWithID:messageID];
    }
}

- (void)cancelMessageWithScheduleID:(NSString *)scheduleID {
    [self.automationEngine cancelScheduleWithIdentifier:scheduleID];
}

- (UAScheduleInfo *)createScheduleInfoWithBuilder:(UAScheduleInfoBuilder *)builder {
    return [[UAInAppMessageScheduleInfo alloc] initWithBuilder:builder];
}

- (void)setFactoryBlock:(id<UAInAppMessageAdapterProtocol> (^)(UAInAppMessage* message))factory
         forDisplayType:(NSString *)displayType {
    NSMutableDictionary *adapterFactories;

    if (!self.adapterFactories) {
        adapterFactories = [NSMutableDictionary dictionary];
    } else {
        adapterFactories = [NSMutableDictionary dictionaryWithDictionary:self.adapterFactories];
    }

    [adapterFactories setObject:factory forKey:displayType];
    self.adapterFactories = [NSDictionary dictionaryWithDictionary:adapterFactories];
}

- (void)unlockDisplayAfter:(NSTimeInterval)interval {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isDisplayLocked = false;
        [self.automationEngine scheduleConditionsChanged];
    });
}

- (void)lockDisplay {
    self.isDisplayLocked = true;
}

- (BOOL)isScheduleReadyToExecute:(UASchedule *)schedule {
    // Only ready if active or very soon to be active
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        return NO;
    }

    // If the display is locked via timer return no
    if (self.isDisplayLocked) {
        return NO;
    }

    UAInAppMessageScheduleInfo *info = (UAInAppMessageScheduleInfo *)schedule.info;
    NSDictionary *messageJSON = [NSJSONSerialization objectWithString:schedule.info.data];
    info.message = [UAInAppMessage messageWithJSON:messageJSON error:nil];

    if (!self.currentAdapter) {

        id<UAInAppMessageAdapterProtocol> (^factory)(UAInAppMessage* message) = self.adapterFactories[info.message.displayType];

        if (!factory) {
            UA_LWARN(@"Factory not present for display type:%@", info.message.displayType);
            return NO;
        }

        id<UAInAppMessageAdapterProtocol> adapter = factory(info.message);

        // If no adapter factory available for specified displayType return NO
        if (!adapter) {
            UA_LWARN(@"Factory failed to build adapter with message:%@", info.message);
            return NO;
        }

        self.currentAdapter = adapter;
        self.currentScheduleID = schedule.identifier;

        UA_WEAKIFY(self);
        [self.currentAdapter prepare:^{
            UA_STRONGIFY(self);

            self.isCurrentMessagePrepared = YES;
            [self.automationEngine scheduleConditionsChanged];
        }];

        return NO;
    }

    if (![schedule.identifier isEqualToString:self.currentScheduleID]) {
        return NO;
    }

    return self.isCurrentMessagePrepared;
}

- (void)executeSchedule:(nonnull UASchedule *)schedule
      completionHandler:(void (^)(void))completionHandler {
    // Lock Display
    [self lockDisplay];

    UA_WEAKIFY(self);
    [self.currentAdapter display:^{
        UA_STRONGIFY(self);
        self.currentAdapter = nil;
        self.currentScheduleID = nil;
        // Start timer to unlock display after display interval
        [self unlockDisplayAfter:self.displayInterval];
        completionHandler();
    }];
}

- (void)onComponentEnableChange {
    if (self.componentEnabled) {
        // if component was disabled and is now enabled, resume automation engine
        [self.automationEngine resume];
    } else {
        // if component was enabled and is now disabled, pause automation engine
        [self.automationEngine pause];
    }
}

- (void)dealloc {
    [self.automationEngine stop];
    self.automationEngine.delegate = nil;
}


@end

NS_ASSUME_NONNULL_END
