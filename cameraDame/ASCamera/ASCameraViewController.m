//
//  ViewController.m
//  photo
//
//  Created by Sweet on 2016/11/16.
//  Copyright © 2016年 sweet. All rights reserved.
//

#define kMainScreenWidth [UIScreen mainScreen].bounds.size.width
#define kMainScreenHeight [UIScreen mainScreen].bounds.size.height

#import "ASCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ASImageView.h"

typedef enum : NSUInteger {
    // The default state has to be off
    CameraFlashOff,
    CameraFlashOn,
    CameraFlashAut,
} CameraFlash;


@interface ASCameraViewController ()<UIGestureRecognizerDelegate>
//界面控件
@property (strong, nonatomic) UIView *backView;
//AVFoundation

@property (nonatomic) dispatch_queue_t sessionQueue;
/**
 *  AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
 */
@property (nonatomic, strong) AVCaptureSession* session;
/**
 *  输入设备
 */
@property (nonatomic, strong) AVCaptureDeviceInput* videoInput;

/**
 *  照片输出流
 */
@property (nonatomic, strong) AVCaptureStillImageOutput* stillImageOutput;
/**
 *  预览图层
 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer* previewLayer;


@property (strong, nonatomic) UIButton *snapButton;

@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UIButton *disMissButton;

/** 背景图片  */
@property (nonatomic, strong) UIImageView * backImageView;

/**   */
@property (nonatomic, assign,getter=isUsingFrontFacingCamera) BOOL FrontFacingCamera;

@property (nonatomic, assign) CameraFlash Flashenum;
@end

@implementation ASCameraViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.Revolve = NO;
    self.session = [[AVCaptureSession alloc] init];
    [self initAVCaptureSession];
}
- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    [self shouldOpenAuthorizationStatus];

}

-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
}

- (void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:YES];
    
    if (self.session) {
        [self.session stopRunning];
    }
}


- (void)shouldOpenAuthorizationStatus {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            // 许可对话没有出现，发起授权许可
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    if (self.session) {
                        [self.session startRunning];
                    }
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            // 已经开启授权，可继续
            if (self.session) {
                [self.session startRunning];
            }
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            if (self.session) {
                [self.session startRunning];
            }
            break;
        default:
            break;
    }
}

- (BOOL)prefersStatusBarHidden {
    
    return YES;
}

- (void)initAVCaptureSession{

    NSError *error;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    //设置闪光灯为自动
    [device setFlashMode:AVCaptureFlashModeAuto];
    self.Flashenum = CameraFlashAut;
    [device unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
    }
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    //输出设置。AVVideoCodecJPEG   输出jpeg格式图片
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    self.previewLayer.frame = CGRectMake(0,44,kMainScreenWidth, kMainScreenHeight-134);
    
    self.backView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, kMainScreenWidth, kMainScreenHeight)];
    self.backView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.backView];
    
    [self.backView.layer addSublayer:self.previewLayer];
    
    UITapGestureRecognizer *pinch = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinch.delegate = self;
    [self.backView addGestureRecognizer:pinch];
    
    [self setUpButtonsOfCamera];
    
}

- (void)dealloc {
}

- (void)handlePinchGesture:(UITapGestureRecognizer *)recognizer{

    CGPoint touchPoint = [recognizer locationInView:self.backView];
    AVCaptureDevice *device = [_session.inputs.lastObject device];
    if ([device lockForConfiguration:nil]) {
        CGPoint pointOfInterest = [self pointOfInterestWithTouchPoint:touchPoint];
        
        if (device.focusPointOfInterestSupported) {
            device.focusPointOfInterest = pointOfInterest;
        }
        
        if (device.exposurePointOfInterestSupported) {
            device.exposurePointOfInterest = pointOfInterest;
        }
        
        if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }
        
        if ([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }
        
        [device unlockForConfiguration];
    }

}

- (CGPoint)pointOfInterestWithTouchPoint:(CGPoint)touchPoint
{
    CGSize screenSize = [UIScreen.mainScreen bounds].size;
    
    CGPoint pointOfInterest;
    pointOfInterest.x = touchPoint.x / screenSize.width;
    pointOfInterest.y = touchPoint.y / screenSize.height;
    
    return pointOfInterest;
}

- (void)setBackImage:(UIImage *)backImage {
    
    self.backImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 44, kMainScreenWidth, kMainScreenHeight-134)];
    self.backImageView.image = backImage;
    self.backImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.backImageView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.backImageView];
    
    
}

