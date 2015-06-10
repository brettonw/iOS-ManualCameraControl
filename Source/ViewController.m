#import "ViewController.h"
#import "AppDelegate.h"
#import "AVCaptureDevicePrivate.h"
#import "PixelBuffer.h"

// these values are the denominator of the fractional time of the exposure, i.e.
// 1/1s, 1/2s, 1/3s, 1/4s... full and half stops
int exposureTimes[] = { 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 256, 384, 512, 768, 1024, 1536, 2048, 3072, 4096 };

@implementation ViewController

/*
- (void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection
{
    // take a look around the white balance sample point and try to make that
    // point white
    if (NOT (captureDevice.isAdjustingExposure OR captureDevice.isAdjustingFocus OR captureDevice.isAdjustingWhiteBalance)) {
        if (captureWhiteBalanceCorrection) {
            // fetch the pixel buffer for the frame data we want to examine
            PixelBuffer*    pixelBuffer = [[PixelBuffer alloc] initWithCVPixelBufferRef:CMSampleBufferGetImageBuffer (sampleBuffer)];
            
            // sample the target rect
            int             x = pixelBuffer.width * whiteBalancePoint.x;
            int             y = pixelBuffer.height * whiteBalancePoint.y;
            CGRect          sampleRect = CGRectMake(x - 5, y - 5, 11, 11);
            UIColor*        sampleMeanColor = [pixelBuffer meanColorInRect:sampleRect];
            
            // get the rgb components of the color
            CGFloat         r, g, b, a;
            if ([sampleMeanColor getRed:&r green:&g blue:&b alpha:&a]) {
                
                // compute the new corrections
                CGFloat           max = MAX(MAX(r, g), b);
                r = (whiteBalanceGains.redGain + (whiteBalanceGains.redGain * (max / r))) / 2;
                g = (whiteBalanceGains.greenGain + (whiteBalanceGains.greenGain * (max / g))) / 2;
                b = (whiteBalanceGains.blueGain + (whiteBalanceGains.blueGain * (max / b))) / 2;
                captureWhiteBalanceCorrection = NO;

                // normalize the corrections to compute the gains
                CGFloat           min = MIN(MIN(r, g), b);
                whiteBalanceGains.redGain = MIN(r / min,captureDevice.maxWhiteBalanceGain);
                whiteBalanceGains.greenGain = MIN(g / min,captureDevice.maxWhiteBalanceGain);
                whiteBalanceGains.blueGain = MIN(b / min,captureDevice.maxWhiteBalanceGain);
            }
        }
    }
}
*/

