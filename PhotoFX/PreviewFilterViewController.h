//
//  PreviewFilterViewController.h
//  PhotoFX
//
//  Created by forrest on 12-11-18.
//  Copyright (c) 2012年 Mobiletuts. All rights reserved.
//
#import "iCarousel.h"
#import "FSGPUImageFilterManager.h"

#import <UIKit/UIKit.h>

@protocol PreviewFilterDelegate <NSObject>

- (void) selectImageWithFilterType:(GPUImageShowcaseFilterType)filterType;


@end

@interface PreviewFilterViewController : UIViewController<iCarouselDataSource, iCarouselDelegate>

- (id)initWithImage:(UIImage*)image;

@property (nonatomic,weak)  id<PreviewFilterDelegate> delegate;

@end
