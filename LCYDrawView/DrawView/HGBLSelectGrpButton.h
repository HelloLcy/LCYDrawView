//
//  HGBLSelectGrpButton.h
//  HuiGanBanLv
//
//  Created by 挥杆伴侣 on 16/3/3.
//  Copyright © 2016年 HuiGanBanLv. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef NS_ENUM(NSUInteger,GraphState) {
    GraphStateCircle,
    GraphStateRectangle,
    GraphStateStraight,
    GraphStateCurve,
    GraphStateOther
} ;

@interface HGBLSelectGrpButton : UIButton

/**当前按钮image为哪种图形的对应图片*/
@property (copy ,nonatomic) NSString *drawGrp;

+ (instancetype)buttonWithFrame:(CGRect)frame andGrpName:(NSString *)graph;

/**设置当前按钮image为哪种颜色的对应图片*/
- (void)setGraphColor:(NSString *)colorName forState:(UIControlState)state;

@end
