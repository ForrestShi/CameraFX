#import <UIKit/UIKit.h>
#import "GPUImage.h"


@protocol MTCameraViewControllerDelegate

- (void)didSelectStillImage:(NSData *)image withError:(NSError *)error;
- (void)addStillImage:(NSData *)image withError:(NSError *)error;
- (void)updateStillImage:(UIImage *)image;

@end

@interface MTCameraViewController : UIViewController

@property(nonatomic, unsafe_unretained) id delegate;
@end
