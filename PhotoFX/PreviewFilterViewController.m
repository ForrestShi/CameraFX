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

@interface PreviewFilterViewController (){

    NSMutableArray *_previewThumnails;
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

- (id)initWithImage:(UIImage*)image{

    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        
        self.processedImage = [image thumbnailImage:128. transparentBorder:6. cornerRadius:8. interpolationQuality:kCGInterpolationHigh] ;
        
        NSAssert(self.processedImage, @"can not be nil");
        
        _previewThumnails = [NSMutableArray array];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.previewCarousel = [[iCarousel alloc] initWithFrame:self.view.frame];
    self.previewCarousel.type = iCarouselTypeLinear;
    self.previewCarousel.vertical = NO;
    self.previewCarousel.bounces = NO;
    self.previewCarousel.delegate = self;
    self.previewCarousel.dataSource = self;
    
    [self.view addSubview:self.previewCarousel];
    
    for (int i = 0 ; i < 24; i++) {
        DLog(@"filter i %d",i);
        
        GPUImageFilter *selectedFilter = [[FSGPUImageFilterManager sharedFSGPUImageFilterManager] createGPUImageFilter:i];
        UIImage *filteredImage = [selectedFilter imageByFilteringImage:self.processedImage];
        [_previewThumnails addObject:filteredImage];
 
    }
    
    
    [self.previewCarousel reloadData];
    
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

    DLog(@"select item %d", index);
    
    [delegate selectImageWithFilterType:index];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}



@end
