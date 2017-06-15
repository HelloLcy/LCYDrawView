//
//  HGBLBezierPath.h
//  HuiGanBanLv
//
//  Created by HGBL on 16/3/8.
//  Copyright © 2016年 HuiGanBanLv. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HGBLSelectGrpButton.h"


@interface HGBLBezierPath : UIBezierPath

/**路径的触摸起点*/
@property (assign,nonatomic) CGPoint startPoint;
/**路径的触摸结束点*/
@property (assign,nonatomic) CGPoint lastPoint;
/**路径的图形类型*/
@property (assign,nonatomic) GraphState currentGraph;
/**路径的渲染颜色*/
@property (strong,nonatomic) UIColor *pathColor;

@end
