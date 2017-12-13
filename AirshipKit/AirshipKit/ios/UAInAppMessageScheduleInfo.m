/* Copyright 2017 Urban Airship and Contributors */

#import "UAInAppMessageScheduleInfo.h"
#import "NSJSONSerialization+UAAdditions.h"
#import "UAScheduleInfo+Internal.h"
#import "UAInAppMessage+Internal.h"
#import "UAInAppMessageBannerDisplayContent.h"

NSString *const UAScheduleInfoInAppMessageKey = @"message";

@implementation UAInAppMessageScheduleInfoBuilder

@dynamic group;

- (UAInAppMessage *)message {
    if (self.data) {
        NSDictionary *data = [NSJSONSerialization objectWithString:self.data];

        if (data) {
            return [UAInAppMessage messageWithJSON:data error:nil];
        }
    }
    return nil;
}

- (void)setMessage:(UAInAppMessage *)message {

    NSMutableDictionary *data = [NSMutableDictionary dictionary];

    if (message) {
        if (message.identifier) {
            data[UAInAppMessageIDKey] = message.identifier;
        }
        if (message.displayType) {
            data[UAInAppMessageDisplayTypeKey] = message.displayType;
        }

        if (message.displayContent) {
            // Banner Type
            if (message.displayType == UAInAppMessageDisplayTypeBanner) {
                data[UAInAppMessageDisplayContentKey] = [UAInAppMessageBannerDisplayContent JSONWithBannerDisplayContent:(UAInAppMessageBannerDisplayContent *)message.displayContent];
            }

            // TODO add support for other types
        }

        if (message.extras) {
            data[UAInAppMessageExtrasKey] = message.extras;
        }

        self.data = [NSJSONSerialization stringWithObject:data];
    } else {
        self.data = nil;
    }
}

@end

@implementation UAInAppMessageScheduleInfo

- (UAInAppMessage *)message {
    return [UAInAppMessage messageWithJSON:[NSJSONSerialization objectWithString:self.data] error:nil];
}

+ (instancetype)inAppMessageScheduleInfoWithBuilderBlock:(void(^)(UAInAppMessageScheduleInfoBuilder *builder))builderBlock {
    UAInAppMessageScheduleInfoBuilder *builder = [[UAInAppMessageScheduleInfoBuilder alloc] init];
    builder.limit = 1;

    if (builderBlock) {
        builderBlock(builder);
    }

    return [[UAInAppMessageScheduleInfo alloc] initWithBuilder:builder];
}

+ (instancetype)inAppMessageScheduleInfoWithJSON:(id)json error:(NSError **)error {
    UAInAppMessageScheduleInfoBuilder *builder = [[UAInAppMessageScheduleInfoBuilder alloc] init];
    if (![builder applyFromJson:json error:error]) {
        return nil;
    }
    if (*error) {
        return nil;
    }

    // message ID
    id messagePayload = json[UAScheduleInfoInAppMessageKey];
    if (![messagePayload isKindOfClass:[NSDictionary class]]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"In-app message payload must be a dictionary. Invalid value: %@", messagePayload];
            *error =  [NSError errorWithDomain:UAScheduleInfoErrorDomain
                                          code:UAScheduleInfoErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }

        return nil;
    }

    // message with JSON expects displayType to be NSString
    UAInAppMessage *message = [UAInAppMessage messageWithJSON:messagePayload error:error];
    if (*error) {
        return nil;
    }
    builder.message = message;
    builder.group = message.identifier;

    return [[UAInAppMessageScheduleInfo alloc] initWithBuilder:builder];
}

+ (NSString *)parseMessageID:(id)json {
    id messagePayload = json[UAScheduleInfoInAppMessageKey];
    if (!messagePayload) {
        return nil;
    }
    
    return messagePayload[UAInAppMessageIDKey];
}
@end
