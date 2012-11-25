//
//  PreviewFilterViewController.m
//  PhotoFX
//
//  Created by forrest on 12-11-18.
//  Copyright (c) 2012年 Mobiletuts. All rights reserved.
//

#import "PreviewFilterViewController.h"
#import "GPUImage.h"
#import "FXImageView.h"
#import "UIImage+Resize.h"
#import "MBProgressHUD.h"

@interface PreviewFilterViewController (){

    NSMutableArray *_previewThumnails;
    BOOL    dynamicGenerate;
}
@property (nonatomic,strong) UIImage *processedImage;
@property (nonatomic,strong) iCarousel *previewCarousel;

@end

@implementation PreviewFilterViewController
@synthesize processedImage,previewCarousel;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithProcessedImage:(UIImage*)image dynamic:(BOOL)flag{

    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        
        dynamicGenerate = flag;
        
        //self.processedImage = [image thumbnailImage:128. transparentBorder:6. cornerRadius:8. interpolationQuality:kCGInterpolationHigh] ;
        if (image.size.width > 128) {
            float ratio = image.size.height/image.size.width;
            float width  = IS_IPAD ? 256.:128.;
            self.processedImage = [image resizedImage:CGSizeMake(width, width*ratio) interpolationQuality:kCGInterpolationHigh];
        }else{
            self.processedImage = image;
        }
        
        if (self.processedImage == nil ) {
            self.processedImage = [UIImage imageNamed:@"s2.png"];
        }
        
        NSAssert(self.processedImage, @"can not be nil");
        
        _previewThumnails = [NSMutableArray array];
        
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    DLog(@"...");
    [self.navigationController setNavigationBarHidden:NO];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO];

	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"apple-shirt.jpg"]];
    
    self.previewCarousel = [[iCarousel alloc] initWithFrame:self.view.frame];
    self.previewCarousel.type = iCarouselTypeInvertedWheel;
    //self.previewCarousel.vertical = NO;
    self.previewCarousel.bounces = NO;
    self.previewCarousel.clipsToBounds = YES;
    self.previewCarousel.delegate = self;
    self.previewCarousel.dataSource = self;
    //self.previewCarousel.transform = CGAffineTransformMakeRotation(45.);
    self.previewCarousel.autoresizingMask = YES;
    self.previewCarousel.autoresizesSubviews = YES;
    
    [self.view addSubview:self.previewCarousel];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    
    for (int i = 0 ; i < 24; i++) {
        DLog(@"filter i %d",i);
        
        GPUImageFilter *selectedFilter = [[FSGPUImageFilterManager sharedFSGPUImageFilterManager] createGPUImageFilter:i];
        NSString *filePath = [basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"thumb_%d",i]];
        
        UIImage *filteredImage = nil;
        
        if (dynamicGenerate) {
            filteredImage = [selectedFilter imageByFilteringImage:self.processedImage];
            
        }else{
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                DLog(@"%@ existed", filePath);
                filteredImage = [UIImage imageWithContentsOfFile:filePath];
                
            }else{
                DLog(@"%@ NOT existed", filePath);
                
                filteredImage = [selectedFilter imageByFilteringImage:self.processedImage];
                [UIImagePNGRepresentation(filteredImage) writeToFile:filePath atomically:YES];
                
            }
            
            
        }
        
        if (filteredImage) {
            [_previewThumnails addObject:filteredImage];
        }

        
    }
    
    [self.previewCarousel reloadData];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel{
    return [_previewThumnails count];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view{

    if (!view) {
        CGRect cellFrame = CGRectMake(0, 0, 250.0f/2, 250.0f/2);
        if (IS_IPAD) {
            cellFrame = CGRectMake(0, 0, 512./2, 512./2);
        }
        
        FXImageView *imageView = [[[FXImageView alloc] initWithFrame:cellFrame] autorelease];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.asynchronous = YES;
        imageView.reflectionScale = 0.1f;
        imageView.reflectionAlpha = 0.05f;
        imageView.reflectionGap = 10.0f/2;
        imageView.shadowOffset = CGSizeMake(0.0f, 2.0f/2);
        imageView.shadowBlur = 5.0f;
        imageView.cornerRadius = 10.0f/2;
        
        view = imageView;
    }
    [((UIImageView*)view) setImage:[_previewThumnails objectAtIndex:index ]];
    return view;
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index{

    [delegate selectImageWithFilterType:index];

}



@end