-(void) configureCamera:(id)sender
{
    // set the gain and exposure duration, duration is set as a fractional
    // shutter speed just like a "real" camera. Gain is a value from 0..1
    // which maps the minISO to maxISO range on the device
    float iso = exposureIsoSlider.value;
    int   exposureDuration = exposureTimes[(int)(exposureTimeIndexSlider.value + 0.5)];
    Time time = makeTime(1, exposureDuration);
    [camera setExposureIso:iso andTime:time];
    
    // set the focus position, the range is [0..1], and report the focus control value
    camera.focus = focusPositionSlider.value;
    
    /*
    NSError*    error = nil;
    if ([captureDevice lockForConfiguration:&error]) {
        // these two values seem to get set automatically by the system when the
        // capture device starts up. Unfortunately they seem to be set differently
        // depending on the lighting environment at start, so we reset them every
        // time to ensure consistency
        captureDevice.contrast = 0.0;
        captureDevice.saturation = 0.5;
        
        // we don't want the device to "help" us here, so we turn off low light
        // boost mode completely
        if (captureDevice.lowLightBoostSupported) {
            captureDevice.automaticallyEnablesLowLightBoostWhenAvailable = NO;
        }
        
        // set the gain and exposure duration, duration is set as a fractional
        // shutter speed just like a "real" camera. Gain is a value from 0..1
        // which maps the minISO to maxISO range on the device
        captureDevice.exposureGain = exposureGainSlider.value;
        NSInteger   exposureDuration = exposureTimes[(NSUInteger)(exposureDurationIndexSlider.value + 0.5)];
        captureDevice.exposureDuration = CMTimeMake(1, (int32_t)exposureDuration);
        
        // set the focus position, the range is [0..1], and report the focus control value
        captureDevice.focusPosition = focusPositionSlider.value;
        focusPositionLabel.text = [NSString stringWithFormat:@"%05.03f", captureDevice.focusPosition];
        
        // set the white balance gains
        NSLog(@"White balance gains (r = %0.03f, g = %0.03f, b = %0.03f, max = %0.03f)", whiteBalanceGains.redGain, whiteBalanceGains.greenGain, whiteBalanceGains.blueGain, captureDevice.maxWhiteBalanceGain);
        [captureDevice setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:whiteBalanceGains completionHandler:nil];
        
        // try to commit the control values
        bool success = [captureDevice commit];
        [captureDevice unlockForConfiguration];
        if ( success) {
            // report the control values
            exposureGainLabel.text = [NSString stringWithFormat:@"%05.03f", captureDevice.exposureGain];
            exposureDurationLabel.text = [NSString stringWithFormat:@"%@%ld sec", (exposureDuration > 1) ? @"1 / " : @"", (long)exposureDuration];
        } else {
            if (commitTimer != nil) {
                [commitTimer invalidate];
            }
            // try again in just a moment - at least as long as a frame, with 5% buffer
            NSTimeInterval  interval = (1.0 / ((NSTimeInterval)exposureDuration)) * 0.5;
            commitTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(configureCaptureDevice:) userInfo:nil repeats:NO];
        }
    }
     */
}

-(void)cameraUpdatedBuffer:(id)sender {
    [self configureCamera:nil];
}

-(void)cameraUpdatedFocus:(id)sender {
    focusPositionLabel.text = [NSString stringWithFormat:@"%05.03f", camera.focus];
}

-(void)cameraUpdatedExposure:(id)sender {
    exposureIsoLabel.text = [NSString stringWithFormat:@"%05.03f", camera.iso];
    exposureTimeLabel.text = [NSString stringWithFormat:@"%d/%d sec", camera.time.count, camera.time.scale];
}

-(void) handleTapGesture:(id)input {
    PixelBuffer*    pixelBuffer = camera.buffer;
    
    // sample the target rect
    int             x = pixelBuffer.width * whiteBalancePoint.x;
    int             y = pixelBuffer.height * whiteBalancePoint.y;
    CGRect          sampleRect = CGRectMake(x - 5, y - 5, 11, 11);
    Color           sampleMeanColor = [pixelBuffer meanColorInRect:sampleRect];
    [camera setWhite:sampleMeanColor];
}

