//
//  UIColor+Extension.h
//  HuiGanBanLv
//
//  Created by  on 15/7/15.
//  Copyright (c) 2015年 HuiGanBanLv. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Extension)
#pragma mark - 颜色转换 IOS中十六进制的颜色转换为UIColor
+ (UIColor *) colorWithHexString: (NSString *)color;
@end
