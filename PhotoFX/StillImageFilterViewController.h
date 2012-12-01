//
//  StillImageFilterViewController.h
//  PhotoFX
//
//  Created by forrest on 12-11-25.
//  Copyright (c) 2012年 Mobiletuts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"
#import "FSGPUImageFilterManager.h"

@interface StillImageFilterViewController : UIViewController


@property (nonatomic,strong) UIImage *processImage;
@property(nonatomic, unsafe_unretained) id delegate;

- (id)initWithImage:(UIImage*)image withFilter:(GPUImageFilter*)filter;

@end
