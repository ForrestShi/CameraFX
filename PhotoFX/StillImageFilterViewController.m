//
//  StillImageFilterViewController.m
//  PhotoFX
//
//  Created by forrest on 12-11-25.
//  Copyright (c) 2012年 Mobiletuts. All rights reserved.
//

#import "StillImageFilterViewController.h"
#import "MBProgressHUD.h"
#import "CMPopTipView.h"
#import "MTCameraViewController.h"

@interface StillImageFilterViewController ()<CMPopTipViewDelegate>{
    UIImageView *processImgView;
    GPUImageShowcaseFilterType _filterType;
}
@property (nonatomic,strong) CMPopTipView *roundRectButtonPopTipView;
@end

@implementation StillImageFilterViewController
@synthesize processImage,delegate;
@synthesize roundRectButtonPopTipView;

- (id)initWithImage:(UIImage*)image andFilterType:(GPUImageShowcaseFilterType)filterType{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.processImage = image;
        _filterType = filterType;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (UISlider*)customizedSliderFromFrame:(CGRect)frame{
    UIImage* sliderBarImage = [UIImage imageNamed:@"slider_bar_21.png"];
    UIImage* sliderThumbImage= [UIImage imageNamed:@"slider_thumb_21.png"];
    sliderBarImage=[sliderBarImage stretchableImageWithLeftCapWidth:8.0 topCapHeight:0.0];
    UISlider *slider = [[UISlider alloc] initWithFrame:frame];
    [slider setMinimumTrackImage:sliderBarImage forState:UIControlStateNormal];
    [slider setMaximumTrackImage:sliderBarImage forState:UIControlStateNormal];
    [slider setThumbImage:sliderThumbImage forState:UIControlStateNormal];
    [slider setMinimumValue:0.001];
    [slider setMaximumValue:1.];
    [slider setValue:.5];
    return slider;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    processImgView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:self.processImage.CGImage]];
    processImgView.autoresizingMask = YES;
    processImgView.contentMode = UIViewContentModeScaleAspectFit;
    processImgView.frame = self.view.frame;
    [self.view addSubview:processImgView];
    
#if defined(SEPIACAM_PRO)
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    [self.view addGestureRecognizer:panGesture];
#elif defined(TOONCAM_PRO)
    float w = self.view.bounds.size.width;    float h = self.view.bounds.size.height;
    float p = IS_IPAD ? 60.:40;
    UISlider *slider1 = [self customizedSliderFromFrame:CGRectMake(w*0.2, h*0.7, w*0.6, 20)];
    UISlider *slider2 = [self customizedSliderFromFrame:CGRectMake(w*0.2, h*0.7 + p, w*0.6, 20)];
    UISlider *slider3 = [self customizedSliderFromFrame:CGRectMake(w*0.2, h*0.7+ p*2, w*0.6, 20)];
    [slider1 addTarget:self action:@selector(onSlider1:) forControlEvents:UIControlEventTouchDown];
    [slider2 addTarget:self action:@selector(onSlider2:) forControlEvents:UIControlEventTouchDown];
    [slider3 addTarget:self action:@selector(onSlider3:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:slider1];
    [self.view addSubview:slider2];
    [self.view addSubview:slider3];
    
#endif
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
    
    UIButton *tipBtn = [UIButton buttonWithType:UIButtonTypeInfoDark];
    tipBtn.frame = CGRectMake(self.view.bounds.size.width - 60., 50., 44., 44.);
    [tipBtn addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:tipBtn];
    
}
static float blur = 0.2;
static float threshold = 0.5;
static float quanize = 10.;

- (void)onSlider1:(UISlider*)slider{
    blur = slider.value;
    [self adjustToonFilter];
}
- (void)onSlider2:(UISlider*)slider{
    threshold = slider.value;
    [self adjustToonFilter];
}
- (void)onSlider3:(UISlider*)slider{
    quanize = slider.value*10 + 5.;
    [self adjustToonFilter];    
}

- (void)adjustToonFilter{
    @autoreleasepool {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        GPUImageSmoothToonFilter* imageFilter = [[GPUImageSmoothToonFilter alloc] init];
        [imageFilter setBlurSize:blur];
        [imageFilter setThreshold:threshold];
        [imageFilter setQuantizationLevels:quanize];
        UIImage  *newImg = [imageFilter imageByFilteringImage:self.processImage];
        [processImgView setImage:newImg];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }
}

- (void)doubleTap{
    
    if([self.delegate respondsToSelector:@selector(updateStillImage:)])
    {
        self.processImage = processImgView.image;
        [self.delegate updateStillImage:self.processImage];
    }
    else
    {
        DLog(@"Delegate did not respond to message");
    }

    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)buttonAction:(id)sender {
    // Toggle popTipView when a standard UIButton is pressed
    if (nil == self.roundRectButtonPopTipView) {
      
        NSString *message = @"";
#if defined(TOONCAM_PRO)
        message = @"Tips:1.Return back by top touch. 2.Save and return by double taps.";
#elif defined(SEPIACAM_RPO)
        message = @"Tips:1.Return back by top touch.2.Adjust effect by paning left/right. 3.Save and return by double taps."
#endif
        self.roundRectButtonPopTipView = [[CMPopTipView alloc] initWithMessage:message];
        self.roundRectButtonPopTipView.delegate = self;
        self.roundRectButtonPopTipView.backgroundColor = [UIColor lightGrayColor];
        self.roundRectButtonPopTipView.textColor = [UIColor darkTextColor];
        self.roundRectButtonPopTipView.alpha = 0.8;
        
        UIButton *button = (UIButton *)sender;
        [self.roundRectButtonPopTipView presentPointingAtView:button inView:self.view animated:YES];
    }
    else {
        // Dismiss
        [self.roundRectButtonPopTipView dismissAnimated:YES];
        self.roundRectButtonPopTipView = nil;
    }
}

#pragma mark CMPopTipViewDelegate methods
- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView {
    // User can tap CMPopTipView to dismiss it
    self.roundRectButtonPopTipView = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onPan:(UIPanGestureRecognizer*)gesture{
    
    CGPoint translate = [gesture translationInView:self.view];
    
    UIImage *newImg = nil;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }else if (gesture.state == UIGestureRecognizerStateEnded){
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }else if (gesture.state == UIGestureRecognizerStateChanged){
        
        if (_filterType  == GPUIMAGE_SEPIA ) {
            
            GPUImageSepiaFilter *sepiaFlt = [[GPUImageSepiaFilter alloc] init];
            static float intensity = 1.;
            if (translate.x > 0 ) {
                intensity += fabsf(translate.x)/self.view.bounds.size.width/10.;
                if (intensity > 2.) {
                    intensity = 2.;
                    return;
                }
            }else{
                intensity -= fabsf(translate.x)/self.view.bounds.size.width/10.;
                if (intensity < -1.) {
                    intensity = -1.;
                    return;
                }
            }
            DLog(@"update image %f",intensity);
            
            [sepiaFlt setIntensity:intensity];
            newImg = [sepiaFlt imageByFilteringImage:self.processImage];
            [processImgView setImage:newImg];
        }
    }
}



@end
