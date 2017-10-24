//
//  ImageViewController.m
//  LLSimpleCameraExample
//
//  Created by Ömer Faruk Gül on 15/11/14.
//  Copyright (c) 2014 Ömer Faruk Gül. All rights reserved.
//

#define kMainScreenWidth [UIScreen mainScreen].bounds.size.width
#define kMainScreenHeight [UIScreen mainScreen].bounds.size.height

#import "ASImageView.h"

@interface ASImageView ()
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UILabel *infoLabel;


@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIButton *achieveButton;

@end

@implementation ASImageView

- (instancetype)initWithImage:(UIImage *)image {

    self = [super initWithFrame:CGRectMake(0, 0, kMainScreenWidth, kMainScreenHeight)];
    if(self) {
        _image = image;
        [self viewLoad];
    }
    
    return self;
}

- (void)viewLoad{
 
    
    self.backgroundColor = [UIColor blackColor];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 44, screenRect.size.width, screenRect.size.height-134)];
    self.imageView.backgroundColor = [UIColor clearColor];
    self.imageView.image = self.image;

    self.imageView.contentMode = UIViewContentModeScaleAspectFit;

    [self addSubview:self.imageView];
    
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cancelButton.frame = CGRectMake(20,kMainScreenHeight-80, 70.0f, 70.0f);
    self.cancelButton.tintColor = [UIColor whiteColor];
    self.cancelButton.titleLabel.text = @"重拍";
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize: 18.0];
    [self.cancelButton setTitle:@"重拍" forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.cancelButton];
    
    
    
    
    self.achieveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.achieveButton.frame = CGRectMake(kMainScreenWidth -80,kMainScreenHeight-80, 70.0f, 70.0f);
    self.achieveButton.tintColor = [UIColor whiteColor];
    self.achieveButton.titleLabel.font = [UIFont systemFontOfSize: 18.0];
    self.achieveButton.titleLabel.text = @"完成";
    [self.achieveButton setTitle:@"完成" forState:UIControlStateNormal];
    [self.achieveButton addTarget:self action:@selector(achieveButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.achieveButton];
    
}

- (void)cancelButtonPressed:(id)sender{
    
    [self removeFromSuperview];
    
}

- (void)achieveButtonPressed:(id)sender{
    
    self.achieveBlock();
    [self removeFromSuperview];
    [self.VC dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)achieve:(AchieveBlock)block {
    
    self.achieveBlock = block;
}

@end
