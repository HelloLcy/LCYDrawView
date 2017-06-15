//
//  HGBLPanVideoView.m
//  HuiGanBanLv
//
//  Created by 挥杆伴侣 on 16/3/3.
//  Copyright © 2016年 HuiGanBanLv. All rights reserved.
//  绘图面板

#import <AudioToolbox/AudioToolbox.h>
#import "HGBLDrawView.h"

#import "HGBLSelectPanToolView.h"
#import "HGBLSelectGrpButton.h"

#import "HGBLArcPath.h"
#import "HGBLBezierPath.h"

#import "UIColor+Extension.h"


#define kLineWidth   2.0  //线宽
#define kOffsetRange 15.0   //选中路径允许的偏差
#define kOffsetAngle 10.0   //当路径为直线时,与Y轴夹角小于此角度,判断选中时另作处理
#define kKeyPointOffset 10.0 //判断端点是否被选中的允许偏差
#define kArcRadius  20.0

#define kSelectStartPoint   1
#define kSelectLastPoint    2
#define kSelectMiddlePoint  3

typedef enum{
    MoveArcPathTypeNone,
    MoveArcPathTypeKeyPoint,
    MoveArcPathTypeAllPoint
} MoveArcPathType;


@interface HGBLDrawView () <HGBLSelectPanToolViewDelegate>

/**当前图形*/
@property (copy,nonatomic) NSString *currentGrp;
/**当前颜色名称字符串*/
@property (copy,nonatomic) NSString *currentColorName;
/**当前颜色*/
@property (strong,nonatomic) UIColor *currentColor;
/**画图视图*/
@property (weak, nonatomic) HGBLSelectPanToolView *toolView;
/**选择画图工具按钮*/
@property (weak, nonatomic) UIButton *selectToolButton;
/**当前选中路径或最后一次添加的路径*/
@property (weak, nonatomic) UIButton *deletePathButton;


/**消除画图工具视图按钮*/
@property (weak, nonatomic) UIButton *closePanToolView;
/**当前图形类型*/
@property (assign,nonatomic)GraphState currentGraphState;
/**所有路径数组*/
@property (strong,nonatomic) NSMutableArray *bezierPaths;
/**当前触摸开始点*/
@property (assign,nonatomic) CGPoint beganTouchPoint;
/**当前选中的路径*/
@property (strong,nonatomic) HGBLBezierPath *selectBezierPath;
/**是否触摸*/
@property (assign,nonatomic) BOOL isBeganTouching;
/**是否选中了某条路径*/
@property (assign,nonatomic) BOOL isSelectOnePath;
/**是否增加一条新路径*/
@property (assign,nonatomic) BOOL isAddNewPath;
/**移动弧形路径的方式*/
@property (assign,nonatomic) MoveArcPathType moveArcPathType;

@end


@implementation HGBLDrawView
{
    CGPoint    _preMovePoint;
    NSInteger  _drawTextOffsetX;
    NSInteger  _drawTextOffsetY;
    NSUInteger _selectPointType;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.currentGrp = @"circle";
        self.currentColorName = @"white";
        self.currentColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor clearColor];
        //创建子控件
        [self creatSubViews];
    }
    
    return self;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self.bezierPaths addObject:image];
    [self setNeedsDisplay];
}

//创建子控件
- (void)creatSubViews
{
    CGFloat panViewWidth = self.bounds.size.width;
    CGFloat panViewHeight = self.bounds.size.height;
    //选择画板工具按钮
    UIButton *selectButton = [[UIButton alloc] initWithFrame:CGRectMake(panViewWidth - 60, panViewHeight - 60, 50, 40)];
    selectButton.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    selectButton.layer.cornerRadius = 5;
    [selectButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"analysis_%@_%@",_currentGrp,_currentColorName]] forState:UIControlStateNormal];
    [selectButton addTarget:self action:@selector(selectAnalysisTool:) forControlEvents:UIControlEventTouchUpInside];
    _selectToolButton = selectButton;
    //撤销按钮
    CGFloat setX = CGRectGetMinX(selectButton.frame);
    CGFloat setY = CGRectGetMinY(selectButton.frame);
    UIButton *deletePath = [[UIButton alloc]initWithFrame:CGRectMake(setX, setY - 40, 50, 32)];
    deletePath.contentMode = UIViewContentModeBottom;
    deletePath.titleLabel.font = [UIFont systemFontOfSize:15.0];
    deletePath.titleLabel.textAlignment = NSTextAlignmentCenter;
    [deletePath setTitle:@"撤销" forState:UIControlStateNormal];
    [deletePath setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6]];
    deletePath.layer.cornerRadius = 5;
    
    [deletePath addTarget:self action:@selector(deleteBezierPath:) forControlEvents:UIControlEventTouchUpInside];
    deletePath.hidden = YES;
    _deletePathButton = deletePath;
    
    //画板工具
    setX = 10;  //起点
    CGFloat setH = 200; //高
    HGBLSelectPanToolView *panTool = [[HGBLSelectPanToolView alloc] initWithFrame:CGRectMake(setX, (panViewHeight - setH) * 0.5, panViewWidth - setX * 2, setH)];
    _toolView = panTool;
    _toolView.delegate = self;
    panTool.changeDrawColorOption = ^(UIColor *color,NSString *colorName){
    
        if (color != nil) {
            _currentColor = color;
            _currentColorName = colorName;
            _toolView.hidden = YES;
            _closePanToolView.hidden = YES;
        }
        
        [_selectToolButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"analysis_%@_%@",_currentGrp,_currentColorName]] forState:UIControlStateNormal];
    };
    panTool.changeDrawGraphOption = ^(NSString *graph,NSInteger graphState){
        
        if (graph.length) {
            _currentGrp = graph;
            _toolView.hidden = YES;
            _closePanToolView.hidden = YES;
            _currentGraphState = (GraphState)graphState;
        }
        
        [_selectToolButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"analysis_%@_%@",_currentGrp,_currentColorName]] forState:UIControlStateNormal];
    };
    //隐藏画板工具按钮
    setX = CGRectGetMaxX(panTool.frame) - 60;
    setY = CGRectGetMinY(panTool.frame) - 40;
    UIButton *closePanTool = [[UIButton alloc] initWithFrame:CGRectMake(setX, setY, 30, 40)];
    [closePanTool setImage:[UIImage imageNamed:@"calendar_close_icon"] forState:UIControlStateNormal];
    [closePanTool addTarget:self action:@selector(closePanToolView:) forControlEvents:UIControlEventTouchUpInside];
    _closePanToolView = closePanTool;
    panTool.hidden = YES;
    closePanTool.hidden = YES;
    
    [self addSubview:panTool];
    [self addSubview:deletePath];
    [self addSubview:closePanTool];
    [self addSubview:selectButton];
}

