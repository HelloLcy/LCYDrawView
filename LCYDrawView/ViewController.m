//
//  ViewController.m
//  LCYDrawView
//
//  Created by edianzu on 2017/6/15.
//  Copyright © 2017年 LCY. All rights reserved.
//

#import "ViewController.h"

#import "HGBLDrawView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor clearColor];
    HGBLDrawView *drawView = [[HGBLDrawView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:drawView];
}



@end
