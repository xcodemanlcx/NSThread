//
//  RootViewController.h
//  myNSThread
//
//  Created by leichunxiang on 14-5-20.
//  Copyright (c) 2014年 qianfeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController

// 原子操作 加锁 牺牲系统的性能为代价
@property (atomic,assign) int sum1;
// 访问速度快
@property (nonatomic,assign) int sum2;

@end
