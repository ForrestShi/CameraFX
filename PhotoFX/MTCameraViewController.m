#import "MTCameraViewController.h"
//http://mobile.tutsplus.com/tutorials/iphone/enhancing-a-photo-app-with-gpuimage-icarousel/
#import "CameraFXManager.h"
#import "FSGPUImageFilterManager.h"
#import "PreviewFilterViewController.h"
#import "MBProgressHUD.h"
#import "ParameterSliderView.h"

@interface MTCameraViewController () <UIActionSheetDelegate, UIGestureRecognizerDelegate , PreviewFilterDelegate , ParameterSliderViewDelegate>
{
    GPUImageStillCamera *stillCamera;
    GPUImageFilter *filter;
    
    PreviewFilterViewController *previewFiltersVC;
    ParameterSliderView         *sliderView;
}
@property (nonatomic,weak) IBOutlet UIBarButtonItem *filterItem;
@property (nonatomic,weak) IBOutlet UIButton *switchButton;
@property (nonatomic,weak) IBOutlet UIButton *backButton;
@property (nonatomic,weak) IBOutlet UIToolbar *toolBar;
@property (nonatomic,weak) IBOutlet UIView *cameraView;

- (IBAction)captureImage:(id)sender;
- (IBAction)switchCamera:(id)sender;
- (IBAction)back:(id)sender;

@end

@implementation MTCameraViewController 
@synthesize delegate;
@synthesize filterItem;
@synthesize cameraView;

#pragma mark -
#pragma mark View Controller Lifecycle


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    DLog(@"...");
    [self.navigationController setNavigationBarHidden:YES];
    
    if (filter == nil || ![filter isKindOfClass:[GPUImageSepiaFilter class]]) {
        if (sliderView) {
            sliderView.hidden = YES;
        }
    }else{
        if (sliderView) {
            sliderView.hidden = NO; 
        }
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:YES];
    
    UIImage *modelImage = [UIImage imageNamed:@"s2.png"];
    previewFiltersVC = [[PreviewFilterViewController alloc] initWithProcessedImage:modelImage dynamic:NO];
    previewFiltersVC.delegate = self;

    if (!filter) {
        // Setup initial camera filter
        filter = [[CameraFXManager sharedInstance] filter];
        //[filter prepareForImageCapture];
        GPUImageView *filterView = (GPUImageView *)self.cameraView;
        [filter addTarget:filterView];

    }

    // Create custom GPUImage camera
    if (!stillCamera) {
        stillCamera =[[CameraFXManager sharedInstance] stillCamera];
        [stillCamera addTarget:filter];
        
        // Begin showing video camera stream
        [stillCamera startCameraCapture];
 
    }
    
    CGSize viewSize = self.view.frame.size;
    
    sliderView = [[ParameterSliderView alloc] initWithFrame:CGRectMake(IS_IPAD ? 100. : 40., viewSize.height/2,viewSize.width - (IS_IPAD ? 100. : 40 )*2 , IS_IPAD ? 22. : 14.)];
    sliderView.delegate = self;
    [sliderView setInitialValue:0.5]; // 0. -- 1.
    [sliderView setMaxValue:1.];
    [sliderView setMinValue:0.];
    
    [self.view addSubview:sliderView];
    
    if ([stillCamera isFrontFacingCameraPresent] == NO ) {
        self.switchButton.hidden = YES;
    }
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    doubleTap.delegate = self;
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.numberOfTouchesRequired = 1;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    singleTap.delegate = self;
    singleTap.numberOfTapsRequired = 1;
    singleTap.numberOfTouchesRequired = 1;

    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    panGesture.delegate = self;
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onPinch:)];
    pinchGesture.delegate = self;

    UIRotationGestureRecognizer *roateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(onRotate:)];
    roateGesture.delegate = self;
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressing:)];
    [longPressGesture setMinimumPressDuration:1.];
    longPressGesture.delegate = self;

    [singleTap requireGestureRecognizerToFail:panGesture];
    [self.view addGestureRecognizer:singleTap];
    [self.view addGestureRecognizer:doubleTap];
    [self.view addGestureRecognizer:pinchGesture];
    [self.view addGestureRecognizer:roateGesture];
    [self.view addGestureRecognizer:longPressGesture];
    //[self.view addGestureRecognizer:panGesture];
    //[sliderView addGestureRecognizer:panGesture];
    
}

