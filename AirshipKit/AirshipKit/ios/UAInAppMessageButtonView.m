/* Copyright 2017 Urban Airship and Contributors */

#import "UAirship.h"
#import "UAInAppMessageButtonView+Internal.h"
#import "UAColorUtils+Internal.h"
#import "UAInAppMessageUtils+Internal.h"
#import "UAInAppMessageBannerDisplayContent.h"
#import "UAInAppMessageButton+Internal.h"
#import "UAColorUtils+Internal.h"

// UAInAppMessageButtonView nib name
NSString *const UAInAppMessageButtonViewNibName = @"UAInAppMessageButtonView";

@interface UAInAppMessageButtonView ()
@property(nonatomic, strong) NSString *buttonLayout;
@property (strong, nonatomic) IBOutlet UIStackView *buttonContainer;
@property (strong, nonatomic) UIColor *dismissButtonColor;

@end

@implementation UAInAppMessageButtonView

+ (instancetype)buttonViewWithButtons:(NSArray<UAInAppMessageButtonInfo *> *)buttons
                               layout:(UAInAppMessageButtonLayoutType)layout
                               target:(id)target
                             selector:(SEL)selector
                   dismissButtonColor:(UIColor *)dismissButtonColor {
    return [[UAInAppMessageButtonView alloc] initWithButtons:buttons
                                                      layout:layout
                                                      target:target
                                                    selector:selector
                                          dismissButtonColor:dismissButtonColor];
}

- (instancetype)initWithButtons:(NSArray<UAInAppMessageButtonInfo *> *)buttons
                         layout:(UAInAppMessageButtonLayoutType)layout
                         target:(id)target
                       selector:(SEL)selector
             dismissButtonColor:(UIColor *)dismissButtonColor {

    self = [super init];

    NSString *nibName = UAInAppMessageButtonViewNibName;
    NSBundle *bundle = [UAirship resources];

    // Joined, Separate and Stacked views object at index 0,1,2, respectively.
    switch (layout) {
        case UAInAppMessageButtonLayoutTypeJoined:
            self = [[bundle loadNibNamed:nibName owner:self options:nil] objectAtIndex:0];
            break;
        case UAInAppMessageButtonLayoutTypeSeparate:
            self = [[bundle loadNibNamed:nibName owner:self options:nil] objectAtIndex:1];
            break;
        case UAInAppMessageButtonLayoutTypeStacked:
            self = [[bundle loadNibNamed:nibName owner:self options:nil] objectAtIndex:2];
            break;
    }

    if (self) {
        self.dismissButtonColor = dismissButtonColor;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self addButtons:buttons layout:layout target:target selector:selector];
    }

    return self;

}

- (void)addButtons:(NSArray<UAInAppMessageButtonInfo *> *)buttons
            layout:(UAInAppMessageButtonLayoutType)layout
            target:(id)target
          selector:(SEL)selector {
    if (!self.buttonContainer) {
        UA_LDEBUG(@"Button view container stack is nil");
        return;
    }

    if (!target) {
        UA_LDEBUG(@"Buttons require a target");
        return;
    }

    if (!selector) {
        UA_LDEBUG(@"Buttons require a selector");
        return;
    }

    NSUInteger buttonOrder = 0;
    for (UAInAppMessageButtonInfo *buttonInfo in buttons) {
        UAInAppMessageButton *button;

        // This rounds to the desired border radius which is 0 by default
        NSUInteger rounding = UAInAppMessageButtonRoundingOptionAllCorners;
        if (layout == UAInAppMessageButtonLayoutTypeJoined) {
            if (buttonOrder == 0) {
                rounding = UAInAppMessageButtonRoundingTopLeftCorner | UAInAppMessageButtonRoundingBottomLeftCorner;
            }
            if (buttonOrder == 1) {
                rounding = UAInAppMessageButtonRoundingTopRightCorner | UAInAppMessageButtonRoundingBottomRightCorner;
            }
        }

        button = [UAInAppMessageButton buttonWithButtonInfo:buttonInfo
                                                   rounding:rounding];

        [UAInAppMessageUtils applyButtonInfo:buttonInfo button:button];
        [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];

        // Customize button background color if it has dismiss behavior, otherwise fall back to button color
        if (buttonInfo.behavior == UAInAppMessageButtonInfoBehaviorDismiss) {
            button.backgroundColor = self.dismissButtonColor ?: buttonInfo.backgroundColor;
        } else {
            button.backgroundColor = buttonInfo.backgroundColor;
        }

        [self.buttonContainer addArrangedSubview:button];
        [self.buttonContainer layoutIfNeeded];
        buttonOrder++;
    }

    if (self.buttonContainer.subviews.count == 0) {
        [self.buttonContainer removeFromSuperview];
    }
}

@end