- (void)setUpButtonsOfCamera {
    
    // snap button to capture image
    self.snapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.snapButton.frame = CGRectMake((kMainScreenWidth -80)/2,kMainScreenHeight-80, 70.0f, 70.0f);
    self.snapButton.clipsToBounds = YES;

    [self.snapButton setImage:[UIImage imageNamed:@"Camrera.bundle/shutter"] forState:UIControlStateNormal];
    [self.snapButton setImage:[UIImage imageNamed:@"Camrera.bundle/shutter_h"] forState:UIControlStateHighlighted];
    [self.snapButton addTarget:self action:@selector(snapButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.snapButton];
    
    
    
    // button to toggle flash
    self.flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.flashButton.frame = CGRectMake(20, 0, 16.0f + 20.0f, 24.0f + 20.0f);
    [self.flashButton setImage:[UIImage imageNamed:@"Camrera.bundle/lightauto"] forState:UIControlStateNormal];
    [self.flashButton setImage:[UIImage imageNamed:@"Camrera.bundle/lightauto_h"] forState:UIControlStateHighlighted  ];
    self.flashButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    [self.flashButton addTarget:self action:@selector(flashButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.flashButton];
    
    
    // button to toggle flash
    self.switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.switchButton.frame = CGRectMake(kMainScreenWidth-80,kMainScreenHeight-80, 70.0f, 70.0f);
    [self.switchButton setImage:[UIImage imageNamed:@"Camrera.bundle/switch"] forState:UIControlStateNormal];
    
    [self.switchButton setImage:[UIImage imageNamed:@"Camrera.bundle/switch_h"] forState:UIControlStateHighlighted];
    
    self.switchButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    [self.switchButton addTarget:self action:@selector(switchButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.switchButton];
    
    
    self.disMissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.disMissButton.frame = CGRectMake(20,kMainScreenHeight-80, 70.0f, 70.0f);
    self.disMissButton.tintColor = [UIColor whiteColor];
    self.disMissButton.titleLabel.text = @"关闭";
    self.disMissButton.titleLabel.font = [UIFont systemFontOfSize: 18.0];
    [self.disMissButton setTitle:@"关闭" forState:UIControlStateNormal];
    [self.disMissButton addTarget:self action:@selector(disMissButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.disMissButton];
    
    
}


#pragma mark respone method

- (void)flashButtonPressed:(id)sender {
    
    NSInteger mode  = -1;
    
    
    if (self.Flashenum == CameraFlashAut) {
        mode = CameraFlashOff;
        self.Flashenum = CameraFlashOff;
        [self.flashButton setImage:[UIImage imageNamed:@"Camrera.bundle/lightoff"] forState:UIControlStateNormal];
        
        [self.flashButton setImage:[UIImage imageNamed:@"Camrera.bundle/lightoff_h"] forState:UIControlStateHighlighted];
        
    }else if (self.Flashenum == CameraFlashOff) {
        mode = CameraFlashOn;
        self.Flashenum = CameraFlashOn;
        [self.flashButton setImage:[UIImage imageNamed:@"Camrera.bundle/lighton"] forState:UIControlStateNormal];
        
        [self.flashButton setImage:[UIImage imageNamed:@"Camrera.bundle/lighton_h"] forState:UIControlStateHighlighted];
    }else if (self.Flashenum == CameraFlashOn) {
        mode = CameraFlashAut;
        self.Flashenum = CameraFlashAut;
        
        [self.flashButton setImage:[UIImage imageNamed:@"Camrera.bundle/lightauto"] forState:UIControlStateNormal];
        
        [self.flashButton setImage:[UIImage imageNamed:@"Camrera.bundle/lightauto_h"] forState:UIControlStateHighlighted];
        
    }
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    //设置闪光灯为自动
    [device setFlashMode:mode];
    [device unlockForConfiguration];
}

- (void)disMissButtonPressed{
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)switchButtonPressed {
    
    AVCaptureDevicePosition desiredPosition;
    if (self.FrontFacingCamera){
        desiredPosition = AVCaptureDevicePositionBack;
        self.flashButton.hidden = NO;
    }else{
        desiredPosition = AVCaptureDevicePositionFront;
        self.flashButton.hidden = YES;
    }
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            [self.previewLayer.session beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in self.previewLayer.session.inputs) {
                [[self.previewLayer session] removeInput:oldInput];
            }
            [self.previewLayer.session addInput:input];
            [self.previewLayer.session commitConfiguration];
            break;
        }
    }
    
    self.FrontFacingCamera = !self.isUsingFrontFacingCamera;
    
}


- (void)setIsShouldOpenFrontCamera:(BOOL)isShouldOpenFrontCamera {
    
    
    self.FrontFacingCamera = isShouldOpenFrontCamera;
    
    AVCaptureDevicePosition desiredPosition;
    if (isShouldOpenFrontCamera==YES){
        desiredPosition = AVCaptureDevicePositionFront;
        self.flashButton.hidden = YES;
        
    }else{
        desiredPosition = AVCaptureDevicePositionBack;
        self.flashButton.hidden = NO;
    }
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            [self.previewLayer.session beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in self.previewLayer.session.inputs) {
                [[self.previewLayer session] removeInput:oldInput];
            }
            [self.previewLayer.session addInput:input];
            [self.previewLayer.session commitConfiguration];
            break;
        }
    }
}

