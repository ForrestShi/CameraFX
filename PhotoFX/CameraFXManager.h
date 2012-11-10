//
//  CameraFXManager.h
//  PhotoFX
//
//  Created by forrest on 12-11-10.
//  Copyright (c) 2012年 Mobiletuts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"

@interface CameraFXManager : NSObject

+ (CameraFXManager*) sharedInstance;

@property(nonatomic,strong)  GPUImageStillCamera *stillCamera;
@property(nonatomic,strong)  GPUImageSmoothToonFilter *filter;

@end
