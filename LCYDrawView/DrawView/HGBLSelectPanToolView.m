//
//  HGBLSelectPanToolView.m
//  HuiGanBanLv
//
//  Created by 挥杆伴侣 on 16/3/3.
//  Copyright © 2016年 HuiGanBanLv. All rights reserved.
//

#import "HGBLSelectPanToolView.h"

#import "HGBLSelectGrpButton.h"
#import "HGBLSelectPanColorButton.h"

#define kColorButtonTagBase     111
#define kGraphButtonTagBase     666

@implementation HGBLSelectPanToolView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        //添加子控件
        [self creatSubViews];
    }

    return self;
}


- (void)creatSubViews
{
    NSInteger index = 0;
    CGFloat selfWidth = self.bounds.size.width;
    CGFloat selfHeight = self.bounds.size.height;
    HGBLSelectGrpButton *graphButton = nil;
    HGBLSelectPanColorButton *colorButton = nil;
    CGFloat setX = 10;  //X起点
    CGFloat setW = (selfWidth - setX * 2) / 7; //宽
    CGFloat spacingX = setW * 0.5; //X间距
    CGFloat colorSetY = (selfHeight - 120) * 0.5;//颜色按钮Y起点
    CGFloat setH = setW;  //设置按钮宽高相等
    CGFloat spacingY = 120 - 2 * setH; //Y间距
    CGFloat graphSetY = colorSetY + setH + spacingY; //图形按钮Y起点
    NSArray *colorA = @[[UIColor whiteColor],[UIColor greenColor],[UIColor yellowColor],[UIColor blueColor],[UIColor redColor]];
    NSArray *graphA = @[@"circle",@"rectangle",@"straight",@"curve",@"drawing"];
    
    for (index = 0; index < 5; index++)
    {
        colorButton = [HGBLSelectPanColorButton buttonWithFrame:CGRectMake(setX +  (setW + spacingX) * index, colorSetY, setW, setH) andColor:colorA[index]];
        [colorButton addTarget:self action:@selector(changeColor:) forControlEvents:UIControlEventTouchUpInside];
        colorButton.tag = index + kColorButtonTagBase;
        
        graphButton = [HGBLSelectGrpButton buttonWithFrame:CGRectMake(setX + (setW + spacingX) * index, graphSetY, setW, setH) andGrpName:graphA[index]];
        [graphButton addTarget:self action:@selector(changeGraph:) forControlEvents:UIControlEventTouchUpInside];
        graphButton.tag = index + kGraphButtonTagBase;
        
        [self addSubview:colorButton];
        [self addSubview:graphButton];
    }
    
    UIButton *clearButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 0, 100, 40)];
    clearButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [clearButton.titleLabel setFont:[UIFont systemFontOfSize:15.0]];
    [clearButton setTitle:@"清除全部" forState:UIControlStateNormal];
    [clearButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [clearButton addTarget:self action:@selector(clearAllDraw:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:clearButton];
}

- (void)changeColor:(HGBLSelectPanColorButton *)colorButton
{
    NSString *colorStr = nil;
    
    if (_changeDrawColorOption) {
        
        switch (colorButton.tag) {
            case kColorButtonTagBase:
                colorStr = @"white";
                break;
            case kColorButtonTagBase + 1:
                colorStr = @"green";
                break;
            case kColorButtonTagBase + 2:
                colorStr = @"yellow";
                break;
            case kColorButtonTagBase + 3:
                colorStr = @"blue";
                break;
            case kColorButtonTagBase + 4:
                colorStr = @"red";
                break;
            default:
                colorStr = @"red";
                break;
        }
        
        [self setAllGraphButtonColor:colorStr];
        _changeDrawColorOption(colorButton.backgroundColor,colorStr);
    }
}

- (void)changeGraph:(HGBLSelectGrpButton *)graphButton
{
    if (_changeDrawGraphOption) {
        _changeDrawGraphOption(graphButton.drawGrp,graphButton.tag - kGraphButtonTagBase);
    }
    
}

- (void)setAllGraphButtonColor:(NSString *)colorName
{
    HGBLSelectGrpButton *graphButton = nil;
    
    for (int index = 0; index < 5; index++)
    {
        graphButton = [self viewWithTag:(kGraphButtonTagBase + index)];
        
        [graphButton setGraphColor:colorName forState:UIControlStateNormal];
    }
}

- (void)clearAllDraw:(UIButton *)button
{
    if([_delegate respondsToSelector:@selector(selectPanToolViewRequestClearAllDraw:)])
    {
        [_delegate selectPanToolViewRequestClearAllDraw:self];
    }
}

@end
