//
//  MyAppsViewController.m
//  PhotoFX
//
//  Created by forrest on 12-11-24.
//  Copyright (c) 2012年 Mobiletuts. All rights reserved.
//

#import "MyAppsViewController.h"
#import "iCarousel.h"
#import "FXImageView.h"
#import "Appirater.h"
#import "SHK.h"
#import "FXLabel.h"

@interface MyApp : NSObject

@property (nonatomic,retain) NSString *appName;
@property (nonatomic,retain) NSString *appLink;
@property (nonatomic,retain) NSString *appInfo;
@property (nonatomic,retain) NSString *developerLink;
@property (nonatomic,retain) NSString *appIconName;

@end

@implementation MyApp
@synthesize appName, appLink,developerLink,appInfo,appIconName;
@end


@interface MyAppsViewController ()<iCarouselDataSource,iCarouselDelegate>{
    UIButton *rateBtn ;
    UILabel *copyrightLabel;
}

@property (nonatomic,strong) NSMutableArray *apps;
@property (nonatomic,strong) iCarousel *iconCarousel;
@property (nonatomic,strong) UILabel *titleLabel;
@end

@implementation MyAppsViewController
@synthesize apps,iconCarousel,titleLabel;

-(UILabel*)createLabelWithFrame:(CGRect)frame andFontSize:(float)fontSize andText:(NSString*)text
{
    UILabel* label = [[UILabel alloc] initWithFrame:frame];
    [label setFont:[UIFont systemFontOfSize:fontSize]];
    [label setTextColor:[UIColor whiteColor]];
    [label setShadowColor:[UIColor blackColor]];
    [label setShadowOffset:CGSizeMake(0, -1)];
    [label setTextAlignment:UITextAlignmentCenter];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setText:text];
    return label;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        NSDictionary *appDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"myApps" ofType:@"plist"]];
        
        for (NSDictionary *d in [appDict allValues]) {
            MyApp *app = [[MyApp alloc] init];
            app.appName = [d objectForKey:@"name"];
            app.appLink = [d objectForKey:@"link"];
            app.appIconName = [d objectForKey:@"icon"];
            app.appInfo = [d objectForKey:@"info"];
            if (!self.apps) {
                self.apps = [NSMutableArray array];
            }
            [self.apps addObject:app];
        }
        NSAssert(self.apps != nil, @"wrong apps");
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ipadbk.jpeg"]];

    if (!self.iconCarousel) {
        self.iconCarousel = [[iCarousel alloc] initWithFrame:self.view.bounds];
        self.iconCarousel.type = iCarouselTypeLinear;
        self.iconCarousel.delegate = self;
        self.iconCarousel.dataSource = self;
        self.iconCarousel.autoresizesSubviews = YES;
        self.iconCarousel.autoresizingMask = YES;
    }
    [self.view addSubview:self.iconCarousel];
    
    UILabel *introLabel = [self createLabelWithFrame:CGRectMake(30., self.view.bounds.size.height/4 - (IS_IPAD ? 55.:40.), 300., 44) andFontSize:(IS_IPAD?15:10.) andText:@"More apps from Design4Apple:"];
    introLabel.textAlignment = UITextAlignmentLeft;
    introLabel.textColor = [UIColor lightGrayColor];
    [self.view addSubview:introLabel];
    
    self.titleLabel = [self createLabelWithFrame:CGRectMake(self.view.bounds.size.width/2 - 300/2, self.view.bounds.size.height/4, 300., 44) andFontSize:(IS_IPAD?15:10.) andText:@""];
    self.titleLabel.textAlignment = UITextAlignmentCenter;    
    [self.view addSubview:self.titleLabel];
    
    CGRect rateBtnFrame = CGRectMake(self.view.bounds.size.width/2 -22., self.view.bounds.size.height - 44.*2, 44., 44.);
    rateBtn = [[UIButton alloc] initWithFrame:rateBtnFrame];
    [rateBtn setImage:[UIImage imageNamed:@"thumbs_up.png"] forState:UIControlStateNormal];
    [rateBtn addTarget:self action:@selector(rateMe:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:rateBtn];
    
    copyrightLabel = [self createLabelWithFrame:CGRectMake(0, self.view.bounds.size.height - 30., self.view.bounds.size.width, 30) andFontSize:6. andText:[NSString stringWithFormat:@"%@ %@ Design4Apple@gmail.com ", APPIRATER_APP_NAME,APP_VERSION ]];
    copyrightLabel.textAlignment = UITextAlignmentRight;
    
    [self.view addSubview:copyrightLabel];
    
    [self.iconCarousel scrollToItemAtIndex:[self.apps count]/2 animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel{
    return [self.apps count];
}
- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view{
    //create new view if no view is available for recycling
    DLog(@"view for %d",index);
    
    if (view == nil)
    {
        CGRect cellFrame = CGRectMake(0, 0, 128., 128.);
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            cellFrame = CGRectMake(0, 0, 256, 256);
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
    [(FXImageView*)view setImage:[UIImage imageNamed:((MyApp*)[apps objectAtIndex:index]).appIconName]];
      
    return view;
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index{
    DLog(@"index %d",index);
    [self buyApp:nil];
}

- (CGFloat)carouselItemWidth:(iCarousel *)carousel{
    return 250.;
}

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel{
    
    [UIView animateWithDuration:0.2 animations:^{
        DLog(@"animation1");
        self.titleLabel.alpha = 0.5;
        [self.titleLabel setText:((MyApp*)[apps objectAtIndex:carousel.currentItemIndex]).appName];
        
    } completion:^(BOOL finished) {
        DLog(@"animation2");

        if (finished) {
            DLog(@"animation3");

            [UIView animateWithDuration:0.2 animations:^{
                self.titleLabel.alpha = 1.;
            }];

        }
    }];

}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
    
    //support all , not perfect now
    self.titleLabel.frame = CGRectMake(self.view.bounds.size.width/2 - 150., self.view.bounds.size.height/4, 300., 44);
    self.iconCarousel.frame = self.view.bounds;
    
    rateBtn.frame = CGRectMake(self.view.bounds.size.width/2 -22., self.view.bounds.size.height - 44.*2, 44., 44.);

    copyrightLabel.frame = CGRectMake(0, self.view.bounds.size.height - 30., self.view.bounds.size.width, 30);

    if (UIInterfaceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        self.titleLabel.frame = CGRectMake(self.view.bounds.size.width/2 - 150., self.view.bounds.size.height/4 - 70., 300., 44);
        rateBtn.frame = CGRectMake(self.view.bounds.size.width/2 -22., self.view.bounds.size.height - 44., 44., 44.);

    }
    
        
    //return YES;
}

- (MyApp*)currentApp{
    MyApp *curApp = (MyApp*)[self.apps objectAtIndex:self.iconCarousel.currentItemIndex];
    return curApp;
}

- (MyApp*)seipaCameraPro{
    MyApp *app = [[MyApp alloc] init];
    app.appLink = @"https://itunes.apple.com/us/app/sepia-toon-camera/id578137731?mt=8";
    return app;
}

- (void)rateMe:(id)sender{
    [Flurry logEvent:@"rate me"];
    
    [Appirater userDidSignificantEvent:YES];
    [Appirater rateApp];
}

- (void)buyApp:(id)sender{
    NSMutableString *appURL = [NSMutableString stringWithString:@"itms-apps://"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[appURL stringByAppendingString: [self currentApp].appLink]]];
    
    [Flurry logEvent:@"buy..."];

}
//Not used
- (void)recommendApp:(id)sender{
    NSMutableString *httpPrefix = [NSMutableString stringWithString:@"http://"];
    NSURL *appURL = [NSURL URLWithString:[httpPrefix stringByAppendingString: [self currentApp].appLink]];
    SHKItem *item = [SHKItem URL:appURL title:[self currentApp].appName contentType:SHKURLContentTypeWebpage];
    SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    [actionSheet showFromRect:((UIButton*)sender).frame inView:self.view animated:YES];
}

@end
