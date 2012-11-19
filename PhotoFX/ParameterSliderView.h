#import <UIKit/UIKit.h>

@protocol ParameterSliderViewDelegate;

@interface ParameterSliderView : UIView

@property(nonatomic, weak)   id<ParameterSliderViewDelegate>    delegate;
@property(nonatomic, strong) UIView*                            parameterView;
@property(nonatomic, strong) UIView*                            parameterViewBorder;
@property(nonatomic, strong) UIPanGestureRecognizer*            panGesture;
@property(nonatomic, assign) CGFloat                            maxValue;
@property(nonatomic, assign) CGFloat                            minValue;
@property(nonatomic, assign) CGFloat                            initialValue;
@property(nonatomic, assign) CGRect                             parameterViewFrame;

- (CGFloat)value;
- (void)setIntialValue;

@end

@protocol ParameterSliderViewDelegate

-(void)parameterSliderValueChanged:(ParameterSliderView*)_parameterSlider;

@end
