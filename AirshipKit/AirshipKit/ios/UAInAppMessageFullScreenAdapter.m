/* Copyright 2017 Urban Airship and Contributors */

#import "UAGlobal.h"
#import "UAInAppMessageFullScreenAdapter.h"
#import "UAInAppMessageFullScreenDisplayContent+Internal.h"
#import "UAInAppMessageFullScreenController+Internal.h"
#import "UAInAppMessageUtils+Internal.h"

@interface UAInAppMessageFullScreenAdapter ()
@property (nonatomic, strong) UAInAppMessage *message;
@property (nonatomic, strong) UAInAppMessageFullScreenController *fullScreenController;
@property (nonatomic, strong) NSCache *imageCache;
@end

NSString *const UAInAppMessageFullScreenAdapterCacheName = @"UAInAppMessageFullScreenAdapterCache";

@implementation UAInAppMessageFullScreenAdapter

+ (instancetype)adapterForMessage:(UAInAppMessage *)message {
    return [[UAInAppMessageFullScreenAdapter alloc] initWithMessage:message];
}

-(instancetype)initWithMessage:(UAInAppMessage *)message {
    self = [super init];

    if (self) {
        self.message = message;
        self.imageCache = [[NSCache alloc] init];
        [self.imageCache setName:UAInAppMessageFullScreenAdapterCacheName];
        [self.imageCache setCountLimit:1];
    }

    return self;
}

- (void)prepare:(void (^)(void))completionHandler {
    UAInAppMessageFullScreenDisplayContent *displayContent = (UAInAppMessageFullScreenDisplayContent *)self.message.displayContent;

    if (!displayContent.media) {
        self.fullScreenController = [UAInAppMessageFullScreenController fullScreenControllerWithFullScreenMessageID:self.message.identifier
                                                                                                     displayContent:displayContent
                                                                                                              image:nil];

        completionHandler();
        return;
    }

    NSURL *mediaURL = [NSURL URLWithString:displayContent.media.url];

    // Prefetch image save as file copy what message center does
    [UAInAppMessageUtils prefetchContentsOfURL:mediaURL
                                     WithCache:self.imageCache
                             completionHandler:^(NSString *cacheKey) {

                                 NSData *data = [self.imageCache objectForKey:cacheKey];
                                 if (data) {
                                     UIImage *prefetchedImage = [UIImage imageWithData:data];
                                     self.fullScreenController = [UAInAppMessageFullScreenController fullScreenControllerWithFullScreenMessageID:self.message.identifier
                                                                                                                                  displayContent:displayContent
                                                                                                                                           image:prefetchedImage];
                                 }

                                 completionHandler();
                             }];
}

- (void)display:(void (^)(void))completionHandler {
    if (!self.fullScreenController) {
        UA_LDEBUG(@"Attempted to display an in-app message with a nil full screen controller. This means an app state change likely interrupted the prepare and display cycle before display could occur.");
        completionHandler();
        return;
    }

    [self.fullScreenController show:^() {
        completionHandler();
    }];
}

- (void)dealloc {
    if (self.imageCache) {
        [self.imageCache removeAllObjects];
    }

    self.imageCache = nil;
}

@end