- (void)deleteBezierPath:(UIButton *)deleteButton
{
    if ([deleteButton.titleLabel.text isEqualToString:@"删除"])
    {
        [self.bezierPaths removeObject:_selectBezierPath];

        _isSelectOnePath = NO;
        _selectBezierPath = nil;
        [self setNeedsDisplay];
        [deleteButton setTitle:@"撤销" forState:UIControlStateNormal];
    }
    else
    {
        [self.bezierPaths removeLastObject];
        [self setNeedsDisplay];
    }

    if (self.bezierPaths.count < 1)
        deleteButton.hidden = YES;
}

- (void)selectAnalysisTool:(UIButton *)button
{
    _toolView.hidden = !_toolView.hidden;
    _closePanToolView.hidden = _toolView.hidden;
}

- (void)closePanToolView:(UIButton *)button
{
    button.hidden = YES;
    _toolView.hidden = YES;
}

#pragma -mark 画板工具代理方法
- (void)selectPanToolViewRequestClearAllDraw:(HGBLSelectPanToolView *)panTool
{
    panTool.hidden = YES;
    _closePanToolView.hidden = YES;
    _deletePathButton.hidden = YES;
    [self.bezierPaths removeAllObjects];
    [self setNeedsDisplay];
}

- (NSMutableArray *)bezierPaths
{
    if (_bezierPaths == nil)
    {
        _bezierPaths = [NSMutableArray array];
    }
    
    return _bezierPaths;
}


