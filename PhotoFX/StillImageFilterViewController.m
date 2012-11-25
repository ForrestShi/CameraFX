//
//  StillImageFilterViewController.m
//  PhotoFX
//
//  Created by forrest on 12-11-25.
//  Copyright (c) 2012年 Mobiletuts. All rights reserved.
//

#import "StillImageFilterViewController.h"
#import "MBProgressHUD.h"

@interface StillImageFilterViewController (){
    UIImageView *processImgView;    
}

@end

@implementation StillImageFilterViewController
@synthesize processImage,imageFilter;

- (id)initWithImage:(UIImage*)image andFilter:(GPUImageFilter*)filter{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.processImage = image;
        self.imageFilter = filter;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    processImgView = [[UIImageView alloc] initWithImage:self.processImage];
    processImgView.autoresizingMask = YES;
    processImgView.frame = self.view.frame;
    [self.view addSubview:processImgView];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    //panGesture.delegate = self;

    [self.view addGestureRecognizer:panGesture];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)adjustFilter:(float)intensity{
    
    if ([self.imageFilter isKindOfClass:[GPUImageSepiaFilter class]]) {
        GPUImageSepiaFilter *sepiaFilter = (GPUImageSepiaFilter*)self.imageFilter;
        [sepiaFilter setIntensity:intensity ];
    }
}

- (void)onPan:(UIPanGestureRecognizer*)gesture{
    
    CGPoint translate = [gesture translationInView:self.view];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }else if (gesture.state == UIGestureRecognizerStateEnded){
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }else if (gesture.state == UIGestureRecognizerStateChanged){
        
        if ([self.imageFilter isKindOfClass:[GPUImageSepiaFilter class]]) {
            GPUImageSepiaFilter *sepiaFilter = (GPUImageSepiaFilter*)self.imageFilter;
            
            static float intensity = 1.;
            intensity = sepiaFilter.intensity;
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
            [sepiaFilter setIntensity:intensity];
            UIImage *newImg = [sepiaFilter imageFromCurrentlyProcessedOutput];
            [processImgView setImage:newImg];
        }
    }
}



@end
