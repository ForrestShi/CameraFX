#import "ViewController.h"
#import "GPUImage.h"
#import "MTCameraViewController.h"
#import "iCarousel.h"
#import "UIImage+Resize.h"

@interface ViewController () 
{
    NSMutableArray *displayImages;
    GPUImageStillCamera *stillCamera;
    GPUImageFilter      *filter;
    MTCameraViewController *cameraViewController;
}

@property(nonatomic, weak) IBOutlet iCarousel *photoCarousel;
@property(nonatomic, weak) IBOutlet UIBarButtonItem *filterButton;
@property(nonatomic, weak) IBOutlet UIBarButtonItem *saveButton;

- (IBAction)photoFromAlbum;
- (IBAction)photoFromCamera;
- (IBAction)saveImageToAlbum;
- (IBAction)applyImageFilter:(id)sender;

@end

@implementation ViewController

@synthesize photoCarousel, filterButton, saveButton;

#pragma mark -
#pragma mark Initializers 

- (void)customSetup
{
    displayImages = [[NSMutableArray alloc] init];
    
    stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    if (!filter) {
        // Setup initial camera filter
        filter = [[GPUImageToonFilter alloc] init];        
    }

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // iCarousel Configuration
    self.photoCarousel.type = iCarouselTypeCoverFlow2;
    self.photoCarousel.bounces = NO;
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

- (IBAction)photoFromAlbum
{
    UIImagePickerController *photoPicker = [[UIImagePickerController alloc] init];
    photoPicker.delegate = self;
    photoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:photoPicker animated:YES completion:NULL];
}

- (IBAction)saveImageToAlbum
{
    UIImage *selectedImage = [displayImages objectAtIndex:self.photoCarousel.currentItemIndex];
    UIImageWriteToSavedPhotosAlbum(selectedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (IBAction)photoFromCamera
{
    NSLog(@"TAP CAMERA");
    if (!stillCamera) {
        NSLog(@"CREATE STILL CAMERA.");
        stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
        stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        
        GPUImageView *gpuImageView = [[GPUImageView alloc] initWithFrame:self.view.frame];
        
        GPUImageFilter *filter = [[GPUImageToonFilter alloc] init];
        [stillCamera addTarget:filter];
        GPUImageView *filterView = gpuImageView;
        [filter addTarget:filterView];
        
        [self.view addSubview:gpuImageView];
        
        [stillCamera startCameraCapture];
 
    }
}

- (IBAction)applyImageFilter:(id)sender
{
    UIActionSheet *filterActionSheet = [[UIActionSheet alloc] initWithTitle:@"Select Filter"
                                                                   delegate:self
                                                          cancelButtonTitle:@"Cancel"
                                                     destructiveButtonTitle:nil
                                                          otherButtonTitles:@"Grayscale", @"Sepia", @"Sketch", @"Pixellate", @"Color Invert", @"Toon", @"Pinch Distort", @"None", nil];
    
    [filterActionSheet showInView:self.parentViewController.view];
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
    self.saveButton.enabled = YES;
    self.filterButton.enabled = YES;
    
    [displayImages addObject:[info valueForKey:UIImagePickerControllerOriginalImage]];
    
    [self.photoCarousel reloadData];
        
    [photoPicker dismissViewControllerAnimated:YES completion:NULL];
    
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if(buttonIndex == actionSheet.cancelButtonIndex)
    {
        return;
    }
    
    GPUImageFilter *selectedFilter;
    
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
            selectedFilter = [[GPUImageToonFilter alloc] init];
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
    
    UIImage *filteredImage = [selectedFilter imageByFilteringImage:[displayImages objectAtIndex:self.photoCarousel.currentItemIndex]];
    [displayImages replaceObjectAtIndex:self.photoCarousel.currentItemIndex withObject:filteredImage];
    [self.photoCarousel reloadData];
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
            [self.photoCarousel scrollToItemAtIndex:[displayImages count] animated:YES];
            
            self.filterButton.enabled = YES;
            self.saveButton.enabled = YES;
        });
        
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Capture Error" message:@"Unable to capture photo." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alert show];
    }
}

#pragma mark 
#pragma mark iCarousel DataSource/Delegate/Custom

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return [displayImages count];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{    
    // Create new view if no view is available for recycling
    if (view == nil)
    {
        view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300.0f, 300.0f)];
        view.contentMode = UIViewContentModeCenter;
    }
    
    // Intelligently scale down to a max of 250px in width or height
    UIImage *originalImage = [displayImages objectAtIndex:index];
    
    CGSize maxSize = CGSizeMake(250.0f, 250.0f);
    CGSize targetSize;
    
    // If image is landscape, set width to 250px
    if(originalImage.size.width >= originalImage.size.height)
    {
        float newHeightMultiplier = maxSize.width / originalImage.size.width;
        targetSize = CGSizeMake(maxSize.width, round(originalImage.size.height * newHeightMultiplier));
    } // If image is portrait, set height to 250px
    else
    {
        float newWidthMultiplier = maxSize.height / originalImage.size.height;
        targetSize = CGSizeMake( round(newWidthMultiplier * originalImage.size.width), maxSize.height );
    }
    
    // Resize the source image down to fit nicely in iCarousel
    //((UIImageView *)view).image = [[displayImages objectAtIndex:index] imageScaledToFitSize:targetSize];
    ((UIImageView *)view).image = [[displayImages objectAtIndex:index] resizedImage:targetSize interpolationQuality:kCGInterpolationHigh];
    
    // Two finger double-tap will delete an image
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeImageFromCarousel:)];
    gesture.numberOfTouchesRequired = 2;
    gesture.numberOfTapsRequired = 2;
    view.gestureRecognizers = [NSArray arrayWithObject:gesture];
    
    return view;
}

- (void)removeImageFromCarousel:(UIGestureRecognizer *)gesture
{
    [gesture removeTarget:self action:@selector(removeImageFromCarousel:)];
    [displayImages removeObjectAtIndex:self.photoCarousel.currentItemIndex];
    [self.photoCarousel reloadData];
}

@end