- (CGPoint)touchAtPointInView:(NSSet<UITouch *> *)touches
{
    UITouch *touch = [touches anyObject];
    
    CGPoint point = [touch locationInView:self];
    
    //转化为整形值
    int  x = point.x;
    int  y = point.y;
    
    return CGPointMake(x, y);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _isBeganTouching = YES;
    _beganTouchPoint = [self touchAtPointInView:touches];
    _preMovePoint = _beganTouchPoint;
    //隐藏选择工具
    if (! CGRectContainsPoint(_toolView.frame, _beganTouchPoint))
    {
        _toolView.hidden = YES;
        _closePanToolView.hidden = YES;
    }
    
    if (_isSelectOnePath)
    {
        if ([self judgeSelectStartOrLastPoint:&_selectPointType])
        {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);  //震动一下
            return;
        }
    }
    if ([self browseBezierPathsForDraw:NO])
    {
        [self setNeedsDisplay];
    }
    else
    {
        if (_currentGraphState == GraphStateOther)
        {
            HGBLArcPath *arcPath = [HGBLArcPath arcPathWithTouchPoint:_beganTouchPoint];
            arcPath.pathColor = _currentColor;
            arcPath.currentGraph = _currentGraphState;
            //默认选中当前绘制的路径
            _isSelectOnePath = YES;
            _selectBezierPath = arcPath;
            _selectPointType = kSelectMiddlePoint;
            [self.bezierPaths addObject:arcPath];
            [self setNeedsDisplay];
            _isBeganTouching = NO;
        }
    }
    
    if (_deletePathButton.hidden == NO)
    {
        if (_isSelectOnePath && ![_deletePathButton.titleLabel.text isEqualToString:@"删除"]) {
            [_deletePathButton setTitle:@"删除" forState:UIControlStateNormal];
        }
        else if(! _isSelectOnePath && [_deletePathButton.titleLabel.text isEqualToString:@"删除"])
        {
            [_deletePathButton setTitle:@"撤销" forState:UIControlStateNormal];
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _moveArcPathType = MoveArcPathTypeNone;
    CGPoint touchPoint = [self touchAtPointInView:touches];

    if (_isSelectOnePath == NO)
    {
        if (_currentGraphState == GraphStateOther)
            return;
   
        HGBLBezierPath *bezierPath = [HGBLBezierPath bezierPath];
        
        if (bezierPath == nil)
            return;
        
        if (_isBeganTouching)
        {
            _isBeganTouching = NO;
            bezierPath.startPoint = _beganTouchPoint;
            bezierPath.currentGraph = _currentGraphState;
            bezierPath.pathColor = _currentColor;
            [self.bezierPaths addObject:bezierPath];
            
            if (_currentGraphState == GraphStateCurve)
                [bezierPath moveToPoint:_beganTouchPoint];
            else
                _isAddNewPath = YES;
        }
        else
        {
            bezierPath = [self.bezierPaths lastObject];
        }
        
        bezierPath.lastPoint = touchPoint;
    }
    else
    {
        if (_selectPointType == kSelectStartPoint)
        {
            _moveArcPathType = MoveArcPathTypeKeyPoint;
            _selectBezierPath.startPoint = touchPoint;
        }
        else if(_selectPointType == kSelectLastPoint)
        {
            _moveArcPathType = MoveArcPathTypeKeyPoint;
            _selectBezierPath.lastPoint = touchPoint;
        }
        else if(_selectPointType == kSelectMiddlePoint)
        {
            _moveArcPathType = MoveArcPathTypeKeyPoint;
            HGBLArcPath *path = (HGBLArcPath *)_selectBezierPath;
            path.middlePoint = touchPoint;
        }
        else
        {
            _moveArcPathType = MoveArcPathTypeAllPoint;
            //移动所选路径
            CGFloat increaseX = touchPoint.x - _preMovePoint.x;
            CGFloat increaseY = touchPoint.y - _preMovePoint.y;
            _preMovePoint = touchPoint;
            _selectBezierPath.startPoint = CGPointMake(_selectBezierPath.startPoint.x + increaseX, _selectBezierPath.startPoint.y + increaseY);
            _selectBezierPath.lastPoint = CGPointMake(_selectBezierPath.lastPoint.x + increaseX, _selectBezierPath.lastPoint.y + increaseY);
            if ([_selectBezierPath isKindOfClass:[HGBLArcPath class]])
            {
                HGBLArcPath *path = (HGBLArcPath *)_selectBezierPath;
                path.middlePoint = CGPointMake(path.middlePoint.x + increaseX, path.middlePoint.y + increaseY);
            }
        }
    }
    
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _isBeganTouching = NO;
    if (_isAddNewPath == YES)
    {
        _isAddNewPath = NO;
        _isSelectOnePath = YES;
        _selectBezierPath = [self.bezierPaths lastObject];
        [self setNeedsDisplay];
    }
}

/**
 计算给定的两点之间的X轴差距
 */
- (CGFloat)getGapXOfPointA:(CGPoint)pointA pointB:(CGPoint)pointB
{
    CGFloat gapX;
    
    gapX = (pointA.x > pointB.x) ? (pointA.x - pointB.x) : (pointB.x - pointA.x);
    
    return gapX;
}

/**
 计算给定的两点之间的Y轴差距
 */

- (CGFloat)getGapYOfPointA:(CGPoint)pointA pointB:(CGPoint)pointB
{
    CGFloat gapY;
    
    gapY = (pointA.y > pointB.y) ? (pointA.y - pointB.y) : (pointB.y - pointA.y);
    
    return gapY;
}

/**
 判断当前触摸点是否是选中路径的起点或终点
 type返回触摸点的类型
 1：起点
 2：终点
 0：其它点
 */
- (BOOL)judgeSelectStartOrLastPoint:(NSUInteger *)type
{
    *type = 0;
    
    BOOL conditionA1 = (_beganTouchPoint.x >= (_selectBezierPath.startPoint.x - kKeyPointOffset) && _beganTouchPoint.x <= (_selectBezierPath.startPoint.x + kKeyPointOffset));
    BOOL conditionA2 = (_beganTouchPoint.y >= (_selectBezierPath.startPoint.y - kKeyPointOffset) && _beganTouchPoint.y <= (_selectBezierPath.startPoint.y + kKeyPointOffset));
    
    BOOL conditionB1 = (_beganTouchPoint.x >= (_selectBezierPath.lastPoint.x - kKeyPointOffset) && _beganTouchPoint.x <= (_selectBezierPath.lastPoint.x + kKeyPointOffset));
    BOOL conditionB2 = (_beganTouchPoint.y >= (_selectBezierPath.lastPoint.y - kKeyPointOffset) && _beganTouchPoint.y <= (_selectBezierPath.lastPoint.y + kKeyPointOffset));
    
    if ((conditionA1 && conditionA2) ||(conditionB1 && conditionB2))
    {
        *type = (conditionA1 && conditionA2) ? kSelectStartPoint : kSelectLastPoint;
        
        return YES;
    }
    else if([_selectBezierPath isKindOfClass:[HGBLArcPath class]])
    {
        HGBLArcPath *arcPath = (HGBLArcPath *)_selectBezierPath;
        BOOL conditionC1 = (_beganTouchPoint.x >= (arcPath.middlePoint.x - kKeyPointOffset) && _beganTouchPoint.x <= (arcPath.middlePoint.x + kKeyPointOffset));
        BOOL conditionC2 = (_beganTouchPoint.y >= (arcPath.middlePoint.y - kKeyPointOffset) && _beganTouchPoint.y <= (arcPath.middlePoint.y + kKeyPointOffset));
        if (conditionC1 && conditionC2)
        {
            *type = kSelectMiddlePoint;
            
            return YES;
        }
    }
    
    return NO;
}

//重写父类drawRect:(CGRect)rect方法 进行绘图
- (void)drawRect:(CGRect)rect
{
    [self browseBezierPathsForDraw:YES];//重绘路径
    
    if (_selectBezierPath)
    {
        _deletePathButton.hidden = NO;
        [_deletePathButton setTitle:@"删除" forState:UIControlStateNormal]; //因为默认选中当前路径，所以出现即设为删除
    }
    else if(self.bezierPaths.count)
    {
        _deletePathButton.hidden = NO;
        [_deletePathButton setTitle:@"撤销" forState:UIControlStateNormal]; //
    }
    
    if(self.bezierPaths.count < 1)
    {
        _isSelectOnePath = NO;
        _selectBezierPath = nil;
       _deletePathButton.hidden = YES;
    }
    
}

/**
 遍历所有路径
 if ‘isDraw’ is true ，重新绘制所有路径
 is false ， 判断是否选中了某个路径
 */

- (BOOL)browseBezierPathsForDraw:(BOOL)isDraw
{
    UIImage *image = nil;
    HGBLBezierPath *bezierPath = nil;
    
    if (isDraw != YES)
    {
        _isSelectOnePath = NO;
        if (_selectBezierPath) {
            _selectBezierPath = nil;
            [self setNeedsDisplay];
        };
    }
    
    for (int index = 0; index < self.bezierPaths.count; index++)
    {
        if ([self.bezierPaths[index] isKindOfClass:[UIImage class]])
            image = (UIImage *)self.bezierPaths[index];
        else
            bezierPath = (HGBLBezierPath *)self.bezierPaths[index];
            
            
        if (isDraw == YES)
        {
            if (image != nil)
            {
                [image drawInRect:self.frame];
                image = nil;
                continue;
            }
            
            [bezierPath.pathColor setStroke];
            bezierPath.lineWidth = kLineWidth;
            [self setSelectSymbol:bezierPath];
        }
        
        switch (bezierPath.currentGraph)
        {
            case GraphStateCircle: //圆
            {
                [self drawUpCircleGraphOnPath:bezierPath isDraw:isDraw];
                break;
            }
            case GraphStateRectangle: //矩形
            {
                [self drawUpRectGraphOnPath:bezierPath isDraw:isDraw];
                break;
            }
            case GraphStateOther:
            {
                [self drawUpOtherGraphOnPath:bezierPath isDraw:isDraw];
                break;
            }
            case GraphStateStraight: //直线
            {
                [self drawUpLineGraphOnPath:bezierPath isDraw:isDraw];
                break;
            }
            case GraphStateCurve: //铅笔
            {
                if (isDraw == YES)
                {
                    [bezierPath addLineToPoint:bezierPath.lastPoint];
                    [bezierPath stroke];
                }
                
                continue;
            }
        }
        
        if (_isSelectOnePath && isDraw == NO)
        {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            return YES;
        }
    }
    
    return NO;
}


/**
    返回某一点在以参考点为原点的坐标轴的哪个象限里
 */
- (NSUInteger)getQuadrantWithPoint:(CGPoint)point ofReferencePoint:(CGPoint)refPonint
{
    CGFloat gapX = point.x - refPonint.x;
    CGFloat gapY = refPonint.y - point.y;
    
    if (gapX >= 0)
        return (gapY > 0 ? 1 : 4);
    else
        return (gapY > 0 ? 2 : 3);
}

/**
 显示给定弧形的角度
 */
- (void)calculateAngleDrawPointWithArcPath:(HGBLArcPath *)arcPath
{
    CGPoint startMiddPoint = arcPath.startPoint;
    CGPoint lastMiddPoint = arcPath.lastPoint;
    CGFloat startMiddleGapX = arcPath.startPoint.x - arcPath.middlePoint.x;//l.x
    CGFloat startMiddleGapY = arcPath.middlePoint.y - arcPath.startPoint.y ;//l.y
    CGFloat lastMiddleGapX = arcPath.lastPoint.x - arcPath.middlePoint.x;//s.x
    CGFloat lastMiddleGapY = arcPath.middlePoint.y - arcPath.lastPoint.y;//s.y
    CGFloat startMiddLength = sqrtf(startMiddleGapX * startMiddleGapX + startMiddleGapY * startMiddleGapY);
    CGFloat lastMiddLength = sqrtf(lastMiddleGapX * lastMiddleGapX + lastMiddleGapY * lastMiddleGapY);
    //判断线段长度
    if (startMiddLength > 50)
    {
        CGFloat value = (kArcRadius + 10) / startMiddLength;
        NSInteger pointX = startMiddleGapX * value + arcPath.middlePoint.x;
        NSInteger pointY = -startMiddleGapY * value + arcPath.middlePoint.y;
        startMiddPoint = CGPointMake(pointX, pointY);
    }
    if (lastMiddLength > 50)
    {
        CGFloat value = (kArcRadius + 10) / lastMiddLength;
        NSInteger pointX = lastMiddleGapX * value + arcPath.middlePoint.x;
        NSInteger pointY = -lastMiddleGapY * value + arcPath.middlePoint.y;
        lastMiddPoint = CGPointMake(pointX, pointY);
    }
    //计算角度文本显示的位置Point
    CGFloat drawPointX = (startMiddPoint.x + lastMiddPoint.x) * 0.5 + _drawTextOffsetX;
    CGFloat drawPointY = (startMiddPoint.y + lastMiddPoint.y) * 0.5 + _drawTextOffsetY;
    arcPath.textDrawPoint = CGPointMake(drawPointX, drawPointY);
}


/**
 计算给定弧形的起始角度，起始与结束角度差值
 */
- (void)calculateAngleWithArcPath:(HGBLArcPath *)arcPath
{
    CGFloat startMiddleGapX = arcPath.startPoint.x - arcPath.middlePoint.x;//l.x
    CGFloat startMiddleGapY = arcPath.middlePoint.y - arcPath.startPoint.y ;//l.y
    CGFloat lastMiddleGapX = arcPath.lastPoint.x - arcPath.middlePoint.x;//s.x
    CGFloat lastMiddleGapY = arcPath.middlePoint.y - arcPath.lastPoint.y;//s.y
    CGFloat startLastGapX = arcPath.lastPoint.x - arcPath.startPoint.x;
    CGFloat startLastGapY = arcPath.lastPoint.y - arcPath.startPoint.y;
    
    CGFloat startMiddLengthSquare = startMiddleGapX * startMiddleGapX + startMiddleGapY * startMiddleGapY;
    CGFloat lastMiddLengthSquare = lastMiddleGapX * lastMiddleGapX + lastMiddleGapY * lastMiddleGapY;
    CGFloat startLastLengthSquare = startLastGapX * startLastGapX + startLastGapY * startLastGapY;
    
    CGFloat squareValue = startMiddLengthSquare + lastMiddLengthSquare - startLastLengthSquare;
    CGFloat divValue = 2 * sqrtf(startMiddLengthSquare) * sqrtf(lastMiddLengthSquare);
    CGFloat angleCosValue = squareValue / divValue;
    //得到夹角
    arcPath.intersectionAngle = acosf(angleCosValue);
    
    NSUInteger startPonitQuadrant = [self getQuadrantWithPoint:arcPath.startPoint ofReferencePoint:arcPath.middlePoint] & 0x0f;
    NSUInteger lastPointQuadrant = [self getQuadrantWithPoint:arcPath.lastPoint ofReferencePoint:arcPath.middlePoint] & 0x0f;
    NSUInteger quadrantType = (startPonitQuadrant << 4) + lastPointQuadrant;

    switch (quadrantType & 0xff)
    {
        case 0x11://两线段同在第一象限
        {
            _drawTextOffsetY = -10;
            _drawTextOffsetX = 20;
            CGFloat angleSinValue_S = startMiddleGapY / sqrtf(startMiddLengthSquare);
            CGFloat angleSinValue_L = lastMiddleGapY / sqrtf(lastMiddLengthSquare);
            CGFloat angleSinValue = MAX(angleSinValue_S, angleSinValue_L);
            arcPath.startAngle = M_PI * 2 - asinf(angleSinValue);
            
            break;
        }
        case 0x22://两线段同在第2象限
        {
            _drawTextOffsetY = -30;
            _drawTextOffsetX = -20;
            CGFloat angleSinValue_S = startMiddleGapY / sqrtf(startMiddLengthSquare);
            CGFloat angleSinValue_L = lastMiddleGapY / sqrtf(lastMiddLengthSquare);
            CGFloat angleSinValue = MIN(angleSinValue_S, angleSinValue_L);
            arcPath.startAngle = M_PI + asinf(angleSinValue);
            
            break;
        }
        case 0x33://两线段同在第3象限
        {
            _drawTextOffsetY = 10;
            _drawTextOffsetX = -20;
            CGFloat angleSinValue_S = -startMiddleGapX / sqrtf(startMiddLengthSquare);
            CGFloat angleSinValue_L = -lastMiddleGapX / sqrtf(lastMiddLengthSquare);
            CGFloat angleSinValue = MIN(angleSinValue_S, angleSinValue_L);
            arcPath.startAngle = M_PI * 0.5 + asinf(angleSinValue);
            
            break;
        }
        case 0x44://两线段同在第4象限
        {
            _drawTextOffsetY = 10;
            _drawTextOffsetX = 30;
            CGFloat angleSinValue_S = -startMiddleGapY / sqrtf(startMiddLengthSquare);
            CGFloat angleSinValue_L = -lastMiddleGapY / sqrtf(lastMiddLengthSquare);
            CGFloat angleSinValue = MIN(angleSinValue_S, angleSinValue_L);
            arcPath.startAngle = asinf(angleSinValue);
            
            break;
        }
        case 0x12:
        case 0x21:
        {
            CGFloat angleSinValue;
            
            _drawTextOffsetY = -30;
            _drawTextOffsetX = -10;
            if (arcPath.startPoint.x < arcPath.lastPoint.x)
                angleSinValue = startMiddleGapY / sqrtf(startMiddLengthSquare);
            else
                angleSinValue = lastMiddleGapY / sqrtf(lastMiddLengthSquare);
            arcPath.startAngle = M_PI + asinf(angleSinValue);
            
            break;
        }
        case 0x13:
        case 0x31:
        {
            //默认startPoint在第一象限
            CGFloat angleSinValue_1 = startMiddleGapY / sqrtf(startMiddLengthSquare);
            CGFloat angleSinValue_3 = -lastMiddleGapY / sqrtf(lastMiddLengthSquare);
            //如果startPoint在第三象限
            if (arcPath.startPoint.x < arcPath.lastPoint.x)
            {
                angleSinValue_3 = -startMiddleGapY / sqrtf(startMiddLengthSquare);
                angleSinValue_1 = lastMiddleGapY / sqrtf(lastMiddLengthSquare);
            }
            
            if (angleSinValue_1 >= angleSinValue_3)
            {
                _drawTextOffsetY = -30;
                _drawTextOffsetX = -30;
                arcPath.startAngle = M_PI - asinf(angleSinValue_3);
            }
            else
            {
                _drawTextOffsetY = 30;
                _drawTextOffsetX = 30;
                arcPath.startAngle = M_PI * 2 - asinf(angleSinValue_1);
            }
           
            break;
        }
        case 0x14:
        case 0x41:
        {
            CGFloat angleSinValue;
            
            _drawTextOffsetY = -10;
            _drawTextOffsetX = 30;
            if (arcPath.startPoint.y <= arcPath.lastPoint.y)
                angleSinValue = startMiddleGapY / sqrtf(startMiddLengthSquare);
            else
                angleSinValue = lastMiddleGapY / sqrtf(lastMiddLengthSquare);
            arcPath.startAngle = M_PI * 2 - asinf(angleSinValue);
            
            break;
        }
        case 0x23:
        case 0x32:
        {
            CGFloat angleSinValue;
            
            _drawTextOffsetY = -10;
            _drawTextOffsetX = -30;
            if (arcPath.startPoint.y >= arcPath.lastPoint.y)
                angleSinValue = -startMiddleGapX / sqrtf(startMiddLengthSquare);
            else
                angleSinValue = -lastMiddleGapX / sqrtf(lastMiddLengthSquare);
            arcPath.startAngle = M_PI * 0.5 + asinf(angleSinValue);
            
            break;
        }
        case 0x24:
        case 0x42:
        {
            //默认startPoint在第二象限
            CGFloat angleSinValue_2 = startMiddleGapY / sqrtf(startMiddLengthSquare);
            CGFloat angleSinValue_4 = -lastMiddleGapY / sqrtf(lastMiddLengthSquare);
            //如果startPoint在第四象限
            if (arcPath.startPoint.x >= arcPath.lastPoint.x)
            {
                angleSinValue_4 = -startMiddleGapY / sqrtf(startMiddLengthSquare);
                angleSinValue_2 = lastMiddleGapY / sqrtf(lastMiddLengthSquare);
            }

            if (angleSinValue_4 >= angleSinValue_2)
            {
                _drawTextOffsetY = 30;
                _drawTextOffsetX = -30;
                arcPath.startAngle = asinf(angleSinValue_4);
            }
            else
            {
                _drawTextOffsetY = -30;
                _drawTextOffsetX = 30;
                arcPath.startAngle = asinf(angleSinValue_2) + M_PI;
            }
            
            break;
        }
        case 0x34:
        case 0x43:
        {
            CGFloat angleSinValue;
            
            _drawTextOffsetY = 20;
            _drawTextOffsetX = -5;
            if (arcPath.startPoint.x >= arcPath.lastPoint.x)
                angleSinValue = -startMiddleGapY / sqrtf(startMiddLengthSquare);
            else
                angleSinValue = -lastMiddleGapY / sqrtf(lastMiddLengthSquare);
            arcPath.startAngle = asinf(angleSinValue);
            
            break;
        }
           
        default:
            break;
    }
}

/**
 铅笔
 */
- (void)drawUpOtherGraphOnPath:(HGBLBezierPath *)bezierPath isDraw:(BOOL)isDraw
{
    HGBLArcPath *arcPath = (HGBLArcPath *)bezierPath;
    HGBLBezierPath *path1 = [HGBLBezierPath bezierPath];
    HGBLBezierPath *path2 = [HGBLBezierPath bezierPath];
    
    if (isDraw == YES)
    {
        //计算起始角度及夹角大小,(某一关键点单独被改变时才需要从新计算)
        if (MoveArcPathTypeKeyPoint == _moveArcPathType)
            [self calculateAngleWithArcPath:arcPath];
        //画直线
        [path1 setLineCapStyle:kCGLineCapRound];
        [path1 setLineWidth:arcPath.lineWidth];
        [path2 setLineCapStyle:kCGLineCapRound];
        [path2 setLineWidth:arcPath.lineWidth];
        [path1 moveToPoint:arcPath.startPoint];
        [path2 moveToPoint:arcPath.middlePoint];
        [path1 addLineToPoint:arcPath.middlePoint];
        [path2 addLineToPoint:arcPath.lastPoint];
        [path1 stroke];
        [path2 stroke];
        
        CGMutablePathRef cgPath = CGPathCreateMutable();
        CGPathAddArc(cgPath, NULL, arcPath.middlePoint.x, arcPath.middlePoint.y, kArcRadius, arcPath.startAngle, arcPath.startAngle + arcPath.intersectionAngle, arcPath.clockWise);
        bezierPath.CGPath = cgPath;
        CGPathRelease(cgPath);
        [bezierPath stroke];
        //计算显示角度的位置
        if (MoveArcPathTypeNone != _moveArcPathType && [_selectBezierPath isEqual:bezierPath])
            [self calculateAngleDrawPointWithArcPath:arcPath];
        
        NSUInteger angle = (arcPath.intersectionAngle / M_PI) * 180 + 0.5;
        NSString *textAngle = [NSString stringWithFormat:@"%d°",angle];
        NSDictionary *dict = @{NSFontAttributeName : [UIFont boldSystemFontOfSize:15.0],NSForegroundColorAttributeName : arcPath.pathColor};
        [textAngle drawAtPoint:arcPath.textDrawPoint withAttributes:dict];
    }
    else
    {
        path1.startPoint = arcPath.startPoint;
        path1.lastPoint = arcPath.middlePoint;
        path2.startPoint = arcPath.lastPoint;
        path2.lastPoint = arcPath.middlePoint;
        if ([self judgeTouchPointAtBezierPath:path1] || [self judgeTouchPointAtBezierPath:path2])
        {
            _isSelectOnePath = YES;
            _selectBezierPath = bezierPath;
        }
    }
}
/**
 画圆 或 判断是否选中某圆
 */
- (void)drawUpCircleGraphOnPath:(HGBLBezierPath *)bezierPath isDraw:(BOOL)isDraw
{
    CGFloat gapX = [self getGapXOfPointA:bezierPath.startPoint pointB:bezierPath.lastPoint];
    CGFloat gapY = [self getGapYOfPointA:bezierPath.startPoint pointB:bezierPath.lastPoint];
    
    CGFloat radius = sqrtf(gapX * gapX + gapY * gapY) * 0.5;
    CGFloat centerX = (bezierPath.lastPoint.x + bezierPath.startPoint.x) * 0.5;
    CGFloat centerY = (bezierPath.lastPoint.y + bezierPath.startPoint.y) * 0.5;
    
    if (isDraw == YES)
    {
        CGMutablePathRef cgPath = CGPathCreateMutable();
        CGPathAddArc(cgPath, NULL, centerX, centerY, radius, 0, M_PI * 2, NO);
        bezierPath.CGPath = cgPath;
        CGPathRelease(cgPath);
        [bezierPath stroke];
    }
    else
    {
        CGFloat getX = _beganTouchPoint.x - centerX ;
        CGFloat getY = _beganTouchPoint.y - centerY;
        
        CGFloat rangeA = (radius - kOffsetRange) * (radius - kOffsetRange);
        CGFloat rangeB = (radius + kOffsetRange) * (radius + kOffsetRange);
        
        if ((getX * getX + getY * getY) >= rangeA && (getX * getX + getY * getY) <= rangeB)
        {
            _isSelectOnePath = YES;
            _selectBezierPath = bezierPath;
         }
    }
    
}
/**
 画矩形  或 判断当前是否选中矩形
 */
- (void)drawUpRectGraphOnPath:(HGBLBezierPath *)bezierPath isDraw:(BOOL)isDraw
{
    CGFloat gapX = [self getGapXOfPointA:bezierPath.startPoint pointB:bezierPath.lastPoint];
    CGFloat gapY = [self getGapYOfPointA:bezierPath.startPoint pointB:bezierPath.lastPoint];
    CGFloat leftX = MIN(bezierPath.startPoint.x, bezierPath.lastPoint.x);
    CGFloat leftY = MIN(bezierPath.startPoint.y, bezierPath.lastPoint.y);
    
    if (isDraw == YES)
    {
        CGMutablePathRef cgPath = CGPathCreateMutable();
        CGPathAddRect(cgPath, NULL, CGRectMake(leftX, leftY, gapX, gapY));
        bezierPath.CGPath = cgPath;
        CGPathRelease(cgPath);
        [bezierPath stroke];
    }
    else
    {
        BOOL condition1 = (_beganTouchPoint.x >= (leftX - kOffsetRange) && _beganTouchPoint.x <= (leftX + kOffsetRange));
        BOOL condition2 = (_beganTouchPoint.x >= (leftX + gapX - kOffsetRange) && _beganTouchPoint.x <= (leftX + gapX + kOffsetRange));
        BOOL condition3 = (_beganTouchPoint.y >= (leftY - kOffsetRange) && _beganTouchPoint.y <= (leftY + kOffsetRange));
        BOOL condition4 = (_beganTouchPoint.y >= (leftY + gapY - kOffsetRange) && _beganTouchPoint.y <= (leftY + gapY + kOffsetRange));
        BOOL condition5 = ((_beganTouchPoint.x >= leftX) && (_beganTouchPoint.x <= leftX + gapX));
        BOOL condition6 = ((_beganTouchPoint.y >= leftY) && (_beganTouchPoint.y <= leftY + gapY));
        
        if ((condition6 && (condition1 || condition2))
            ||(condition5 && (condition3 || condition4)))
        {
            _isSelectOnePath = YES;
            _selectBezierPath = bezierPath;
        }
    }
}
/**
 画直线 或 判断是否选中直线
 */
- (void)drawUpLineGraphOnPath:(HGBLBezierPath *)bezierPath isDraw:(BOOL)isDraw
{
    if (isDraw == YES)
    {
        CGMutablePathRef cgPath = CGPathCreateMutable();
        CGPathMoveToPoint(cgPath, nil, bezierPath.startPoint.x, bezierPath.startPoint.y);
        CGPathAddLineToPoint(cgPath, nil, bezierPath.lastPoint.x, bezierPath.lastPoint.y);
        bezierPath.CGPath = cgPath;
        CGPathRelease(cgPath);
        [bezierPath stroke];
    }
    else
    {
        if ([self judgeTouchPointAtBezierPath:bezierPath])
        {
            _isSelectOnePath = YES;
            _selectBezierPath = bezierPath;
        }
    }
   
}

/**
    设置选中路径的选中标识  == 放大起点和终点
 */
- (void)setSelectSymbol:(HGBLBezierPath *)beziePath
{
    if (_selectBezierPath == beziePath)
    {
        //绘制选中标志
        [_selectBezierPath.pathColor setFill];
        HGBLBezierPath *path = [HGBLBezierPath bezierPathWithArcCenter:_selectBezierPath.startPoint radius:5.0 startAngle:0 endAngle:M_PI * 2 clockwise:NO];
        [path appendPath:[HGBLBezierPath bezierPathWithArcCenter:_selectBezierPath.lastPoint radius:5.0 startAngle:0 endAngle:M_PI * 2 clockwise:NO]];
        if ([beziePath isKindOfClass:[HGBLArcPath class]])
        {
            HGBLArcPath *arcPath = (HGBLArcPath *)beziePath;
            [path appendPath:[HGBLBezierPath bezierPathWithArcCenter:arcPath.middlePoint radius:5.0 startAngle:0 endAngle:M_PI * 2 clockwise:NO]];
        }
        [path fill];
        [path stroke];
    }
}

/**
 判断当前触摸点是否在指定路径上
 */

- (BOOL)judgeTouchPointAtBezierPath:(HGBLBezierPath *)bezierPath
{
    //计算线段X、Y的范围
    CGFloat minX = MIN(bezierPath.startPoint.x, bezierPath.lastPoint.x);
    CGFloat maxX = MAX(bezierPath.startPoint.x, bezierPath.lastPoint.x);
    CGFloat minY = MIN(bezierPath.startPoint.y, bezierPath.lastPoint.y);
    CGFloat maxY = MAX(bezierPath.startPoint.y, bezierPath.lastPoint.y);
    
    CGFloat endx = bezierPath.lastPoint.x;
    CGFloat endy = bezierPath.lastPoint.y;
    CGFloat startx = bezierPath.startPoint.x;
    CGFloat starty = bezierPath.startPoint.y;
    
    CGFloat dy = (_beganTouchPoint.x - startx) * (endy - starty) / (endx - startx);
    CGFloat dx = (_beganTouchPoint.y - starty) * (endx - startx) / (endy - starty);//
    
    if ((_beganTouchPoint.y <= maxY + kKeyPointOffset)
        && _beganTouchPoint.y >= (minY - kKeyPointOffset)
        && _beganTouchPoint.x <= (maxX + kKeyPointOffset)
        && _beganTouchPoint.x >= (minX - kKeyPointOffset)
        && (fabs(dy - (_beganTouchPoint.y - starty)) <= kKeyPointOffset + 15 || fabs(dx - (_beganTouchPoint.x - startx)) <= kKeyPointOffset + 15))
    {
            return YES;
    }
    else
    {
            return NO;
    }
}

-(void)removeAllPath {
    [_bezierPaths removeAllObjects];
    [self setNeedsDisplay];
}

@end
