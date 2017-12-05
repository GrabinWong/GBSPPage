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
