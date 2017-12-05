# GBSPPage
主要是介绍SPPage如何使用

######之前项目中有个需求，需要做类似简书个人主页效果的页面。
顶部是一个view，中间一个标题栏，底部是几个UITableView，滑动的时候，顶部View会跟着联动，不会影响下面UITableView的左右滑动。没有手势冲突。

![image.png](http://upload-images.jianshu.io/upload_images/2376772-5b7c5f444e6f5280.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/320)

![demo2.gif](http://upload-images.jianshu.io/upload_images/2376772-e465c2b9937a6e58.gif?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

######最近看到有大神封装的控件 [SPPage](https://github.com/xichen744/SPPage) (点击直接跳到github)，就是针对这样的需求的，这篇文章主要是讲如何使用SPPage。
下面直接把代码copy进来，该有的说明都在注释里面。

1.先把SPPage手动导入到项目中；

######主UIViewController
2.⚠️这个需要滑动的主UIViewController需要继承SPCoverController；
```
//
//  ViewController.h
//  Demo-jianshuPersonalPage
//
//  Created by GrabinWong on 2017/12/4.
//  Copyright © 2017年 GrabinWong. All rights reserved.
//

#import "SPCoverController.h"

@interface ViewController : SPCoverController


@end
```

#####.m文件中需要实现父类需要实现的方法，才能实现效果

```
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

```
######子控制器ChildController
3.联动的ChildController必须实现了
 <SPPageSubControllerDataSource> 这个协议，表示Tab和Cover会跟随Page纵向滑动
```
//
//  TextViewController.h
//  Demo-jianshuPersonalPage
//
//  Created by GrabinWong on 2017/12/4.
//  Copyright © 2017年 GrabinWong. All rights reserved.
//

#import "SPPageProtocol.h"

//如ChildController实现了这个协议<SPPageSubControllerDataSource>，表示Tab和Cover会跟随Page纵向滑动
@interface TextViewController : UIViewController<SPPageSubControllerDataSource>

@end

```
######需要实现 - (UIScrollView *)preferScrollView 这个代理方法，才能实现联动效果

![image.png](http://upload-images.jianshu.io/upload_images/2376772-248cf2b229a65835.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


```
//
//  TextViewController.m
//  Demo-jianshuPersonalPage
//
//  Created by GrabinWong on 2017/12/4.
//  Copyright © 2017年 GrabinWong. All rights reserved.
//

#import "TextViewController.h"

@interface TextViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation TextViewController

//如ChildController实现了这个协议，表示Tab和Cover会跟随Page纵向滑动
-(UIScrollView *)preferScrollView
{
    return self.tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.estimatedRowHeight= 0.0f;
}

#pragma mark - UITableViewDelegate Methods
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 0)];
    cell.textLabel.text = [NSString stringWithFormat:@"Row%zd",indexPath.row];
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}


@end

```


