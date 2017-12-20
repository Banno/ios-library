/* Copyright 2017 Urban Airship and Contributors */

#import <Foundation/Foundation.h>

/**
 * Display content for a in-app message.
 */
@interface UAInAppMessageDisplayContent : NSObject

/**
 * Button layout.
 */
typedef NS_ENUM(NSInteger, UAInAppMessageButtonLayoutType) {
    /**
     * Stacked button layout
     */
    UAInAppMessageButtonLayoutTypeStacked,
    
    /**
     * Separate button layout
     */
    UAInAppMessageButtonLayoutTypeSeparate,
    
    /**
     * Joined button layout
     */
    UAInAppMessageButtonLayoutTypeJoined,
};

/**
 * JSON keys and values.
 */
extern NSString *const UAInAppMessageBodyKey;
extern NSString *const UAInAppMessageHeadingKey;
extern NSString *const UAInAppMessageBackgroundColorKey;
extern NSString *const UAInAppMessagePlacementKey;
extern NSString *const UAInAppMessageContentLayoutKey;
extern NSString *const UAInAppMessageBorderRadiusKey;
extern NSString *const UAInAppMessageButtonLayoutKey;
extern NSString *const UAInAppMessageButtonsKey;
extern NSString *const UAInAppMessageMediaKey;
extern NSString *const UAInAppMessageURLKey;
extern NSString *const UAInAppMessageDismissButtonColorKey;
extern NSString *const UAInAppMessageFooterKey;
extern NSString *const UAInAppMessageDurationKey;

/**
 * Buttons are displayed with a space between them.
 */
extern NSString *const UAInAppMessageButtonLayoutStackedValue;

/**
 * Buttons are displayed right next to each other.
 */
extern NSString *const UAInAppMessageButtonLayoutSeparateValue;

/**
 * Buttons are stacked.
 */
extern NSString *const UAInAppMessageButtonLayoutJoinedValue;


/**
 * Method to return the display content as its JSON representation.
 * Sub-classes must override this method
 *
 * @returns JSON representation of the display content (as NSDictionary)
 */
- (NSDictionary *)toJsonValue;

@end

