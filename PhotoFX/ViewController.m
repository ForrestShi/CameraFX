#import "ViewController.h"
#import "GPUImage.h"
#import "MTCameraViewController.h"
#import "iCarousel.h"
#import "UIImage+Resize.h"
#import "FXImageView.h"
#import "SHKItem.h"
#import "SHKActionSheet.h"

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
    
    self.photoCarousel.backgroundColor = [UIColor clearColor];
    // iCarousel Configuration
    self.photoCarousel.type = iCarouselTypeCoverFlow;
    self.photoCarousel.bounces = YES;
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
    
    if ([displayImages count] == 0 ) {
        return;
    }
    
    SHKItem *item = [SHKItem image:[displayImages objectAtIndex:self.photoCarousel.currentItemIndex] title:@"San Francisco"];
    
    /* optional examples
     item.tags = [NSArray arrayWithObjects:@"bay bridge", @"architecture", @"california", nil];
     
     //give a source rect in the coords of the view set with setRootViewController:
     item.popOverSourceRect = [self.navigationController.toolbar convertRect:self.navigationController.toolbar.bounds toView:self.view];
     */
    
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
	[SHK setRootViewController:self];
//	[actionSheet showFromToolbar:self.navigationController.toolbar];
    [actionSheet showFromRect:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 1) inView:self.view animated:YES];

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

            [self.photoCarousel reloadDataToLastItem];
            //[self.photoCarousel scrollToItemAtIndex:[displayImages count] animated:YES];

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
    
    //create new view if no view is available for recycling
    if (view == nil)
    {
        FXImageView *imageView = [[[FXImageView alloc] initWithFrame:CGRectMake(0, 0, 250.0f, 250.0f)] autorelease];
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
