//
//  ImageViewController.h
//  LLSimpleCameraExample
//
//  Created by Ömer Faruk Gül on 15/11/14.
//  Copyright (c) 2014 Ömer Faruk Gül. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^AchieveBlock)();
@interface ASImageView: UIView


/**   */
@property (nonatomic, weak) UIViewController * VC;
@property (nonatomic, copy) AchieveBlock achieveBlock;


- (instancetype)initWithImage:(UIImage *)image;

- (void)achieve:(AchieveBlock)block;

@end
