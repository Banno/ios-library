/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

/**
 * Represents the possible error conditions when deserializing media info from JSON.
 */
typedef NS_ENUM(NSInteger, UAMediaInfoErrorCode) {
    /**
     * Indicates an error with the media info JSON definition.
     */
    UAInAppMessageMediaInfoErrorCodeInvalidJSON,
};

/**
 * JSON keys.
 */
extern NSString *const UAInAppMessageMediaURLKey;
extern NSString *const UAInAppMessageMediaTypeKey;

/**
 * Image media type.
 */
extern NSString *const UAInAppMessageMediaInfoTypeImage;

/**
 * Video media type.
 */
extern NSString *const UAInAppMessageMediaInfoTypeVideo;

/**
 * YouTube media type.
 */
extern NSString *const UAInAppMessageMediaInfoTypeYouTube;

/**
 * Builder class for a UAInAppMessageMediaInfo object.
 */
@interface UAInAppMessageMediaInfoBuilder : NSObject

/**
 * Media URL.
 */
@property(nonatomic, copy) NSString *url;

/**
 * Media type - media, video or YouTube video.
 */
@property(nonatomic, copy) NSString *type;

@end


/**
 * Defines in-app message media content.
 */
@interface UAInAppMessageMediaInfo : NSObject

/**
 * Media URL.
 */
@property(nonatomic, copy, readonly) NSString *url;

/**
 * Media type - media, video or YouTube video.
 */
@property(nonatomic, copy, readonly) NSString *type;

/**
 * Factory method to create an in-app message media info from a JSON payload.
 *
 * @param json The JSON payload.
 * @param error An NSError pointer for storing errors, if applicable.
 * @return An in-app message media info or `nil` if the JSON is invalid.
 */
+ (nullable instancetype)mediaInfoWithJSON:(id)json error:(NSError * _Nullable *)error;

/**
 * Factory method to create a JSON dictionary from an in-app message media info.
 *
 * @param mediaInfo An in-app message media info.
 * @return The JSON dictionary.
 */
+ (NSDictionary *)JSONWithMediaInfo:(UAInAppMessageMediaInfo *)mediaInfo;

/**
 * Creates in-app message media info with a builder block.
 *
 * @return The in-app message media info.
 */
+ (nullable instancetype)mediaInfoWithBuilderBlock:(void(^)(UAInAppMessageMediaInfoBuilder *builder))builderBlock;


@end

NS_ASSUME_NONNULL_END

