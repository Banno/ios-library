/* Copyright 2017 Urban Airship and Contributors */

#import "UAGlobal.h"
#import "UAInAppMessageModalAdapter.h"
#import "UAInAppMessageModalDisplayContent+Internal.h"
#import "UAInAppMessageModalViewController+Internal.h"
#import "UAInAppMessageUtils+Internal.h"

@interface UAInAppMessageModalAdapter ()
@property (nonatomic, strong) UAInAppMessage *message;
@property (nonatomic, strong) UAInAppMessageModalViewController *modalController;
@property (nonatomic, strong) NSCache *imageCache;
@end

NSString *const UAInAppMessageModalAdapterCacheName = @"UAInAppMessageModalAdapterCache";

@implementation UAInAppMessageModalAdapter

+ (instancetype)adapterForMessage:(UAInAppMessage *)message {
    return [[UAInAppMessageModalAdapter alloc] initWithMessage:message];
}

-(instancetype)initWithMessage:(UAInAppMessage *)message {
    self = [super init];
    
    if (self) {
        self.message = message;
        self.imageCache = [[NSCache alloc] init];
        [self.imageCache setName:UAInAppMessageModalAdapterCacheName];
        [self.imageCache setCountLimit:1];
    }
    
    return self;
}

- (void)prepare:(void (^)(UAInAppMessagePrepareResult result))completionHandler {
    UAInAppMessageModalDisplayContent *displayContent = (UAInAppMessageModalDisplayContent *)self.message.displayContent;
    
    if (!displayContent.media) {
        self.modalController = [UAInAppMessageModalViewController modalControllerWithModalMessageID:self.message.identifier
                                                                                                     displayContent:displayContent
                                                                                                              image:nil];
        
        completionHandler(UAInAppMessagePrepareResultSuccess);
        return;
    }
    
    NSURL *mediaURL = [NSURL URLWithString:displayContent.media.url];
    
    // Prefetch image save as file copy what message center does
    UA_WEAKIFY(self);
    [UAInAppMessageUtils prefetchContentsOfURL:mediaURL
                                     WithCache:self.imageCache
                             completionHandler:^(NSString *cacheKey) {
                                 UA_STRONGIFY(self);
                                 NSData *data = [self.imageCache objectForKey:cacheKey];
                                 if (data) {
                                     UIImage *prefetchedImage = [UIImage imageWithData:data];
                                     self.modalController = [UAInAppMessageModalViewController modalControllerWithModalMessageID:self.message.identifier
                                                                                                                            displayContent:displayContent
                                                                                                                                     image:prefetchedImage];
                                 }
                                 
                                 completionHandler(UAInAppMessagePrepareResultSuccess);
                             }];

}

- (void)display:(void (^)(void))completionHandler {
    if (!self.modalController) {
        UA_LDEBUG(@"Attempted to display an in-app message with a nil modal controller. This means an app state change likely interrupted the prepare and display cycle before display could occur.");
        completionHandler();
        return;
    }
    
    [self.modalController show:^() {
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


