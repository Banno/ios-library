/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

@class UAInAppMessageTagSelector;
@class UAVersionMatcher;

NS_ASSUME_NONNULL_BEGIN


/**
 * Builder class for a UAInAppMessageAudience.
 */
@interface UAInAppMessageAudienceBuilder : NSObject

/**
 * The notifications opt in flag.
 */
@property(nonatomic, copy) NSNumber *notificationsOptIn;

/**
 * The location opt in flag.
 */
@property(nonatomic, copy) NSNumber *locationOptIn;

/**
 * The language tags.
 */
@property(nonatomic, strong, nullable) NSArray<NSString *> *languageTags;

/**
 * The tag selector
 */
@property(nonatomic, strong, nullable) UAInAppMessageTagSelector *tagSelector;

/**
 * The app version predicate
 */
@property(nonatomic, strong, nullable) UAVersionMatcher *versionMatcher;

/**
 * Checks if the builder is valid and will produce a audience.
 * @return YES if the builder is valid, otherwise NO.
 */
- (BOOL)isValid;

@end

/**
 * Model object for an In App Message audience constraint.
 */
@interface UAInAppMessageAudience : NSObject

/**
 * The notifications opt in flag.
 */
@property(nonatomic, strong) NSNumber *notificationsOptIn;

/**
 * The location opt in flag.
 */
@property(nonatomic, strong) NSNumber *locationOptIn;

/**
 * The language tags.
 */
@property(nonatomic, strong, nullable) NSArray<NSString *> *languageIDs;

/**
 * The tag selector
 */
@property(nonatomic, strong, nullable) UAInAppMessageTagSelector *tagSelector;

/**
 * The app version matcher
 */
@property(nonatomic, strong, nullable) UAVersionMatcher *versionMatcher;

/**
 * Factory method for building audience model from a builder block.
 *
 * @param builderBlock The builder block.
 * @returns `YES` if the builderBlock was able to be applied, otherwise `NO`.
 */
+ (instancetype)audienceWithBuilderBlock:(void(^)(UAInAppMessageAudienceBuilder *builder))builderBlock;



@end

NS_ASSUME_NONNULL_END

