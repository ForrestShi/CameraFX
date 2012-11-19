#import "MTCameraViewController.h"
//http://mobile.tutsplus.com/tutorials/iphone/enhancing-a-photo-app-with-gpuimage-icarousel/
#import "CameraFXManager.h"
#import "FSGPUImageFilterManager.h"
#import "PreviewFilterViewController.h"
#import "MBProgressHUD.h"

@interface MTCameraViewController () <UIActionSheetDelegate, UIGestureRecognizerDelegate , PreviewFilterDelegate>
{
    GPUImageStillCamera *stillCamera;
    GPUImageFilter *filter;
    
    PreviewFilterViewController *previewFiltersVC;
}
@property (nonatomic,weak) IBOutlet UIBarButtonItem *filterItem;
@property (nonatomic,weak) IBOutlet UIButton *switchButton;
@property (nonatomic,weak) IBOutlet UIButton *backButton;
@property (nonatomic,weak) IBOutlet UIToolbar *toolBar;

- (IBAction)captureImage:(id)sender;
- (IBAction)adjust0:(id)sender;
- (IBAction)adjust1:(id)sender;
- (IBAction)adjust2:(id)sender;
- (IBAction)switchCamera:(id)sender;
- (IBAction)back:(id)sender;

@end

@implementation MTCameraViewController 
@synthesize delegate;
@synthesize filterItem;

#pragma mark -
#pragma mark View Controller Lifecycle

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    DLog(@"...");
    [self.navigationController setNavigationBarHidden:YES];
    
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
        GPUImageView *filterView = (GPUImageView *)self.view;
        [filter addTarget:filterView];

    }

    // Create custom GPUImage camera
    if (!stillCamera) {
        stillCamera =[[CameraFXManager sharedInstance] stillCamera];
        [stillCamera addTarget:filter];
        
        // Begin showing video camera stream
        [stillCamera startCameraCapture];
 
    }
    
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

    //[singleTap requireGestureRecognizerToFail:panGesture];
    [self.view addGestureRecognizer:singleTap];
    [self.view addGestureRecognizer:doubleTap];

    //[self.view addGestureRecognizer:panGesture];
    
}

- (void)singleTap:(UITapGestureRecognizer*)gesture{
    @synchronized(self){
        static BOOL hideCtrls = NO;
        [UIView animateWithDuration:0.3 animations:^{
            if ([stillCamera isFrontFacingCameraPresent]) {
                self.switchButton.alpha = hideCtrls ? 0.:1.;
            }
            self.backButton.alpha = hideCtrls ? 0.:1.;
            hideCtrls = !hideCtrls;
        }];
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


- (void)doubleTap:(UITapGestureRecognizer*)gesture{
    if (stillCamera && [filter isKindOfClass:[GPUImageSepiaFilter class]] ) {
        DLog(@"show advanced sliders");
        
        static BOOL firstTimeOn = NO;
        firstTimeOn = !firstTimeOn;
        
        UISlider *slider0 = (UISlider*)[self.view viewWithTag:1001];
        [UIView animateWithDuration:0.3 animations:^{
            slider0.alpha = (firstTimeOn ? 0:1.);
        }];

    }
}
- (void)onPan:(UIPanGestureRecognizer*)gesture{
    DLog(@"%@",@"paning");
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        
        if (stillCamera  ) {
            DLog(@"show advanced sliders");
            
            static BOOL firstTimeOn = YES;
            firstTimeOn = !firstTimeOn;
            
            [UIView animateWithDuration:0.3 animations:^{
                for (UIView *v in [self.view subviews]) {
                    //DLog(@"on %d",firstTimeOn);
                    //DLog(@"v %@",v);
                    if (v.tag == 1001 ) {
                        v.alpha = (firstTimeOn == YES ? 0.:1.);
                    }
                }
            }];
            
            
        }

    }

}

//tag: 1001
- (IBAction)adjust0:(id)sender{
    UISlider *slider = (UISlider*)sender;
    
    if (filter) {
//        if ([filter isKindOfClass:[GPUImageSmoothToonFilter class]]) {
//            GPUImageSmoothToonFilter *toonFilter = (GPUImageSmoothToonFilter*)filter;
//            [toonFilter setBlurSize:slider.value];
//        }
        if ([filter isKindOfClass:[GPUImageSepiaFilter class]]) {
            GPUImageSepiaFilter *sepiaFilter = (GPUImageSepiaFilter*)filter;
            [sepiaFilter setIntensity:slider.value * 3. ];
        }
    }
}
//tag: 1002
- (IBAction)adjust1:(id)sender{
    UISlider *slider = (UISlider*)sender;

    if (filter) {
        if ([filter isKindOfClass:[GPUImageSmoothToonFilter class]]) {
            GPUImageSmoothToonFilter *toonFilter = (GPUImageSmoothToonFilter*)filter;
            [toonFilter setThreshold:slider.value];
        }

    }

}
//tag: 1003
- (IBAction)adjust2:(id)sender{
    UISlider *slider = (UISlider*)sender;
    
    if (filter) {
        if ([filter isKindOfClass:[GPUImageSmoothToonFilter class]]) {
            GPUImageSmoothToonFilter *toonFilter = (GPUImageSmoothToonFilter*)filter;
            [toonFilter setQuantizationLevels:slider.value * 20.];

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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark IBAction Methods

- (IBAction)applyImageFilter:(id)sender
{
    if (previewFiltersVC) {
        [self.navigationController pushViewController:previewFiltersVC animated:YES];
    }
}

- (void) selectImageWithFilterType:(GPUImageShowcaseFilterType)filterType{
    
 
    [stillCamera removeAllTargets];
    [filter removeAllTargets];
    
    GPUImageFilter *selectedFilter = [[FSGPUImageFilterManager sharedFSGPUImageFilterManager] createGPUImageFilter:filterType];
    
    /*
    UISlider *slider0 = (UISlider*)[self.view viewWithTag:1001];
    
    dispatch_async(dispatch_get_main_queue(), ^{
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

    });
    */
    filter = selectedFilter;
    GPUImageView *filterView = (GPUImageView *)self.view;
    [filter addTarget:filterView];
    [stillCamera addTarget:filter];
    
    [self.navigationController popToViewController:self animated:YES];
    
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
    GPUImageView *filterView = (GPUImageView *)self.view;
    [filter addTarget:filterView];
    [stillCamera addTarget:filter];
    
}

@end
