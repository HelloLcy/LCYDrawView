//
//  HGBLSelectPanColorButton.m
//  HuiGanBanLv
//
//  Created by 挥杆伴侣 on 16/3/3.
//  Copyright © 2016年 HuiGanBanLv. All rights reserved.
//

#import "HGBLSelectPanColorButton.h"

@implementation HGBLSelectPanColorButton

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        
    }
    
    return self;
}

+ (instancetype)buttonWithFrame:(CGRect)frame andColor:(UIColor *)color
{
    HGBLSelectPanColorButton *button = [[self alloc]initWithFrame:frame];
    if (button != nil) {
        //button.drawColor = color;
        //设置按钮为圆形
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = MIN(button.frame.size.width, button.frame.size.height) * 0.5;
        button.backgroundColor = color;
    }
    
    return button;
}

@end
