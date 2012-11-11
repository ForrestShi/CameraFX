//
//  CameraFXManager.m
//  PhotoFX
//
//  Created by forrest on 12-11-10.
//  Copyright (c) 2012年 Mobiletuts. All rights reserved.
//

#import "CameraFXManager.h"

static CameraFXManager* instance = nil;

@implementation CameraFXManager
@synthesize stillCamera = _stillCamera,filter = _filter;


+ (CameraFXManager*) sharedInstance{
    if (!instance) {
        instance = [[CameraFXManager alloc] init];
        [instance setupCamera];
    }
    return instance;
}

- (void)setupCamera{
    if (!_stillCamera) {
        _stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
        _stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

    }
    
    if (!_filter) {
        // Setup initial camera filter
        _filter = [[GPUImageSepiaFilter alloc] init];
    }


}


@end
