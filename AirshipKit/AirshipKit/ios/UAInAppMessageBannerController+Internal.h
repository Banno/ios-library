/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>
#import "UAInAppMessageBannerDisplayContent.h"
#import "UAInAppMessageResolution.h"

NS_ASSUME_NONNULL_BEGIN

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
                                              image:(UIImage * _Nullable)image;

/**
 * The method to show the banner controller.
 *
 * @param parentView The parent view.
 * @param completionHandler The completion handler that's called when show operation completes.
 */
- (void)showWithParentView:(UIView *)parentView completionHandler:(void (^)(UAInAppMessageResolution *))completionHandler;

@end

NS_ASSUME_NONNULL_END
