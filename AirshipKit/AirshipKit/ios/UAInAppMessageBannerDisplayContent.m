/* Copyright 2017 Urban Airship and Contributors */

#import "UAirship.h"
#import "UAInAppMessageBannerDisplayContent+Internal.h"
#import "UAInAppMessageTextInfo.h"
#import "UAInAppMessageButtonInfo.h"
#import "UAInAppMessageMediaInfo+Internal.h"
#import "UAInAppMessageDisplayContent.h"
#import "UAColorUtils+Internal.h"

// JSON keys
NSString *const UAInAppMessageBannerActionsKey = @"actions";
NSString *const UAInAppMessageBannerDisplayContentDomain = @"com.urbanairship.banner_display_content";
NSString *const UAInAppMessageBannerPlacementTopValue = @"top";
NSString *const UAInAppMessageBannerPlacementBottomValue = @"bottom";
NSString *const UAInAppMessageBannerContentLayoutMediaLeftValue = @"media_left";
NSString *const UAInAppMessageBannerContentLayoutMediaRightValue = @"media_right";

// Constants
NSUInteger const UAInAppMessageBannerDefaultDuration = 30000;
NSUInteger const UAInAppMessageBannerMaxButtons = 2;

@implementation UAInAppMessageBannerDisplayContentBuilder

// set default values for properties
- (instancetype)init {
    if (self = [super init]) {
        self.buttonLayout = UAInAppMessageButtonLayoutTypeSeparate;
        self.placement = UAInAppMessageBannerPlacementBottom;
        self.contentLayout = UAInAppMessageBannerContentLayoutTypeMediaLeft;
        self.duration = UAInAppMessageBannerDefaultDuration;
        self.backgroundColor = [UIColor whiteColor];
        self.dismissButtonColor = [UIColor blackColor];
    }
    return self;
}

@end

@implementation UAInAppMessageBannerDisplayContent

+ (instancetype)bannerDisplayContentWithBuilderBlock:(void(^)(UAInAppMessageBannerDisplayContentBuilder *builder))builderBlock {
    UAInAppMessageBannerDisplayContentBuilder *builder = [[UAInAppMessageBannerDisplayContentBuilder alloc] init];

    if (builderBlock) {
        builderBlock(builder);
    }

    return [[UAInAppMessageBannerDisplayContent alloc] initWithBuilder:builder];
}

