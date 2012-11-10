#import "MTCameraViewController.h"
//http://mobile.tutsplus.com/tutorials/iphone/enhancing-a-photo-app-with-gpuimage-icarousel/
#import "CameraFXManager.h"


@interface MTCameraViewController () <UIActionSheetDelegate, UIGestureRecognizerDelegate>
{
    GPUImageStillCamera *stillCamera;
    GPUImageSmoothToonFilter *filter;

}

- (IBAction)captureImage:(id)sender;
- (IBAction)adjust1:(id)sender;
- (IBAction)adjust2:(id)sender;

@end

@implementation MTCameraViewController 
@synthesize delegate;

#pragma mark -
#pragma mark View Controller Lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];

    NSLog(@"view loaded");
    
    // Add Filter Button to Interface
    UIBarButtonItem *filterButton = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStylePlain target:self action:@selector(applyImageFilter:)];
    self.navigationItem.rightBarButtonItem = filterButton;

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
        //stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        [stillCamera addTarget:filter];
        
        // Begin showing video camera stream
        [stillCamera startCameraCapture];
 
    }
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    singleTap.delegate = self;
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    panGesture.delegate = self;
    
    [self.view addGestureRecognizer:singleTap];
    [self.view addGestureRecognizer:panGesture];
    
}

- (void)singleTap:(UIGestureRecognizer*)gesture{
    if (stillCamera) {
        //DLog(@"switch camera");
        [stillCamera rotateCamera];
    }
}

- (void)onPan:(UIPanGestureRecognizer*)gesture{
    DLog(@"%@",@"paning");
}


- (IBAction)adjust1:(id)sender{
    UISlider *slider = (UISlider*)sender;

    if (filter) {
        if ([filter isKindOfClass:[GPUImageSmoothToonFilter class]]) {
            GPUImageSmoothToonFilter *toonFilter = (GPUImageSmoothToonFilter*)filter;
            [toonFilter setThreshold:slider.value];
        }

    }

}

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
    
    CGRect captureBtnFrame = ((UIButton*)[self.view viewWithTag:1000]).frame;
    CGRect sliderFrame = ((UISlider*)[self.view viewWithTag:1001]).frame;
    CGRect sliderFrame2 = ((UISlider*)[self.view viewWithTag:1002]).frame;

    //DLog(@"capture frame %@",NSStringFromCGRect(captureBtnFrame));
    if ( CGRectContainsPoint(captureBtnFrame, [gestureRecognizer locationInView:self.view]) ||
                             CGRectContainsPoint(sliderFrame, [gestureRecognizer locationInView:self.view]) ||
                                     CGRectContainsPoint(sliderFrame2, [gestureRecognizer locationInView:self.view])) {
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
    UIActionSheet *filterActionSheet = [[UIActionSheet alloc] initWithTitle:@"Select Filter"
                                                                   delegate:self
                                                          cancelButtonTitle:@"Cancel"
                                                     destructiveButtonTitle:nil
                                                          otherButtonTitles:@"Grayscale", @"Sepia", @"Sketch", @"Pixellate", @"Color Invert", @"Toon", @"Pinch Distort", @"None", nil];
    
    [filterActionSheet showFromBarButtonItem:sender animated:YES];
}

-(IBAction)captureImage:(id)sender
{
    // Disable to prevent multiple taps while processing
    UIButton *captureButton = (UIButton *)sender;
    //captureButton.enabled = NO;
    
    // Snap Image from GPU camera, send back to main view controller
    [stillCamera capturePhotoAsJPEGProcessedUpToFilter:filter withCompletionHandler:^(NSData *processedJPEG, NSError *error)
     {
         if([self.delegate respondsToSelector:@selector(didSelectStillImage:withError:)])
         {
             [self.delegate didSelectStillImage:processedJPEG withError:error];
         }
         else
         {
             NSLog(@"Delegate did not respond to message");
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
    
    GPUImageFilter *selectedFilter;
    
    [stillCamera removeAllTargets];
    [filter removeAllTargets];

    
    switch (buttonIndex) {
        case 0:
            selectedFilter = [[GPUImageGrayscaleFilter alloc] init];
            break;
        case 1:
            selectedFilter = [[GPUImageSepiaFilter alloc] init];
            break;
        case 2:
            selectedFilter = [[GPUImageSketchFilter alloc] init];
            break;
        case 3:
            selectedFilter = [[GPUImagePixellateFilter alloc] init];
            break;
        case 4:
            selectedFilter = [[GPUImageColorInvertFilter alloc] init];
            break;
        case 5:
            selectedFilter = [[GPUImageSmoothToonFilter alloc] init];
            break;
        case 6:
            selectedFilter = [[GPUImagePinchDistortionFilter alloc] init];
            break;
        case 7:
            selectedFilter = [[GPUImageFilter alloc] init];
            break;
        default:
            break;
    }
        
    filter = selectedFilter;
    GPUImageView *filterView = (GPUImageView *)self.view;
    [filter addTarget:filterView];
    [stillCamera addTarget:filter];
    
}

@end
