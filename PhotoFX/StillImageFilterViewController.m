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

@interface StillImageFilterViewController ()<CMPopTipViewDelegate,UIGestureRecognizerDelegate>{
    UIImageView *processImgView;
    GPUImageFilter *_curFilter;
}
@property (nonatomic,strong) CMPopTipView *roundRectButtonPopTipView;
@end

@implementation StillImageFilterViewController
@synthesize processImage,delegate;
@synthesize roundRectButtonPopTipView;

- (id)initWithImage:(UIImage*)image withFilter:(GPUImageFilter*)filter{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.processImage = image;
        _curFilter = filter;
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

//#if defined(TOONCAM_PRO) || defined(SEPIACAM_PRO)
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    panGesture.delegate = self;
    [self.view addGestureRecognizer:panGesture];
//#elif defined(FUNCAM_PRO)
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
    tap.delegate = self;
    //[self.view addGestureRecognizer:tap];
//#endif
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
    [tap requireGestureRecognizerToFail:doubleTap];

    UIButton *tipBtn = [UIButton buttonWithType:UIButtonTypeInfoDark];
    tipBtn.frame = CGRectMake(self.view.bounds.size.width - 60., 50., 44., 44.);
    tipBtn.autoresizesSubviews = YES;
    
    [tipBtn addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:tipBtn];
    [self buttonAction:tipBtn];

    
}

- (void)onTap:(UITapGestureRecognizer*)gesture{
    
    CGPoint touchPoint = [gesture locationInView:self.view];
    
    if (gesture.state == UIGestureRecognizerStateEnded){
        
        if ([_curFilter isKindOfClass:[GPUImageBulgeDistortionFilter class]]){
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            GPUImageBulgeDistortionFilter *curFilter = [[GPUImageBulgeDistortionFilter alloc] init];
            curFilter.center = CGPointMake(touchPoint.x/self.view.bounds.size.width, touchPoint.y/self.view.bounds.size.height);
            UIImage *newImg = [curFilter imageByFilteringImage:self.processImage];
            [processImgView setImage:newImg];
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            
        }        
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
      
        NSString *message = @"Tips:1.Return back by top touch.2.Adjust effect by paning left/right. 3.Save and return by double taps.";
#if defined(FUNCAM_PRO)
        message = @"Tips: 1.Return by touch the top. 2.Adjust effect by single tap.  3.Save photo by double taps.";
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

static float intensity = 0.5;

- (void)onPan:(UIPanGestureRecognizer*)gesture{
    
    CGPoint translate = [gesture translationInView:self.view];
    
    UIImage *newImg = nil;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }else if (gesture.state == UIGestureRecognizerStateEnded){
        
        intensity += translate.x/self.view.bounds.size.width/10.;
        intensity = MIN(1.0, MAX(0.,intensity));
        
        if ([_curFilter isKindOfClass:[GPUImageSepiaFilter class]] ) {
            
            GPUImageSepiaFilter *sepiaFlt = [[GPUImageSepiaFilter alloc] init];
            DLog(@"update image %f",intensity);
            [sepiaFlt setIntensity:intensity];
            newImg = [sepiaFlt imageByFilteringImage:self.processImage];
        }else if ([_curFilter isKindOfClass:[GPUImageSmoothToonFilter class]]){
            
            GPUImageSmoothToonFilter *filter = [[GPUImageSmoothToonFilter alloc] init];
            DLog(@"update image %f",intensity);
            [filter setBlurSize:0.5+intensity];
            [filter setThreshold:0.2+ (intensity - 0.5)/5.];  // 0.1 -- 0.3 
            newImg = [filter imageByFilteringImage:self.processImage];
        }else if ([_curFilter isKindOfClass:[GPUImageBulgeDistortionFilter class]]){
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            CGPoint touchPoint = [gesture locationInView:self.view];

            GPUImageBulgeDistortionFilter *curFilter = [[GPUImageBulgeDistortionFilter alloc] init];
            curFilter.center = CGPointMake(touchPoint.x/self.view.bounds.size.width, touchPoint.y/self.view.bounds.size.height);
            newImg = [curFilter imageByFilteringImage:self.processImage];            
        }
        
        [processImgView setImage:newImg];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];

    }else if (gesture.state == UIGestureRecognizerStateChanged){
    }
    

}

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return YES;
}

@end
