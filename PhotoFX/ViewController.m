#import "ViewController.h"
#import "GPUImage.h"
#import "MTCameraViewController.h"
#import "iCarousel.h"
#import "UIImage+Resize.h"
#import "FXImageView.h"
#import "SHKItem.h"
#import "SHKActionSheet.h"
#import "FSGPUImageFilterManager.h"
#import "PreviewFilterViewController.h"
#import "MyAppsViewController.h"
#import "StillImageFilterViewController.h"


static BOOL sureToDelete = YES;

@interface ViewController () <PreviewFilterDelegate , UIGestureRecognizerDelegate>
{
    NSMutableArray *displayImages;
    MTCameraViewController *cameraViewController;
    UIPopoverController *popOver;
    NSTimer *adjustFXTimer;
    GPUImageSepiaFilter *sepiaFlt ;
    
}

@property(nonatomic, assign) IBOutlet iCarousel *photoCarousel;
@property(nonatomic, weak) IBOutlet UIBarButtonItem *filterButton;
@property(nonatomic, weak) IBOutlet UIBarButtonItem *shareButton;
@property(nonatomic, weak) IBOutlet UIBarButtonItem *deleteButton;
@property(nonatomic, weak) IBOutlet UIBarButtonItem *refreshButton;

- (IBAction)photoFromAlbum:(id)sender;
- (IBAction)refreshCarouselStyle;
- (IBAction)deleteImage;
- (IBAction)shareImage;
- (IBAction)applyImageFilter:(id)sender;
- (IBAction)showInfo;
- (IBAction)stillImageFilterAdjust;

@end

@implementation ViewController

@synthesize photoCarousel, filterButton, shareButton,deleteButton,refreshButton;

#pragma mark -
#pragma mark Initializers 

- (void)customSetup
{
    displayImages = [[NSMutableArray alloc] init];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        [self customSetup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self customSetup];
    }
    return self;
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    DLog(@"...");
    [self.navigationController setNavigationBarHidden:NO];
//    if (self.photoCarousel) {
//        [self.photoCarousel reloadData];
//        [self.photoCarousel scrollToItemAtIndex:[displayImages count] animated:YES];
//    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen.jpg"]];

    self.photoCarousel.backgroundColor = [UIColor clearColor];
    // iCarousel Configuration
    self.photoCarousel.type = iCarouselTypeCoverFlow;
    self.photoCarousel.bounces = YES;
    self.photoCarousel.delegate = self;
    self.photoCarousel.dataSource = self;

    BOOL firstTimeToRun = NO; //[[[NSUserDefaults standardUserDefaults] objectForKey:@"firstTime"] boolValue];
    if (!firstTimeToRun) {
        //first time run
        
        UIImage *scarlett = [UIImage imageNamed:@"scarlett.jpg"];
        
        sepiaFlt = [[GPUImageSepiaFilter alloc] init];
        [sepiaFlt setIntensity:0.2];
        UIImage *s1 = [sepiaFlt imageByFilteringImage:scarlett];
        
        sepiaFlt = [[GPUImageSepiaFilter alloc] init];
        [sepiaFlt setIntensity:0.5];
        UIImage *s2 = [sepiaFlt imageByFilteringImage:scarlett];
        
        sepiaFlt = [[GPUImageSepiaFilter alloc] init];
        [sepiaFlt setIntensity:0.8];
        UIImage *s3 = [sepiaFlt imageByFilteringImage:scarlett];
        
        sepiaFlt = [[GPUImageSepiaFilter alloc] init];
        [sepiaFlt setIntensity:1.];
        UIImage *s4 = [sepiaFlt imageByFilteringImage:scarlett];
        
        [displayImages addObject:scarlett];
        [displayImages addObject:s1];
        [displayImages addObject:s2];
        [displayImages addObject:s3];
        [displayImages addObject:s4];
        [self.photoCarousel reloadData];
        [self refreshUI];
        [self.photoCarousel scrollToItemAtIndex:[displayImages count]/2 animated:YES];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstTime"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    UITapGestureRecognizer *tapToCancelDeleteGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToCancel)];
    tapToCancelDeleteGesture.delegate = self;
    //[tapToCancelDeleteGesture setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:tapToCancelDeleteGesture];
    
    [self refreshUI];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"pushMTCamera"])
    {
        // Set the delegate so this controller can received snapped photos
        cameraViewController = (MTCameraViewController *) segue.destinationViewController;
        cameraViewController.delegate = self;
    }

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark -
#pragma mark IBAction Methods

