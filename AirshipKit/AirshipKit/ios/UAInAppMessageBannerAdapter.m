/* Copyright Airship and Contributors */

#import "UAGlobal.h"
#import "UAInAppMessageBannerAdapter.h"
#import "UAInAppMessageBannerDisplayContent+Internal.h"
#import "UAInAppMessageBannerController+Internal.h"
#import "UAInAppMessageUtils+Internal.h"
#import "UAUtils+Internal.h"
#import "UAInAppMessageSceneManager.h"

NSString *const UABannerStyleFileName = @"UAInAppMessageBannerStyle";

@interface UAInAppMessageBannerAdapter ()
@property (nonatomic, strong) UAInAppMessage *message;
@property (nonatomic, strong) UAInAppMessageBannerController *bannerController;
@end

@implementation UAInAppMessageBannerAdapter

+ (instancetype)adapterForMessage:(UAInAppMessage *)message {
    return [[UAInAppMessageBannerAdapter alloc] initWithMessage:message];
}

- (instancetype)initWithMessage:(UAInAppMessage *)message {
    self = [super init];

    if (self) {
        self.message = message;
        self.style = [UAInAppMessageBannerStyle styleWithContentsOfFile:UABannerStyleFileName];
    }

    return self;
}

- (void)prepareWithAssets:(nonnull UAInAppMessageAssets *)assets completionHandler:(nonnull void (^)(UAInAppMessagePrepareResult))completionHandler {
    UAInAppMessageBannerDisplayContent *displayContent = (UAInAppMessageBannerDisplayContent *)self.message.displayContent;
    [UAInAppMessageUtils prepareMediaView:displayContent.media assets:assets completionHandler:^(UAInAppMessagePrepareResult result, UAInAppMessageMediaView *mediaView) {
        if (result == UAInAppMessagePrepareResultSuccess) {
            self.bannerController = [UAInAppMessageBannerController bannerControllerWithBannerMessageID:self.message.identifier
                                                                                         displayContent:displayContent
                                                                                              mediaView:mediaView
                                                                                                  style:self.style];
        }
        completionHandler(result);
    }];
}


- (BOOL)isReadyToDisplay {
    UAInAppMessageBannerDisplayContent* displayContent = (UAInAppMessageBannerDisplayContent *)self.message.displayContent;
    return [UAInAppMessageUtils isReadyToDisplayWithMedia:displayContent.media];
}

- (void)display:(void (^)(UAInAppMessageResolution *))completionHandler {
    if (@available(iOS 13.0, *)) {
        UIWindowScene *scene = [[UAInAppMessageSceneManager shared] sceneForMessage:self.message];
        [self.bannerController showWithParentView:[UAUtils mainWindow:scene]
                                completionHandler:completionHandler];
    } else {
        [self.bannerController showWithParentView:[UAUtils mainWindow]
                                completionHandler:completionHandler];
    }
}

@end