- (void)snapButtonPressed:(id)sender {
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusDenied){
        [self alertToFailOnLivenessWithMessage:@"请到设置>隐私>相机>打开本应用的权限设置"];
        return ;
    }
    
    AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [stillImageConnection setVideoOrientation:avcaptureOrientation];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        NSData *jpegData = [NSData data];
        @try {
            jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        } @catch (NSException *exception) {
            NSLog(@"--身份证照片照出问题啦~~");
        } @finally {
            NSLog(@"哦~~");
        }
        
        UIImage *image = [UIImage imageWithData:jpegData scale:1];
        CGRect cropFrame = CGRectMake(0,44,kMainScreenWidth , kMainScreenHeight-134);
        
        if (image.size.width > image.size.height) {
            cropFrame = CGRectMake(44,0, kMainScreenHeight-134,kMainScreenWidth );
        }
        image = [self cropImage:image withCropSize:cropFrame.size];
        
        ASImageView *imageVC = [[ASImageView alloc]initWithImage:image];
        imageVC.VC = self;
        [imageVC achieve:^{
            [self.delegate CameraAchieveToImageDelegate:self Withimage:image];
            
        }];
        [self.view addSubview:imageVC];
        
    }];
    
}

- (void)alertToFailOnLivenessWithMessage:(NSString *)message {
    //     1.实例化alert:alertControllerWithTitle
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"未授权" message:[NSString stringWithFormat:@"\n%@",message] preferredStyle:UIAlertControllerStyleAlert];
    
    //修改message
    NSMutableAttributedString *alertControllerMessageStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",message]];
    [alertControllerMessageStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:152/255.0 green:159/255.0 blue:178 alpha:1] range:NSMakeRange(0, 4)];
    [alertControllerMessageStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:20] range:NSMakeRange(0, 4)];
    if ([alert valueForKey:@"attributedMessage"]) {
        [alert setValue:alertControllerMessageStr forKey:@"attributedMessage"];
    }
    //
    [alert addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    }]];
    
    // 3.显示alertController:presentViewController
    [self presentViewController:alert animated:YES completion:nil];
    
}


- (UIImage *)cropImage:(UIImage *)image withCropSize:(CGSize)cropSize
{
    UIImage *newImage = nil;
    
    CGSize imageSize = image.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    CGFloat targetWidth = cropSize.width;
    CGFloat targetHeight = cropSize.height;
    
    CGFloat scaleFactor = 0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0, 0);
    
    if (CGSizeEqualToSize(imageSize, cropSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor) {
            scaleFactor = widthFactor;
        } else {
            scaleFactor = heightFactor;
        }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * .5f;
        } else {
            if (widthFactor < heightFactor) {
                thumbnailPoint.x = (targetWidth - scaledWidth) * .5f;
            }
        }
    }
    
    UIGraphicsBeginImageContextWithOptions(cropSize, YES, 0);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [image drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    if (image.size.width < image.size.height && self.isRevolving) {
        
        newImage = [self image:newImage rotation:UIImageOrientationLeft];
    }
    return newImage;
}

- (UIImage *)image:(UIImage *)image rotation:(UIImageOrientation)orientation
{
    long double rotate = 0.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    switch (orientation) {
        case UIImageOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationRight:
            rotate = 3 * M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image.CGImage);
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    return newPic;
}




- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}

- (void)flashButtonClick:(UIBarButtonItem *)sender {
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //修改前必须先锁定
    [device lockForConfiguration:nil];
    //必须判定是否有闪光灯，否则如果没有闪光灯会崩溃
    if ([device hasFlash]) {
        
        if (device.flashMode == AVCaptureFlashModeOff) {
            device.flashMode = AVCaptureFlashModeOn;
            
            [sender setTitle:@"flashOn"];
        } else if (device.flashMode == AVCaptureFlashModeOn) {
            device.flashMode = AVCaptureFlashModeAuto;
            [sender setTitle:@"flashAuto"];
        } else if (device.flashMode == AVCaptureFlashModeAuto) {
            device.flashMode = AVCaptureFlashModeOff;
            [sender setTitle:@"flashOff"];
        }
        
    } else {
        NSLog(@"设备不支持闪光灯");
    }
    [device unlockForConfiguration];
}



@end