- (IBAction)photoFromAlbum:(id)sender
{
    UIImagePickerController *photoPicker = [[UIImagePickerController alloc] init];
    photoPicker.delegate = self;
    photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:photoPicker];

        [popover presentPopoverFromBarButtonItem:((UIBarButtonItem*)sender) permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        popOver = popover;
        
    } else {
        [self presentViewController:photoPicker animated:YES completion:NULL];
    }


}

- (IBAction)refreshCarouselStyle{
    
#if 0
    self.photoCarousel.type = (self.photoCarousel.type+1 > iCarouselTypeCustom) ? iCarouselTypeLinear : (self.photoCarousel.type + 1);
#else
    /*
     iCarouselTypeLinear = 0,
     iCarouselTypeRotary,
     iCarouselTypeInvertedRotary,
     iCarouselTypeCylinder,
     iCarouselTypeInvertedCylinder,
     iCarouselTypeWheel,
     iCarouselTypeInvertedWheel,
     iCarouselTypeCoverFlow,
     iCarouselTypeCoverFlow2,
     iCarouselTypeTimeMachine,
     iCarouselTypeInvertedTimeMachine,
     iCarouselTypeCustom

     */
    UIActionSheet *styleSheet = [[UIActionSheet alloc] initWithTitle:@"Display Style" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Linear",@"Rotary",@"Rotary 2",@"Cylinder",@"Cylinder2",@"Wheel",@"Wheel 2",@"CoverFlow",@"CoverFlow 2",@"TimeMachine",@"TimeMachine 2", nil];
    [styleSheet showFromBarButtonItem:self.refreshButton animated:YES];
    
#endif
}

- (void)refreshUI{
    if ([displayImages count] == 0 ) {
        self.filterButton.enabled = NO;
        self.deleteButton.enabled = NO;
        self.refreshButton.enabled = NO;
        self.shareButton.enabled = NO;
    }else{
        self.filterButton.enabled = YES;
        self.deleteButton.enabled = YES;
        self.refreshButton.enabled = YES;
        self.shareButton.enabled = YES;
    }

}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([touch.view.superview isKindOfClass:[UIToolbar class]] || [touch.view isKindOfClass:[UIButton class]]) {
        return NO;
    }
    return YES;
}

- (void)tapToCancel{
    
    if (sureToDelete == NO ) {
        [self.deleteButton setTintColor:[UIColor clearColor]];
        sureToDelete = YES;
    }
}

- (IBAction)deleteImage{
    if ([displayImages count] == 0 ) {
        [self refreshUI];
        return;
    }
    sureToDelete = !sureToDelete;
    
    if (sureToDelete) {
        [displayImages removeObjectAtIndex:self.photoCarousel.currentItemIndex];
        [self.photoCarousel removeItemAtIndex:self.photoCarousel.currentItemIndex animated:YES];
        [self refreshUI];
        [self.deleteButton setTintColor:[UIColor clearColor]];
    }else{
        [self.deleteButton setTintColor:[UIColor redColor]];
    }
}

- (IBAction)shareImage
{
    if ([displayImages count] == 0 ) {
        self.shareButton.enabled = NO;
        return;
    }
    
    SHKItem *item = [SHKItem image:[displayImages objectAtIndex:self.photoCarousel.currentItemIndex] title:@"Sepia Camera Pro"];
    
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
	[SHK setRootViewController:self];
//	[actionSheet showFromToolbar:self.navigationController.toolbar];
//    [actionSheet showFromRect:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 1) inView:self.view animated:YES];
    [actionSheet showFromBarButtonItem:self.shareButton animated:YES];

}

- (IBAction)stillImageFilterAdjust{
    
    StillImageFilterViewController *filterVC = [[StillImageFilterViewController alloc] initWithImage:[displayImages objectAtIndex:self.photoCarousel.currentItemIndex] andFilterType:GPUIMAGE_SEPIA];
    filterVC.delegate = self;
    
    filterVC.modalTransitionStyle = UIModalTransitionStylePartialCurl;
    [self presentModalViewController:filterVC animated:YES];

}

- (IBAction)applyImageFilter:(id)sender
{
    
//    CATransition* transition = [CATransition animation];
//    transition.duration = 0.5;
//    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//    transition.type = kCATransitionMoveIn; //kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
//    transition.subtype = kCATransitionFromBottom; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom
//    [self.navigationController.view.layer addAnimation:transition forKey:nil];
//    [[self navigationController] popViewControllerAnimated:NO];
//    
//    PreviewFilterViewController *previewFiltersVC = [[PreviewFilterViewController alloc] initWithProcessedImage:[displayImages objectAtIndex:self.photoCarousel.currentItemIndex] dynamic:YES];
//    previewFiltersVC.delegate = self;
//    
//    
//    [self.navigationController pushViewController:previewFiltersVC animated:NO];
//    
    
    PreviewFilterViewController *previewFiltersVC = [[PreviewFilterViewController alloc] initWithProcessedImage:[displayImages objectAtIndex:self.photoCarousel.currentItemIndex] dynamic:YES];
    previewFiltersVC.delegate = self;
    previewFiltersVC.modalTransitionStyle = UIModalTransitionStylePartialCurl;
    [self presentModalViewController:previewFiltersVC animated:YES];
}