+ (instancetype)bannerDisplayContentWithJSON:(id)json error:(NSError **)error {
    UAInAppMessageBannerDisplayContentBuilder *builder = [[UAInAppMessageBannerDisplayContentBuilder alloc] init];
    
    if (![json isKindOfClass:[NSDictionary class]]) {
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Attempted to deserialize invalid object: %@", json];
            *error =  [NSError errorWithDomain:UAInAppMessageBannerDisplayContentDomain
                                          code:UAInAppMessageBannerDisplayContentErrorCodeInvalidJSON
                                      userInfo:@{NSLocalizedDescriptionKey:msg}];
        }
        return nil;
    }
    
    if (json[UAInAppMessageHeadingKey]) {
        if (![json[UAInAppMessageHeadingKey] isKindOfClass:[NSDictionary class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Attempted to deserialize invalid text info object: %@", json];
                *error =  [NSError errorWithDomain:UAInAppMessageBannerDisplayContentDomain
                                              code:UAInAppMessageBannerDisplayContentErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }
            return nil;
        }
        builder.heading = [UAInAppMessageTextInfo textInfoWithJSON:json[UAInAppMessageHeadingKey] error:error];
    }
    
    if (json[UAInAppMessageBodyKey]) {
        if (![json[UAInAppMessageBodyKey] isKindOfClass:[NSDictionary class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Attempted to deserialize invalid text info object: %@", json];
                *error =  [NSError errorWithDomain:UAInAppMessageBannerDisplayContentDomain
                                              code:UAInAppMessageBannerDisplayContentErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }
            return nil;
        }
        builder.body = [UAInAppMessageTextInfo textInfoWithJSON:json[UAInAppMessageBodyKey] error:error];
    }
    
    if (json[UAInAppMessageMediaKey]) {
        builder.media = [UAInAppMessageMediaInfo mediaInfoWithJSON:json[UAInAppMessageMediaKey] error:error];

        if (!builder.media) {
            return nil;
        }
    }

    NSMutableArray<UAInAppMessageButtonInfo *> *buttons = [NSMutableArray array];
    id buttonsJSONArray = json[UAInAppMessageButtonsKey];
    if (buttonsJSONArray) {
        if (![buttonsJSONArray isKindOfClass:[NSArray class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Buttons must contain an array of buttons. Invalid value %@", buttonsJSONArray];
                *error =  [NSError errorWithDomain:UAInAppMessageBannerDisplayContentDomain
                                              code:UAInAppMessageBannerDisplayContentErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }
            return nil;
        }
        
        builder.buttons = [NSMutableArray array];
        
        for (id buttonJSON in buttonsJSONArray) {
            UAInAppMessageButtonInfo *buttonInfo = [UAInAppMessageButtonInfo buttonInfoWithJSON:buttonJSON error:error];
            
            if (!buttonInfo) {
                return nil;
            }
            
            [buttons addObject:buttonInfo];
        }
        builder.buttons = [NSArray arrayWithArray:buttons];
    }
    
    id buttonLayoutValue = json[UAInAppMessageButtonLayoutKey];
    if (buttonLayoutValue) {
        if (![buttonLayoutValue isKindOfClass:[NSString class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Button layout must be a string. Invalid value: %@", buttonLayoutValue];
                *error =  [NSError errorWithDomain:UAInAppMessageBannerDisplayContentDomain
                                              code:UAInAppMessageBannerDisplayContentErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }
            return nil;
        }
        if ([UAInAppMessageButtonLayoutJoinedValue isEqualToString:buttonLayoutValue]) {
            builder.buttonLayout = UAInAppMessageButtonLayoutTypeJoined;
        } else if ([UAInAppMessageButtonLayoutSeparateValue isEqualToString:buttonLayoutValue]) {
            builder.buttonLayout = UAInAppMessageButtonLayoutTypeSeparate;
        } else if ([UAInAppMessageButtonLayoutStackedValue isEqualToString:buttonLayoutValue]) {
            builder.buttonLayout = UAInAppMessageButtonLayoutTypeStacked;
        } else {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Invalid in-app button layout type: %@", buttonLayoutValue];
                *error =  [NSError errorWithDomain:UAInAppMessageBannerDisplayContentDomain
                                              code:UAInAppMessageBannerDisplayContentErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }
            return nil;
        }
    }
    
    id placementValue = json[UAInAppMessagePlacementKey];
    if (placementValue) {
        if (![placementValue isKindOfClass:[NSString class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Placement must be a string. Invalid value: %@", placementValue];
                *error =  [NSError errorWithDomain:UAInAppMessageBannerDisplayContentDomain
                                              code:UAInAppMessageBannerDisplayContentErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }
            return nil;
        } else {
            if ([UAInAppMessageBannerPlacementTopValue isEqualToString:placementValue]) {
                builder.placement = UAInAppMessageBannerPlacementTop;
            } else if ([UAInAppMessageBannerPlacementBottomValue isEqualToString:placementValue]) {
                builder.placement = UAInAppMessageBannerPlacementBottom;
            } else {
                NSString *msg = [NSString stringWithFormat:@"Placement must be a string. Invalid value: %@", placementValue];
                *error =  [NSError errorWithDomain:UAInAppMessageBannerDisplayContentDomain
                                              code:UAInAppMessageBannerDisplayContentErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
                return nil;
            }
        }
    }
    
    id layoutContents = json[UAInAppMessageContentLayoutKey];
    if (layoutContents) {
        if (![layoutContents isKindOfClass:[NSString class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Content layout must be a string."];
                *error =  [NSError errorWithDomain:UAInAppMessageBannerDisplayContentDomain
                                              code:UAInAppMessageBannerDisplayContentErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }
            return nil;
        }
        
        layoutContents = [layoutContents lowercaseString];
        
        if ([UAInAppMessageBannerContentLayoutMediaLeftValue isEqualToString:layoutContents]) {
            builder.contentLayout = UAInAppMessageBannerContentLayoutTypeMediaLeft;
        } else if ([UAInAppMessageBannerContentLayoutMediaRightValue isEqualToString:layoutContents]) {
            builder.contentLayout = UAInAppMessageBannerContentLayoutTypeMediaRight;
        } else {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Invalid in-app message content layout: %@", layoutContents];
                *error =  [NSError errorWithDomain:UAInAppMessageBannerDisplayContentDomain
                                              code:UAInAppMessageBannerDisplayContentErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }
            return nil;
        }
    }
    
    id durationValue = json[UAInAppMessageDurationKey];
    if (durationValue) {
        if (![durationValue isKindOfClass:[NSNumber class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Duration must be a number. Invalid value: %@", durationValue];
                *error =  [NSError errorWithDomain:UAInAppMessageBannerDisplayContentDomain
                                              code:UAInAppMessageBannerDisplayContentErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }
            return nil;
        }
        builder.duration = [durationValue integerValue];
    }
    
    id backgroundColorHex = json[UAInAppMessageBackgroundColorKey];
    if (backgroundColorHex) {
        if (![backgroundColorHex isKindOfClass:[NSString class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Background color must be a string. Invalid value: %@", backgroundColorHex];
                *error =  [NSError errorWithDomain:UAInAppMessageBannerDisplayContentDomain
                                              code:UAInAppMessageBannerDisplayContentErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }
            return nil;
        }
        builder.backgroundColor = [UAColorUtils colorWithHexString:backgroundColorHex];
    }
    
    id dismissButtonColorHex = json[UAInAppMessageDismissButtonColorKey];
    if (dismissButtonColorHex) {
        if (![dismissButtonColorHex isKindOfClass:[NSString class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Dismiss button color must be a string. Invalid value: %@", dismissButtonColorHex];
                *error =  [NSError errorWithDomain:UAInAppMessageBannerDisplayContentDomain
                                              code:UAInAppMessageBannerDisplayContentErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }
            return nil;
        }
        builder.dismissButtonColor = [UAColorUtils colorWithHexString:dismissButtonColorHex];
    }
    
    id borderRadius = json[UAInAppMessageBorderRadiusKey];
    if (borderRadius) {
        if (![borderRadius isKindOfClass:[NSNumber class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Border radius must be a number. Invalid value: %@", borderRadius];
                *error =  [NSError errorWithDomain:UAInAppMessageBannerDisplayContentDomain
                                              code:UAInAppMessageBannerDisplayContentErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }
            return nil;
        }
        builder.borderRadius = [borderRadius unsignedIntegerValue];
    }

    id actions = json[UAInAppMessageBannerActionsKey];
    if (actions) {
        if (![actions isKindOfClass:[NSDictionary class]]) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Actions payload must be a dictionary. Invalid value: %@", actions];
                *error =  [NSError errorWithDomain:UAInAppMessageBannerDisplayContentDomain
                                              code:UAInAppMessageBannerDisplayContentErrorCodeInvalidJSON
                                          userInfo:@{NSLocalizedDescriptionKey:msg}];
            }
            return nil;
        }
        builder.actions = actions;
    }
    
    return [[UAInAppMessageBannerDisplayContent alloc] initWithBuilder:builder];
}

- (instancetype)initWithBuilder:(UAInAppMessageBannerDisplayContentBuilder *)builder {
    self = [super init];

    if (![UAInAppMessageBannerDisplayContent validateBuilder:builder]) {
        UA_LDEBUG(@"UAInAppMessageBannerDisplayContent could not be initialized, builder has missing or invalid parameters.");
        return nil;
    }

    if (self) {
        self.heading = builder.heading;
        self.body = builder.body;
        self.media = builder.media;
        self.buttons = builder.buttons;
        self.buttonLayout = builder.buttonLayout;
        self.placement = builder.placement;
        self.contentLayout = builder.contentLayout;
        self.duration = builder.duration;
        self.backgroundColor = builder.backgroundColor;
        self.dismissButtonColor = builder.dismissButtonColor;
        self.borderRadius = builder.borderRadius;
        self.actions = builder.actions;
    }

    return self;
}

#pragma mark - Validation

// Validates builder contents for the banner type
+ (BOOL)validateBuilder:(UAInAppMessageBannerDisplayContentBuilder *)builder {
    if (builder.buttonLayout == UAInAppMessageButtonLayoutTypeStacked) {
        UA_LDEBUG(@"Banner style does not support stacked button layouts");
        return NO;
    }

    if (builder.heading == nil && builder.body == nil) {
        UA_LDEBUG(@"Banner must have either its body or heading defined.");
        return NO;
    }

    if (builder.media.type && builder.media.type != UAInAppMessageMediaInfoTypeImage) {
        UA_LDEBUG(@"Banner only supports image media.");
        return NO;
    }

    if (builder.buttons.count > UAInAppMessageBannerMaxButtons) {
        UA_LDEBUG(@"Banner allows a maximum of %lu buttons", (unsigned long)UAInAppMessageBannerMaxButtons);
        return NO;
    }

    return YES;
}

- (NSDictionary *)toJsonValue {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];

    if (self.heading) {
        json[UAInAppMessageHeadingKey] = [UAInAppMessageTextInfo JSONWithTextInfo:self.heading];
    }

    if (self.body) {
        json[UAInAppMessageBodyKey] = [UAInAppMessageTextInfo JSONWithTextInfo:self.body];
    }

    if (self.media) {
        json[UAInAppMessageMediaKey] = [self.media toJson];
    }
    
    NSMutableArray *buttonsJSONs = [NSMutableArray array];
    for (UAInAppMessageButtonInfo *buttonInfo in self.buttons) {
        [buttonsJSONs addObject:[UAInAppMessageButtonInfo JSONWithButtonInfo:buttonInfo]];
    }

    if (buttonsJSONs.count) {
        json[UAInAppMessageButtonsKey] = buttonsJSONs;
    }
    
    switch (self.buttonLayout) {
        case UAInAppMessageButtonLayoutTypeStacked:
            json[UAInAppMessageButtonLayoutKey] = UAInAppMessageButtonLayoutStackedValue;
            break;
        case UAInAppMessageButtonLayoutTypeSeparate:
            json[UAInAppMessageButtonLayoutKey] = UAInAppMessageButtonLayoutSeparateValue;
            break;
        case UAInAppMessageButtonLayoutTypeJoined:
            json[UAInAppMessageButtonLayoutKey] = UAInAppMessageButtonLayoutJoinedValue;
            break;
    }

    switch (self.placement) {
        case UAInAppMessageBannerPlacementTop:
            json[UAInAppMessagePlacementKey] = UAInAppMessageBannerPlacementTopValue;
            break;
        case UAInAppMessageBannerPlacementBottom:
            json[UAInAppMessagePlacementKey] = UAInAppMessageBannerPlacementBottomValue;
            break;
    }

    switch(self.contentLayout) {
        case UAInAppMessageBannerContentLayoutTypeMediaLeft:
            json[UAInAppMessageContentLayoutKey] = UAInAppMessageBannerContentLayoutMediaLeftValue;
            break;
        case UAInAppMessageBannerContentLayoutTypeMediaRight:
            json[UAInAppMessageContentLayoutKey] = UAInAppMessageBannerContentLayoutMediaRightValue;
            break;
    }

    json[UAInAppMessageDurationKey] = [NSNumber numberWithInteger:self.duration];
    json[UAInAppMessageBackgroundColorKey] = [UAColorUtils hexStringWithColor:self.backgroundColor];
    json[UAInAppMessageDismissButtonColorKey] = [UAColorUtils hexStringWithColor:self.dismissButtonColor];
    json[UAInAppMessageBorderRadiusKey] = [NSNumber numberWithInteger:self.borderRadius];
    json[UAInAppMessageBannerActionsKey] = self.actions;
    
    return [NSDictionary dictionaryWithDictionary:json];
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[UAInAppMessageBannerDisplayContent class]]) {
        return NO;
    }

    return [self isEqualToInAppMessageBannerDisplayContent:(UAInAppMessageBannerDisplayContent *)object];
}

- (BOOL)isEqualToInAppMessageBannerDisplayContent:(UAInAppMessageBannerDisplayContent *)content {

    if (content.heading != self.heading && ![self.heading isEqual:content.heading]) {
        return NO;
    }

    if (content.body != self.body && ![self.body isEqual:content.body]) {
        return NO;
    }

    if (content.media != self.media  && ![self.media isEqual:content.media]) {
        return NO;
    }

    if (content.buttons != self.buttons  && ![self.buttons isEqualToArray:content.buttons]) {
        return NO;
    }

    if (content.buttonLayout != self.buttonLayout) {
        return NO;
    }

    if (content.placement != self.placement) {
        return NO;
    }

    if (content.contentLayout != self.contentLayout) {
        return NO;
    }

    if (self.duration != content.duration) {
        return NO;
    }

    // Unfortunately, UIColor won't compare across color spaces. It works to convert them to hex and then compare them.
    if (content.backgroundColor != self.backgroundColor && ![[UAColorUtils hexStringWithColor:self.backgroundColor] isEqualToString:[UAColorUtils hexStringWithColor:content.backgroundColor]]) {
        return NO;
    }

    if (content.dismissButtonColor != self.dismissButtonColor && ![[UAColorUtils hexStringWithColor:self.dismissButtonColor] isEqualToString:[UAColorUtils hexStringWithColor:content.dismissButtonColor]]) {
        return NO;
    }

    if (self.borderRadius != content.borderRadius) {
        return NO;
    }

    return YES;
}

- (NSUInteger)hash {
    NSUInteger result = 1;
    result = 31 * result + [self.heading hash];
    result = 31 * result + [self.body hash];
    result = 31 * result + [self.media hash];
    result = 31 * result + [self.buttons hash];
    result = 31 * result + self.buttonLayout;
    result = 31 * result + self.placement;
    result = 31 * result + self.contentLayout;
    result = 31 * result + self.duration;
    result = 31 * result + [[UAColorUtils hexStringWithColor:self.backgroundColor] hash];
    result = 31 * result + [[UAColorUtils hexStringWithColor:self.dismissButtonColor] hash];
    result = 31 * result + self.borderRadius;

    return result;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"UAInAppMessageBannerDisplayContent: %lu", (unsigned long)self.hash];
}

@end

