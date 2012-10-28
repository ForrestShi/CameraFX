#import <UIKit/UIKit.h>
#import "iCarousel.h"
#import "MTCameraViewController.h"

@interface ViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, MTCameraViewControllerDelegate, iCarouselDataSource, iCarouselDelegate>

@end