- (void) selectImageWithFilterType:(GPUImageShowcaseFilterType)filterType{
    
    GPUImageFilter *selectedFilter = [[FSGPUImageFilterManager sharedFSGPUImageFilterManager] createGPUImageFilter:filterType];
    UIImage *filteredImage = [selectedFilter imageByFilteringImage:[displayImages objectAtIndex:self.photoCarousel.currentItemIndex]];
    [displayImages insertObject:filteredImage atIndex:self.photoCarousel.currentItemIndex+1];
    [self.photoCarousel insertItemAtIndex:self.photoCarousel.currentItemIndex+1 animated:YES];
    [self.photoCarousel scrollToItemAtIndex:self.photoCarousel.currentItemIndex+1 animated:YES];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)showInfo{
    MyAppsViewController *infoVC = [[MyAppsViewController alloc] init];
    infoVC.modalPresentationStyle = UIModalPresentationCurrentContext;
    infoVC.modalTransitionStyle = UIModalTransitionStylePartialCurl;
    [self presentModalViewController:infoVC animated:YES];
}

#pragma mark -
#pragma mark Album Picking/Saving Code

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSString *alertTitle;
    NSString *alertMessage;
    
    if(!error)
    {
        alertTitle   = @"Image Saved";
        alertMessage = @"Image saved to photo album successfully.";
    }
    else
    {
        alertTitle   = @"Error";
        alertMessage = @"Unable to save to photo album.";
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle
                                                    message:alertMessage
                                                   delegate:self
                                          cancelButtonTitle:@"Okay"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)imagePickerController:(UIImagePickerController *)photoPicker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if (self.photoCarousel.currentItemIndex >= 0 && self.photoCarousel.currentItemIndex < 1000 ) {
        [displayImages insertObject:[info valueForKey:UIImagePickerControllerOriginalImage] atIndex:self.photoCarousel.currentItemIndex];
        [self.photoCarousel insertItemAtIndex:self.photoCarousel.currentItemIndex animated:YES];

    }else{
        [displayImages insertObject:[info valueForKey:UIImagePickerControllerOriginalImage] atIndex:0];
        [self.photoCarousel insertItemAtIndex:0 animated:YES];

    }
    
    [photoPicker dismissViewControllerAnimated:YES completion:NULL];
    
    [self refreshUI];

}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if(buttonIndex == actionSheet.cancelButtonIndex)
    {
        return;
    }
    
    self.photoCarousel.type = (buttonIndex > iCarouselTypeCustom) ? iCarouselTypeLinear : buttonIndex;

}

#pragma mark -
#pragma mark MTCameraViewController

// This delegate method is called after our custom camera class takes a photo
- (void)didSelectStillImage:(NSData *)imageData withError:(NSError *)error
{
    if(!error)
    {
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        [displayImages addObject:image];
        
        runOnMainQueueWithoutDeadlocking(^{
            
            [self.photoCarousel reloadData];
            //[self refreshCarousel];
            [self.photoCarousel scrollToItemAtIndex:[displayImages count] animated:YES];
            [self refreshUI];
        });
        
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Capture Error" message:@"Unable to capture photo." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alert show];
    }
}

- (void)addStillImage:(NSData *)imageData withError:(NSError *)error
{
    if(!error)
    {
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        [displayImages addObject:image];
        [self.photoCarousel reloadData];
        [self.photoCarousel scrollToItemAtIndex:[displayImages count] animated:YES];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Capture Error" message:@"Unable to capture photo." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alert show];
    }
}

- (void)updateStillImage:(UIImage*)newImage{
    [displayImages replaceObjectAtIndex:self.photoCarousel.currentItemIndex withObject:newImage];
    [self.photoCarousel reloadData];
}

#pragma mark 
#pragma mark iCarousel DataSource/Delegate/Custom

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return [displayImages count];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        
        CGRect cellFrame = CGRectMake(0, 0, 250.0f, 250.0f);
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            cellFrame = CGRectMake(0, 0, 512., 512.);
        }
        
        FXImageView *imageView = [[[FXImageView alloc] initWithFrame:cellFrame] autorelease];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.asynchronous = YES;
        imageView.reflectionScale = 0.5f;
        imageView.reflectionAlpha = 0.25f;
        imageView.reflectionGap = 10.0f;
        imageView.shadowOffset = CGSizeMake(0.0f, 2.0f);
        imageView.shadowBlur = 5.0f;
        imageView.cornerRadius = 10.0f;
        
        view = imageView;
    }
    
    //load image
    [(FXImageView*)view setImage:[displayImages objectAtIndex:index]];
    
    // One finger double-tap will delete an image
