//
//  HGBLArcPath.h
//  HuiGanBanLv
//
//  Created by HGBL on 16/3/11.
//  Copyright © 2016年 HuiGanBanLv. All rights reserved.
//

#import "HGBLBezierPath.h"



#define kLineLength 80


@interface HGBLArcPath : HGBLBezierPath

/**角度显示的位置*/
@property (assign,nonatomic) CGPoint textDrawPoint;
/**路径的顶点*/
@property (assign,nonatomic) CGPoint middlePoint;
/**圆弧的起始角度*/
@property (assign,nonatomic) CGFloat startAngle;
/**是否顺时针*/
@property (assign,nonatomic) BOOL clockWise;
/**圆弧弧度, 圆弧始终两点和圆点组成的两条线的夹角  */
@property (assign,nonatomic) CGFloat intersectionAngle;

+ (instancetype)arcPathWithTouchPoint:(CGPoint)touchPoint;

@end
