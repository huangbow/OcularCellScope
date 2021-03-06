//
//  AVCaptureManager.m
//  OcularCellscope
//
//  Created by Chris Echanique on 4/17/14.
//  Copyright (c) 2014 UC Berkeley Ocular CellScope. All rights reserved.
//

#import "AVCaptureManager.h"
#import "NSMutableDictionary+ImageMetadata.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+Custom.h"

@interface AVCaptureManager()
{
    CALayer *rootLayer;
    CALayer *boxLayer;
    CALayer *focusBoxLayer;
}
@end

@implementation AVCaptureManager

@synthesize session = _session;
@synthesize device = _device;
@synthesize deviceInput = _deviceInput;
@synthesize previewLayer = _previewLayer;
@synthesize stillOutput = _stillOutput;
@synthesize delegate = _delegate;
@synthesize isExposureLocked = _isExposureLocked;
@synthesize isCapturingImages = _isCapturingImages;
@synthesize lastImageMetadata = _lastImageMetadata;

-(id)init{
    self = [super init];
    
    if(self){
        self.isCapturingImages = NO; //TODO: is this used?
    }
    
    return self;
}

-(void)setupCameraWithPreview:(UIView*)view{
    self.view = view;
    
    // Create a new photo session
    self.session = [[AVCaptureSession alloc] init];
    [self.session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    // Set device to video
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Add device to session
    self.deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:Nil];
    if ( [self.session canAddInput:self.deviceInput] )
        [self.session addInput:self.deviceInput];
    
    // Add still image output
    self.stillOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.stillOutput setOutputSettings:outputSettings];
    [self.session addOutput:self.stillOutput];
    
    // Set preview layer
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];

    // Set the preview layer to the bounds of the screen
    rootLayer = [self.view layer];
    [rootLayer setMasksToBounds:YES];
    [self.previewLayer setFrame:CGRectMake(0, 0, view.frame.size.width, view.frame.size.height)];
    [self.previewLayer setVideoGravity: AVLayerVideoGravityResizeAspectFill];//AVLayerVideoGravityResizeAspect];
    
    [rootLayer insertSublayer:self.previewLayer atIndex:0];
    
    BOOL mirroredView = [[NSUserDefaults standardUserDefaults] boolForKey:@"mirroredView"];
    
    if(mirroredView == YES){
        self.previewLayer.affineTransform = CGAffineTransformInvert(CGAffineTransformMakeRotation(M_PI));
    }
    
    if(mirroredView == NO){
        self.previewLayer.affineTransform = CGAffineTransformInvert(CGAffineTransformMakeRotation(0));
    }
    
    [self.session startRunning];
}

-(void)takeDownCamera {
    [self.session removeInput:self.deviceInput];
    [self.session removeOutput:self.stillOutput];
    [self.previewLayer removeFromSuperlayer];
    self.session = nil;
    self.device = nil;
    self.deviceInput = nil;
    self.stillOutput = nil;
    
}

-(AVCaptureConnection*)getVideoConnection{
    AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in self.stillOutput.connections)
	{
		for (AVCaptureInputPort *port in [connection inputPorts])
		{
			if ([[port mediaType] isEqual:AVMediaTypeVideo] )
			{
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) { break; }
	}
    return videoConnection;
}


-(void)takePicture{
    
    // Set boolean for capturing images
    self.isCapturingImages = YES; //TODO: is this used? it never gets reset
    
    AVCaptureConnection *videoConnection = [self getVideoConnection];
    
    // Asynchronous call to capture image
	[_stillOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         self.lastImageMetadata = [[NSMutableDictionary alloc] initWithImageSampleBuffer:imageSampleBuffer];
         //PRINTS ALL METADATA
         //NSLog(self.lastImageMetadata.description);
         
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         
         // Call to delegate to do something with this image data
         dispatch_async(dispatch_get_main_queue(), ^{
         [self.delegate didCaptureImageWithData:imageData];
         });
     }];
}

//TODO: refactor...

-(void)lockFocus{
    if ([self.device isFocusModeSupported:AVCaptureFocusModeLocked]) {
        [self.device lockForConfiguration:nil];
        [self.device setFocusMode:AVCaptureFocusModeLocked];
        [self.device unlockForConfiguration];
    }
}

-(void)lockWhiteBalance{
    if ([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked]) {
        [self.device lockForConfiguration:nil];
        [self.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked];
        [self.device unlockForConfiguration];
    }
}

- (void)setExposureLock:(BOOL)locked
{
    NSError* error;
    if ([self.device lockForConfiguration:&error])
    {
        if (locked)
            [self.device setExposureMode:AVCaptureExposureModeLocked];
        else
            [self.device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        self.isExposureLocked = locked;
        [self.device unlockForConfiguration];
    }
    else
        NSLog(@"Error: %@",error);
}

-(void)unlockFocus{
    if ([self.device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        CGPoint autofocusPoint = CGPointMake(0.5f, 0.5f);
        [self.device lockForConfiguration:nil];
        [self.device setFocusPointOfInterest:autofocusPoint];
        [self.device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [self.device unlockForConfiguration];
    }
}

-(void)unlockWhiteBalance{
    if ([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {

        [self.device lockForConfiguration:nil];
        [self.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        [self.device unlockForConfiguration];
    }
}


- (void)setFocusWithPoint:(CGPoint)point
{
    NSError *error;
    
    if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus] &&
        [self.device isFocusPointOfInterestSupported])
    {
        if ([self.device lockForConfiguration:&error]) {
            [self.device setFocusPointOfInterest:point];
            [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
            [self.device unlockForConfiguration];
        } else {
            NSLog(@"Error: %@", error);
        }
    }
}



- (void)setRedGain:(float)redGain
         greenGain:(float)greenGain
          blueGain:(float)blueGain
{
    
    [self.device lockForConfiguration:nil];
    AVCaptureWhiteBalanceGains gains;
    gains.redGain = redGain;
    gains.greenGain = greenGain;
    gains.blueGain = blueGain;
    [self.device setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:gains completionHandler:nil];
    [self.device unlockForConfiguration];
}

- (void)setFocusPosition:(float)position
{
    [self.device lockForConfiguration:nil];
    [self.device setFocusModeLockedWithLensPosition:position completionHandler:nil];
    [self.device unlockForConfiguration];
    
}

- (void)setExposureDuration:(float)durationMilliseconds ISO:(float)iso
{
    CMTime exposureDurationTime = CMTimeMake(durationMilliseconds,1e3);
    
    if (iso<self.device.activeFormat.minISO)
        iso = self.device.activeFormat.minISO;
    else if (iso>self.device.activeFormat.maxISO)
        iso = self.device.activeFormat.maxISO;
    
    [self.device lockForConfiguration:nil];
    [self.device setExposureModeCustomWithDuration:exposureDurationTime ISO:iso completionHandler:nil];
    [self.device unlockForConfiguration];
}

@end
