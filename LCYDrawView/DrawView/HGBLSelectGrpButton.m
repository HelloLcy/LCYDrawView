//
//  HGBLSelectGrpButton.m
//  HuiGanBanLv
//
//  Created by 挥杆伴侣 on 16/3/3.
//  Copyright © 2016年 HuiGanBanLv. All rights reserved.
//

#import "HGBLSelectGrpButton.h"

@implementation HGBLSelectGrpButton

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        
    }
    
    return self;
}

+ (instancetype)buttonWithFrame:(CGRect)frame andGrpName:(NSString *)graph
{
    HGBLSelectGrpButton *button = [[self alloc]initWithFrame:frame];
    if (button != nil)
    {
        button.drawGrp = graph;
        [button setGraphColor:@"white" forState:UIControlStateNormal];
    }
    
    return button;
}

- (void)setGraphColor:(NSString *)colorName forState:(UIControlState)state
{
    [self setImage:[UIImage imageNamed:[NSString stringWithFormat:@"analysis_%@_%@",_drawGrp,colorName]] forState:state];
}

@end
