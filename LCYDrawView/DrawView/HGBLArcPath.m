//
//  HGBLArcPath.m
//  HuiGanBanLv
//
//  Created by HGBL on 16/3/11.
//  Copyright © 2016年 HuiGanBanLv. All rights reserved.
//

#import "HGBLArcPath.h"

@implementation HGBLArcPath

+ (instancetype)arcPathWithTouchPoint:(CGPoint)touchPoint
{
    CGFloat angle = sqrtf(3.0);
    
    HGBLArcPath *arcPath = [self bezierPath];
    
    arcPath.middlePoint = touchPoint;
    arcPath.startPoint = CGPointMake(touchPoint.x - kLineLength * 0.5, touchPoint.y + kLineLength * 0.5 * angle);
    arcPath.lastPoint = CGPointMake(touchPoint.x + kLineLength * 0.5, touchPoint.y + kLineLength * 0.5 * angle);
    arcPath.clockWise = NO;
    arcPath.startAngle = M_PI / 3;
    arcPath.intersectionAngle = M_PI / 3;
    arcPath.textDrawPoint = CGPointMake(touchPoint.x - 10, touchPoint.y + 30);
    
    return arcPath;
}

@end
