/* Copyright 2017 Urban Airship and Contributors */

#import <UIKit/UIKit.h>
#import "UAirship.h"
#import "UAInAppMessageBannerContentView+Internal.h"
#import "UAInAppMessageBannerDisplayContent+Internal.h"
#import "UAInAppMessageTextView+Internal.h"
#import "UAInAppMessageMediaView+Internal.h"
#import "UAInAppMessageUtils+Internal.h"

NSString *const UAInAppMessageBannerContentViewNibName = @"UAInAppMessageBannerContentView";

@interface UAInAppMessageBannerContentView ()

// Subviews
@property(nonatomic, strong) IBOutlet UIView *imageContainerView;
@property(nonatomic, strong) IBOutlet UIView *textContainerView;
@property (nonatomic, strong) IBOutlet UIView *containerView;

@end

@implementation UAInAppMessageBannerContentView

+ (instancetype)contentViewWithLayout:(NSString *)contentLayout textView:(UAInAppMessageTextView *)textView image:(UIImage *)image {
    return [[self alloc] initContentViewWithLayout:contentLayout textView:textView image:image];
}

- (instancetype)initContentViewWithLayout:(NSString *)contentLayout textView:(UAInAppMessageTextView *)textView image:(UIImage *)image {

    NSString *nibName = UAInAppMessageBannerContentViewNibName;
    NSBundle *bundle = [UAirship resources];
    
    // Left and right IAM views are firstObject and lastObject, respectively.
    if ([contentLayout isEqualToString:UAInAppMessageBannerContentLayoutMediaLeft]) {
        self = [[bundle loadNibNamed:nibName owner:self options:nil] firstObject];
    } else if ([contentLayout isEqualToString:UAInAppMessageBannerContentLayoutMediaRight]) {
        self = [[bundle loadNibNamed:nibName owner:self options:nil] lastObject];
    } else {
        UA_LWARN(@"Invalid content layout for banner content view");
    }
    
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.userInteractionEnabled = NO;
        
        self.backgroundColor = [UIColor clearColor];
        
        self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
        self.containerView.backgroundColor = [UIColor clearColor];

        if (image) {
            [self addImage:image];
        } else {
            [self.imageContainerView removeFromSuperview]; //remove constraints
        }

        [self addTextView:textView];

        [self.textContainerView layoutIfNeeded];
        [self.imageContainerView layoutIfNeeded];
        [self layoutIfNeeded];
    }
    
    return self;
}

- (void)addTextView:(UAInAppMessageTextView *)textView {
    [self.textContainerView addSubview:textView];
    [UAInAppMessageUtils applyContainerConstraintsToContainer:self.textContainerView containedView:textView];
}

- (void)addImage:(UIImage *)image {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];

    [self.imageContainerView addSubview:imageView];
    [UAInAppMessageUtils applyContainerConstraintsToContainer:self.imageContainerView containedView:imageView];
}

@end
