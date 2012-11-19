#import "ParameterSliderView.h"
#import <QuartzCore/QuartzCore.h>

#define PARAMETER_VIEW_HEIGHT_SCALE     0.5
#define DEFAULT_MIN_VALUE               0.0
#define DEFAULT_MAX_VALUE               1.0
#define DEFAULT_INITIAL_VALUE           0.5

@interface ParameterSliderView (PrivateAPI)

- (void)valueChanged;
- (void)drawParameterViewBorder;
- (void)addSubviews;

@end

@implementation ParameterSliderView

@synthesize delegate, parameterView, parameterViewBorder, panGesture, maxValue, minValue, initialValue, parameterViewFrame;

#pragma mark -
#pragma mark ParameterSlider PrivateAPI

- (void)valueChanged:(UIPanGestureRecognizer*)_panGesture {
    CGPoint dragDelta = [_panGesture translationInView:self];
    CGFloat newWidth = self.parameterViewFrame.size.width + dragDelta.x;
    if (newWidth < 0.0) {
        newWidth = 0.0;
    } else if (newWidth > self.frame.size.width) {
        newWidth = self.frame.size.width;
    }
    switch (_panGesture.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
            self.parameterView.frame = CGRectMake(0.0, self.parameterViewFrame.origin.y, newWidth, self.parameterViewFrame.size.height);
            break;
        case UIGestureRecognizerStateEnded:
            self.parameterViewFrame = self.parameterView.frame;
            [self.delegate parameterSliderValueChanged:self];
            break;
        default:
            break;
    }
}

- (void)addSubviews {
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(valueChanged:)];
    [self addGestureRecognizer:self.panGesture];
    self.parameterViewFrame = CGRectMake(0.0, 0.5 * self.frame.size.height * (1.0 - PARAMETER_VIEW_HEIGHT_SCALE), 0.5 * self.frame.size.width, PARAMETER_VIEW_HEIGHT_SCALE * self.frame.size.height);
    self.parameterView = [[UIView alloc] initWithFrame:self.parameterViewFrame];
    self.parameterView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.parameterView];
    self.parameterViewBorder = [[UIView alloc] initWithFrame:CGRectMake(-1.0, self.parameterView.frame.origin.y - 1.0, self.frame.size.width + 2.0, self.parameterView.frame.size.height + 2.0)];
    [self addSubview:self.parameterViewBorder];
    self.backgroundColor = [UIColor clearColor];
    self.initialValue = self.initialValue;
    self.parameterViewBorder.layer.borderColor = [UIColor whiteColor].CGColor;
    self.parameterViewBorder.layer.borderWidth = 1.0f;    
    
}

#pragma mark -
#pragma mark ParameterSlider

+ (id)withFrame:(CGRect)_frame {
    ParameterSliderView* sliderView = [[ParameterSliderView alloc] initWithFrame:_frame];
    return sliderView;
}

- (id)initWithCoder:(NSCoder*)coder { 
    self = [super initWithCoder:coder];
    if (self) {
        [self addSubviews];
    }
    return self;
}

- (id)initWithFrame:(CGRect)_frame { 
    self = [super initWithFrame:_frame];
    if (self) {
        [self addSubviews];
    }
    return self;
}

- (void)setIntialValue {
    self.parameterView.frame = CGRectMake(0.0, 
                                          0.5 * self.frame.size.height * (1.0 - PARAMETER_VIEW_HEIGHT_SCALE), 
                                          (self.initialValue - self.minValue) / (self.maxValue - self.minValue) * self.frame.size.width, 
                                          PARAMETER_VIEW_HEIGHT_SCALE * self.frame.size.height);
    self.parameterViewFrame = self.parameterView.frame;
}

- (CGFloat)value {
    CGFloat parameterWidth = self.parameterViewFrame.size.width / self.frame.size.width;
    return parameterWidth * (self.maxValue - self.minValue) + self.minValue;  
}

@end