// build a slider and label together
UILabel*    tmpLabel;
UISlider*   tmpSlider;
-(void) createSliderWithTitle:(NSString*)title min:(CGFloat)min max:(CGFloat)max value:(CGFloat)value atY:(CGFloat)y
{
    CGRect      frame = controlContainerView.frame;
    CGFloat     spacing = 20;
    CGFloat     doubleSpacing = spacing * 2;
    CGFloat     halfWidth = frame.size.width / 2;
    
    // create the title  label
    CGRect      labelFrame = CGRectMake(halfWidth + spacing, y, halfWidth - doubleSpacing, 20);
    tmpLabel = [[UILabel alloc] initWithFrame:labelFrame];
    tmpLabel.textAlignment = NSTextAlignmentLeft;
    tmpLabel.backgroundColor = [UIColor clearColor];
    tmpLabel.textColor = [UIColor whiteColor];
    tmpLabel.font = [UIFont systemFontOfSize:14.0];
    tmpLabel.text = title;
    [controlContainerView addSubview:tmpLabel];
    
    // create the value label
    tmpLabel = [[UILabel alloc] initWithFrame:labelFrame];
    tmpLabel.textAlignment = NSTextAlignmentRight;
    tmpLabel.backgroundColor = [UIColor clearColor];
    tmpLabel.textColor = [UIColor whiteColor];
    tmpLabel.font = [UIFont systemFontOfSize:14.0];
    tmpLabel.text = @"XXX";
    [controlContainerView addSubview:tmpLabel];
    
    // create the slider
    CGRect      sliderFrame = CGRectMake(halfWidth + spacing, CGRectGetMaxY(labelFrame), halfWidth - doubleSpacing, doubleSpacing);
    tmpSlider = [[UISlider alloc] initWithFrame:sliderFrame];
    tmpSlider.minimumValue = min;
    tmpSlider.maximumValue = max;
    tmpSlider.value = value;
    [tmpSlider addTarget:self action:@selector(configureCamera:) forControlEvents:UIControlEventValueChanged];
    [controlContainerView addSubview:tmpSlider];
}

-(void) loadView
{
    UIWindow*   window = APP_DELEGATE.window;
    CGRect      frame = window.frame;
    
    // this view automatically gets resized to fill the window
    self.view = [[UIView alloc] initWithFrame:frame];
    self.view.backgroundColor = [UIColor redColor];
    
    // adjust the frame rect based on the orientation
    frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    baseView = [[UIView alloc] initWithFrame:frame];
    baseView.backgroundColor = [UIColor blackColor];
    baseView.clipsToBounds = YES;
    [self.view addSubview:baseView];
    
    // put down a view to contain the controls
    controlContainerView = [[UIView alloc] initWithFrame:frame];
    controlContainerView.backgroundColor = [UIColor clearColor];
    controlContainerView.userInteractionEnabled = YES;
    [controlContainerView addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)]];
    [self.view addSubview:controlContainerView];
    
    // setup the video feed
    camera = [[Camera alloc] initInView:baseView];
    camera.delegate = self;
    
    // put sliders down for camera controls
    FloatRange isoRange = camera.isoRange;
    [self createSliderWithTitle:@"ISO" min:isoRange.low max:isoRange.high value:interpolateFloatInRange(0.333, isoRange) atY:20];
    exposureIsoSlider = tmpSlider; exposureIsoLabel = tmpLabel;
    
    [self createSliderWithTitle:@"Time" min:0 max:(ARRAY_SIZE(exposureTimes) - 1) value:6 atY:(CGRectGetMaxY(tmpSlider.frame) + 10)];
    exposureTimeIndexSlider = tmpSlider; exposureTimeLabel = tmpLabel;
    
    FloatRange focusRange = camera.focusRange;
    [self createSliderWithTitle:@"Focus" min:focusRange.low max:focusRange.high value:interpolateFloatInRange(0.5, focusRange) atY:(CGRectGetMaxY(tmpSlider.frame) + 10)];
    focusPositionSlider = tmpSlider; focusPositionLabel = tmpLabel;
    
    // initialize the white balance
    whiteBalanceGains = camera.gains;
    whiteBalancePoint = CGPointMake(0.5, 0.5);
    whiteBalanceFeedbackView = [[UIView alloc] initWithFrame:CGRectMake((frame.size.width / 2) - 5, (frame.size.height / 2) - 5, 11, 11)];
    whiteBalanceFeedbackView.backgroundColor = [UIColor clearColor];
    whiteBalanceFeedbackView.layer.borderColor = [UIColor blueColor].CGColor;
    whiteBalanceFeedbackView.layer.borderWidth = 1;
    //whiteBalanceFeedbackView.hidden = NO;
    [controlContainerView addSubview:whiteBalanceFeedbackView];

    // start the video feed
    [camera startVideo];
    [self configureCamera:nil];
}

-(void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
