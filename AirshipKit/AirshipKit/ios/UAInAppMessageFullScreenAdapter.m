/* Copyright Airship and Contributors */

#import "UAGlobal.h"
#import "UAInAppMessageFullScreenAdapter.h"
#import "UAInAppMessageFullScreenDisplayContent+Internal.h"
#import "UAInAppMessageFullScreenViewController+Internal.h"
#import "UAInAppMessageUtils+Internal.h"
#import "UAInAppMessageMediaView+Internal.h"
#import "UAUtils+Internal.h"
#import "UAInAppMessageSceneManager.h"

NSString *const UAFullScreenStyleFileName = @"UAInAppMessageFullScreenStyle";

@interface UAInAppMessageFullScreenAdapter ()
@property (nonatomic, strong) UAInAppMessage *message;
@property (nonatomic, strong) UAInAppMessageFullScreenViewController *fullScreenController;
@end

@implementation UAInAppMessageFullScreenAdapter

+ (instancetype)adapterForMessage:(UAInAppMessage *)message {
    return [[UAInAppMessageFullScreenAdapter alloc] initWithMessage:message];
}

- (instancetype)initWithMessage:(UAInAppMessage *)message {
    self = [super init];

    if (self) {
        self.message = message;
        self.style = [UAInAppMessageFullScreenStyle styleWithContentsOfFile:UAFullScreenStyleFileName];
    }

    return self;
}

- (void)prepareWithAssets:(nonnull UAInAppMessageAssets *)assets completionHandler:(nonnull void (^)(UAInAppMessagePrepareResult))completionHandler {
    UAInAppMessageFullScreenDisplayContent *displayContent = (UAInAppMessageFullScreenDisplayContent *)self.message.displayContent;
    [UAInAppMessageUtils prepareMediaView:displayContent.media assets:assets completionHandler:^(UAInAppMessagePrepareResult result, UAInAppMessageMediaView *mediaView) {
        if (result == UAInAppMessagePrepareResultSuccess) {
            self.fullScreenController = [UAInAppMessageFullScreenViewController fullScreenControllerWithFullScreenMessageID:self.message.identifier
                                                                                                             displayContent:displayContent
                                                                                                                  mediaView:mediaView
                                                                                                                      style:self.style];
        }
        completionHandler(result);
    }];
}

- (BOOL)isReadyToDisplay {
    UAInAppMessageFullScreenDisplayContent *fullScreenContent = (UAInAppMessageFullScreenDisplayContent *)self.message.displayContent;
    return [UAInAppMessageUtils isReadyToDisplayWithMedia:fullScreenContent.media];
}

- (void)display:(void (^)(UAInAppMessageResolution *))completionHandler {
    if (@available(iOS 13.0, *)) {
        UIWindowScene *scene = [[UAInAppMessageSceneManager shared] sceneForMessage:self.message];
        [self.fullScreenController showWithScene:scene completionHandler:completionHandler];
    } else {
        [self.fullScreenController showWithCompletionHandler:completionHandler];
    }
}


@end

