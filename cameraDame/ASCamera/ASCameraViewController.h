//
//  FRCameraViewController.h
//  photo
//
//  Created by Sweet on 2016/11/16.
//  Copyright © 2016年 sweet. All rights reserved.
//

#import <UIKit/UIKit.h>


@class ASCameraViewController;

@protocol CameraAchieveToImageDelegate <NSObject>
@required
- (void)CameraAchieveToImageDelegate:(ASCameraViewController *)ViewController Withimage:(UIImage *)image;
@end

@interface ASCameraViewController : UIViewController

/** 背景图片  */
@property (nonatomic, strong) UIImage * backImage;

/** 默认摄像头  */
@property (nonatomic, assign) BOOL isShouldOpenFrontCamera;

@property (strong, nonatomic) UIButton *switchButton;
/** 代理*/
@property (nonatomic, weak) id<CameraAchieveToImageDelegate> delegate;

/** 是否旋转  */
@property (nonatomic, assign,getter=isRevolving) BOOL Revolve;

@end
