/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>
#import "UAInAppMessageBannerDisplayContent.h"

/**
 * The banner controller.
 */
@interface UAInAppMessageBannerController : NSObject <UIGestureRecognizerDelegate>


/**
 * The factory method for creating a banner controller.
 *
 * @param identifer The message identifier.
 * @param displayContent The display content.
 * @param image The image.
 *
 * @return a configured UAInAppMessageBannerView instance.
 */
+ (instancetype)bannerControllerWithBannerMessageID:(NSString *)identifer
                                     displayContent:(UAInAppMessageBannerDisplayContent *)displayContent
                                              image:(UIImage *)image;

/**
 * The factory method for creating a banner controller
 *
 * @param completionHandler The completion handler that's called when show operation completes.
 */
- (void)show:(void (^)(void))completionHandler;

@end
