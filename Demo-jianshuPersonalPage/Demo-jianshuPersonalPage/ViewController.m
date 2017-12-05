//
//  ViewController.m
//  Demo-jianshuPersonalPage
//
//  Created by GrabinWong on 2017/12/4.
//  Copyright © 2017年 GrabinWong. All rights reserved.
//

#import "ViewController.h"
#import "TextViewController.h"

#define CoverHeight 245

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //拉上拉 tab的最小值
    self.minYPullUp = 50;
}


/**
   控制器继承 SPCoverController
   此方法返回的是标题栏 标题
 */
- (NSString *)titleForIndex:(NSInteger)index
{
    return [NSString stringWithFormat:@"TAB%zd", index];
}

/*
    是否需要标题栏选中时候联动的下滑线
 */
- (BOOL)needMarkView
{
    return YES;
}

/*
    (SPCoverProtocol)不用管什么时机去生成coverview
 */
- (UIView *)preferCoverView
{
    UIView *view = [[UIView alloc] initWithFrame:[self preferCoverFrame]];
    view.backgroundColor = [UIColor yellowColor];
    
    return view;
}

/**
    标题栏View 的Y值
 */
- (CGFloat)preferTabY
{
    return CoverHeight;
}

/**
    顶部View frame
 */
- (CGRect)preferCoverFrame
{
    return CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, CoverHeight);
}

/**
    下面联动的ChildController控制器
 */
- (UIViewController *)controllerAtIndex:(NSInteger)index
{
    TextViewController *coverController = [[TextViewController alloc] init];
    coverController.view.frame = [self preferPageFrame];
    
    if (index == 0) {
        coverController.view.backgroundColor = [UIColor lightGrayColor];
    } else if (index == 1) {
        coverController.view.backgroundColor = [UIColor orangeColor];
    } else {
        coverController.view.backgroundColor = [UIColor purpleColor];
    }
    
    return coverController;
    
}

/**
    下面联动的ChildController控制器的数量
 */
- (NSInteger)numberOfControllers
{
    return 3;
}

/**
    交互切换的时候 是否预加载
 */
-(BOOL)isPreLoad {
    return YES;
}


@end