- (void)singleTap:(UITapGestureRecognizer*)gesture{
    @synchronized(self){
        self.cameraView.transform = CGAffineTransformIdentity;

        static BOOL hideCtrls = NO;
        [UIView animateWithDuration:0.3 animations:^{
            if ([stillCamera isFrontFacingCameraPresent]) {
                self.switchButton.alpha = hideCtrls ? 0.:1.;
            }
            self.backButton.alpha = hideCtrls ? 0.:1.;
            sliderView.alpha = hideCtrls ? 0.:1.;
            
            hideCtrls = !hideCtrls;
        }];
    }
}

- (void)onLongPressing:(UILongPressGestureRecognizer*)gesture{
    if (gesture.state == UIGestureRecognizerStateBegan) {
    }else if(gesture.state == UIGestureRecognizerStateEnded){
        
    }
}

- (IBAction)back:(id)sender{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)switchCamera:(id)sender{
    if (stillCamera) {
        DLog(@"switch camera");
        
        CATransition *animation = [CATransition animation];
        animation.delegate = self;
        animation.duration = .3;
        animation.timingFunction = UIViewAnimationCurveEaseInOut;
        animation.type = @"cameraIris";
        //animation.type = @"flip";
        //animation.subtype = @"fromLeft";
        [self.view.layer addAnimation:animation forKey:nil];
        
        [stillCamera rotateCamera];
    }
}

- (void)onPinch:(UIPinchGestureRecognizer*)gesture{
    
    self.cameraView.transform = CGAffineTransformScale(self.cameraView.transform, [gesture scale], [gesture scale]);
    gesture.scale = 1.;
}

- (void)onRotate:(UIRotationGestureRecognizer*)gesture{
    //float angle = atan2f(self.cameraView.transform.b, self.cameraView.transform.a) + gesture.rotation;
    self.cameraView.transform = CGAffineTransformRotate(self.cameraView.transform, [gesture rotation]*M_PI/180.);
}

- (void)doubleTap:(UITapGestureRecognizer*)gesture{
    //short cut to capture
    self.cameraView.transform = CGAffineTransformIdentity;
    [self captureImage:nil];
}

- (void)onPan:(UIPanGestureRecognizer*)gesture{
    DLog(@"%@",@"paning");
    //TODO: transfer all pan event to sliderview 
}

-(void)parameterSliderValueChanged:(ParameterSliderView*)_parameterSlider{
    DLog(@"slider %f",sliderView.value);
    if (filter) {
        //        if ([filter isKindOfClass:[GPUImageSmoothToonFilter class]]) {
        //            GPUImageSmoothToonFilter *toonFilter = (GPUImageSmoothToonFilter*)filter;
        //            [toonFilter setBlurSize:slider.value];
        //        }
        if ([filter isKindOfClass:[GPUImageSepiaFilter class]]) {
            GPUImageSepiaFilter *sepiaFilter = (GPUImageSepiaFilter*)filter;
            [sepiaFilter setIntensity:sliderView.value * 3. ];
        }
    }

}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    

    if (CGRectContainsPoint(self.filterItem.customView.frame, [gestureRecognizer locationInView:self.view]) || CGRectContainsPoint(self.switchButton.frame, [gestureRecognizer locationInView:self.view] ) || CGRectContainsPoint(self.backButton.frame, [gestureRecognizer locationInView:self.view] ) || CGRectContainsPoint(self.toolBar.frame, [gestureRecognizer locationInView:self.view] ) )
    {
        return NO;
    }
    return YES;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Only support portrati orientation
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

#pragma mark -
#pragma mark IBAction Methods

- (IBAction)applyImageFilter:(id)sender
{
    if (previewFiltersVC) {
        //[self.navigationController pushViewController:previewFiltersVC animated:YES];
        previewFiltersVC.modalTransitionStyle = UIModalTransitionStylePartialCurl;
        [self presentModalViewController:previewFiltersVC animated:YES];
    }
}