//    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeImageFromCarousel:)];
//    gesture.numberOfTouchesRequired = 1;
//    gesture.numberOfTapsRequired = 2;
//    view.gestureRecognizers = [NSArray arrayWithObject:gesture];
//    
    
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:singleTap];
    
    UITapGestureRecognizer *single2Tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingle2Tap:)];
    single2Tap.numberOfTapsRequired = 2;
    single2Tap.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:single2Tap];
    
    [singleTap requireGestureRecognizerToFail:single2Tap];
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(onPinch:)];
    [view addGestureRecognizer:pinchGesture];
    
    //do not try this because hard to control 
//    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressing:)];
//    [longPressGesture setMinimumPressDuration:1./2.];
//    //longPressGesture.delegate = self;
//    [view addGestureRecognizer:longPressGesture];
    
    return view;
}

- (void)removeImageFromCarousel:(UIGestureRecognizer *)gesture
{
    [gesture removeTarget:self action:@selector(removeImageFromCarousel:)];
    [displayImages removeObjectAtIndex:self.photoCarousel.currentItemIndex];
    [self.photoCarousel reloadData];
    [self.photoCarousel scrollToItemAtIndex:self.photoCarousel.currentItemIndex animated:YES];
}

- (void)adjustFX{
    DLog(@"run fx adjust...");
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        static int i = 0;
        UIImage *curImage = [displayImages objectAtIndex:self.photoCarousel.currentItemIndex];
        if (!sepiaFlt) {
            sepiaFlt =[[GPUImageSepiaFilter alloc] init];
        }
        sepiaFlt.intensity = 1. - i++ * 0.01;
        if (sepiaFlt.intensity < 0 ) {
            sepiaFlt.intensity = 1.;
            i = 0;
        }
    
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:curImage];
    [stillImageSource addTarget:sepiaFlt];
    [stillImageSource processImage];
    
    UIImage *newImage = [sepiaFlt imageFromCurrentlyProcessedOutput];
    
        [displayImages replaceObjectAtIndex:self.photoCarousel.currentItemIndex withObject:newImage];
        
        [self.photoCarousel reloadItemAtIndex:self.photoCarousel.currentItemIndex animated:NO];
    //});
}

- (void)onLongPressing:(UILongPressGestureRecognizer*)gesture{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        DLog(@"start pressing...");
        if (!adjustFXTimer) {
            adjustFXTimer = [NSTimer scheduledTimerWithTimeInterval:1/30. target:self selector:@selector(adjustFX) userInfo:nil repeats:YES];
            [adjustFXTimer fire];
        }
    }else if(gesture.state == UIGestureRecognizerStateEnded){
        DLog(@"end pressing...");
        
        if (adjustFXTimer) {
            [adjustFXTimer invalidate];
            adjustFXTimer = nil;
        }
    }
}


- (void)onPinch:(UIPinchGestureRecognizer*)gesture{
    DLog(@"pinching... %@ scale : %f", gesture , [gesture scale] );
    
    FXImageView *selectedImageView = (FXImageView*)gesture.view;
    selectedImageView.transform = CGAffineTransformScale([selectedImageView transform], [gesture scale], [gesture scale]);
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.3 animations:^{
            selectedImageView.transform = CGAffineTransformMakeScale(1., 1.);
        }];
    }
    
    gesture.scale = 1.;

    
}
- (void)onSingleTap:(UITapGestureRecognizer*)gesture{
    if ([displayImages count] > 0) {
        [self stillImageFilterAdjust];
    }
    [self tapToCancel];
}

- (void)onSingle2Tap:(UITapGestureRecognizer*)gesture{
    
    static BOOL zoomin = YES;
    FXImageView *selectedImageView = (FXImageView*)gesture.view;
    if (selectedImageView) {
        [UIView animateWithDuration:0.3 animations:^{
            // make it not clear after multiple times
            //selectedImageView.frame = CGRectMake(0, 0, 250.0f, 250.0f);
            if (zoomin) {
                selectedImageView.transform =CGAffineTransformMakeScale(3., 3.);
            }else{
                selectedImageView.transform =CGAffineTransformMakeScale(1., 1.);
            }
            zoomin = !zoomin;

        }];
    }
}


@end
