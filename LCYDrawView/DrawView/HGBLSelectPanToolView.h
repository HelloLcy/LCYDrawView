//
//  HGBLSelectPanToolView.h
//  HuiGanBanLv
//
//  Created by 挥杆伴侣 on 16/3/3.
//  Copyright © 2016年 HuiGanBanLv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HGBLSelectGrpButton.h"

typedef void(^drawColorChange)(UIColor *color,NSString *colorName);

typedef void(^drawGraphChange)(NSString *graph,NSInteger GraphState);


@class HGBLSelectPanToolView;

@protocol HGBLSelectPanToolViewDelegate <NSObject>
/**请求删除所有路径*/
- (void)selectPanToolViewRequestClearAllDraw:(HGBLSelectPanToolView *)panTool;

@end

/**画板工具视图*/
@interface HGBLSelectPanToolView : UIView

@property (copy, nonatomic) drawColorChange changeDrawColorOption;

@property (copy, nonatomic) drawGraphChange changeDrawGraphOption;

@property (weak,nonatomic) id <HGBLSelectPanToolViewDelegate> delegate;

@end