- (void) selectImageWithFilterType:(GPUImageShowcaseFilterType)filterType{
     
    [stillCamera removeAllTargets];
    [filter removeAllTargets];
    
    GPUImageFilter *selectedFilter = [[FSGPUImageFilterManager sharedFSGPUImageFilterManager] createGPUImageFilter:filterType];
    filter = selectedFilter;
    GPUImageView *filterView = (GPUImageView *)self.cameraView;
    [filter addTarget:filterView];
    [stillCamera addTarget:filter];
    
    if (filter == nil || ![filter isKindOfClass:[GPUImageSepiaFilter class]]) {
        if (sliderView) {
            sliderView.hidden = YES;
        }
    }else{
        if (sliderView) {
            sliderView.hidden = NO;
        }
    }

    [self dismissModalViewControllerAnimated:YES];
}



-(IBAction)captureImage:(id)sender
{
    // Disable to prevent multiple taps while processing
    UIButton *captureButton = (UIButton *)sender;
    //captureButton.enabled = NO;
    
    // Snap Image from GPU camera, send back to main view controller
    [stillCamera capturePhotoAsPNGProcessedUpToFilter:filter withCompletionHandler:^(NSData *processedPNG, NSError *error)
     {
         if([self.delegate respondsToSelector:@selector(didSelectStillImage:withError:)])
         {
             [self.delegate didSelectStillImage:processedPNG withError:error];
         }
         else
         {
             DLog(@"Delegate did not respond to message");
         }

         [stillCamera removeAllTargets];
         [filter removeAllTargets];

         runOnMainQueueWithoutDeadlocking(^{
             
             captureButton.enabled = YES;

             [self.navigationController popToRootViewControllerAnimated:YES];
         });
     }];
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Bail if the cancel button was tapped
    if(actionSheet.cancelButtonIndex == buttonIndex)
    {
        return;
    }
    
    [stillCamera removeAllTargets];
    [filter removeAllTargets];

    GPUImageFilter *selectedFilter;
    GPUImageShowcaseFilterType fitlerEnumType;
    
    switch (buttonIndex) {
        case 0:
            fitlerEnumType = GPUIMAGE_SEPIA;
            break;
        case 1:
            fitlerEnumType = GPUIMAGE_SKETCH;
            break;
        case 2:
            fitlerEnumType = GPUIMAGE_VIGNETTE;
            break;
        case 3:
            fitlerEnumType = GPUIMAGE_SMOOTHTOON;
            break;
        case 4:
            fitlerEnumType = GPUIMAGE_POSTERIZE;
            break;
        case 5:
            fitlerEnumType = GPUIMAGE_BULGE;
            break;
        case 6:
            fitlerEnumType = GPUIMAGE_PINCH;
            break;
        case 7:
            fitlerEnumType = GPUIMAGE_FASTBLUR;
            break;
        case 8:
            fitlerEnumType = GPUIMAGE_COLORINVERT;
            break;
        case 9:
            fitlerEnumType = GPUIMAGE_GRAYSCALE;
            break;
        case 10:
            fitlerEnumType = GPUIMAGE_EMBOSS;
            break;
        default:
            fitlerEnumType = GPUIMAGE_SEPIA;
            break;
    }
    
    selectedFilter = [[FSGPUImageFilterManager sharedFSGPUImageFilterManager] createGPUImageFilter:fitlerEnumType];

    UISlider *slider0 = (UISlider*)[self.view viewWithTag:1001];
    if (![selectedFilter isKindOfClass:[GPUImageSepiaFilter class]]) {
        [UIView animateWithDuration:0.3 animations:^{
            slider0.alpha = 0.;
        }];

    }else{
        slider0.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            slider0.alpha = 1.;
        }];

    }
    filter = selectedFilter;
    GPUImageView *filterView = (GPUImageView *)self.cameraView;
    [filter addTarget:filterView];
    [stillCamera addTarget:filter];
    
}

@end
