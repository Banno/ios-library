/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAInAppMessageDisplayContent.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Custom display content.
 */
@interface UAInAppMessageCustomDisplayContent : UAInAppMessageDisplayContent

/**
 * The custom content.
 */
@property (nonatomic, readonly) NSDictionary *value;

/**
 * Factory method to create a custom display content.
 *
 * @param value The custom display content. The value should be json serializable.
 * @return The custom display content.
 */
+ (instancetype)displayContentWithValue:(NSDictionary *)value;

@end

NS_ASSUME_NONNULL_END

