//
//  RootViewController.m
//  myNSThread
//
//  Created by leichunxiang on 14-5-20.
//  Copyright (c) 2014年 qianfeng. All rights reserved.
//  主要问题：1、什么是runloop；2、某个实例对象，在runloop中运行模式的修改，由默认修改为common；3、runloop的默认模式（系统模式），在子线程与主线程中运行。
/*
 
 三、NSRunLoop?
 
 1、外部用户触摸事件，会中断（暂时不执行）一切 非外部用户触摸事件的方法@selecter（）（列如：UI的创建与刷新，定时器方法、异步请求方法），如何让app响应外部用户触摸事件的时候，在碎片时间响应其他方法？
 解决：调用 联实例对象与runloop实例对象 相关的方法，模式设为 NSRunLoopCommonModes。列如：NSTimer、NSConnection异步。
 
 2、如何理解runloop？
 运行模式： 有事做事，无事休眠。事是指外部用户触摸事件。
 2.1 每个app有且只有一个runloop实例，是一种高明的用户消息处理机制对象。
 2.2 每个app有且只有一个runloop的while循环：1、循环判断有没有 外部用户触摸事件发生，有则处理外部事件，即调用用户触摸屏幕触发的方法；没有用户事件发生，则处理其他方法。2、退出循环条件：app退出。
 2.2.1 [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode  beforeDate:[NSDate distantFuture]]，runloop调用这个方法：
    1、在子线程中调用：a、此方法每调用一次，都会去判断所在线程有没相关的事情要做，有则执行，即执行时间片交给了子线程。b、每次调用完毕都会离开子线程，回到主线程，执行主线程的方法。即执行时间片交给了主线程。除非设置循环，如例：runloopUser3。
    2、在主线程中调用：a、这是系统默认模式；b、执行时间片在主线程中，先执行主线程的方法。
 2.2.2  [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];runloop调用这个方法：1、修改实例对象的方法在runloop中运行的模式，forMode:NSRunLoopCommonModes表示处理外部用户触摸事件时候，碎片时间处理connection实例在子线程相关的方法。
 2.3 runloop里执行的方法类型有：用户交互事件port方法、显示给用户看方法（创建UI的方法）、performSelector创建子线程中的方法、定时器方法。
 2.4 这个runloop每隔一段很短的时间，去判断主线程有没有任务需要执行，即有没有同步的方法要调用。如果没有，就会等待，间隔一段时间，又去判断有没有任务。

 
 */

/*
 多线程知识扩展
 
 ios 中OC的概念：只有类（类成员变量、类成员方法），
 
 事件：所有的事件，系统都识别为@selecter（），即可执行的ios类的某个方法。
 外部用户事件关联的方法：port的@selecter（） 用户的点击、滑动等手势（系统与用户交互的方式，即可被系统识别的用户动作。）
 内部事件关联的方法：定时器@selecter（）、performSelector、custom自定义@selecter（）
 
 ios系统事件处理
 限制：单核原则，即一个时间只能处理一件事。
 
 
 一、同步与异步 的区别
 同步：
    1、通俗意义：等待上一步的操作（或说任务、事件、函数、方法等）结束，才进行下一步操作。
    2、程序中意义：函数内所有语句执行完成后，才能返回。
 异步：即函数调用者，不需求等待函数执行。
     1、通俗意义：不用 等上一步的操作（或说任务、事件、函数、方法等）完全结束，就进行下一步操作。
     2、程序中意义：即函数内并非所有语句 执行完成后，函数内某些方法先不执行，就返回了。
                  例如：函数中的block，如果是异步提交，函数则先返回，后执行block。

 二、线程、多线程、线程同步
 oc中线程对象：NSThread
 线程：线路，程序。
 线程：程序执行流的最小单元。
    1、线程是进程中的一个实体（即 配置好运行信息的内存）。
    2、一个线程可以创建和撤消另一个线程。
    3、线程也有就绪、阻塞和运行三种基本状态。
    4、每一个程序都至少有一个线程，若程序只有一个线程，那就是程序本身。
 主线程：在主线程中需要执行的方法，提交到main——queue。
 子线程：在子线程中需要执行的方法，提交到globle——queue。默认在主线程没事做的时候，才做的事情。即主线程没有方法需要调用，才会去子线程中调用有需要执行的方法。
 多线程：除了系统的主线程，还开辟了子线程。
 线程同步：前提，多线程情况下，只有一个主线程，不存在这个问题。
     1、多线程要考虑，线程同步：即让一段代码，在同一个时间片里执行，中间没有间断，在c语言层面的GCD有个queue队列（队列的执行是在时间上是连续的）的说法。
     2、多线程中，线程同步作用：防止多个线程资源竞争，抢同一个变量。
     3、考虑线程同步的场景：多线程下，在子线程中创建和调用的方法和变量。
 
 
 为什么开辟 子线程？即用多线程有什么优点？
 解答：避免阻塞主线程。如网络请求下载，为了避免在主线程下载大量数据，而影响主线程中响应外部用户触摸事件，所以会开辟子线程，在子线程中进行网络请求。
 
 使用多线程，优化性能的实质？
 解答：充分利用并发运算产生的等待时间。更好的进行并发程序的编写。
 
 */

#import "RootViewController.h"

#define QQURL @"http://dl_dir.qq.com/qqfile/qq/QQforMac/QQ_V2.4.1.dmg"

@interface RootViewController ()<NSURLConnectionDataDelegate>
{
    NSLock * _lock;//锁
    NSCondition *_condition;// 条件
}
@end

@implementation RootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)createScrollView
{
    UIScrollView * s = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
    s.contentSize = CGSizeMake(320*2, 200);
    s.backgroundColor=[UIColor redColor];
    [self.view addSubview:s];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _lock = [[NSLock alloc] init];
    _condition = [[NSCondition alloc] init];
    

//    [self createScrollView];
    
//    [self createThread1];
    //[self createThread2];
    
    
    [self runloopUser1];
//    [self runloopUser2];
    [self runloopUser3];
    

    
}

#pragma mark - 1、thread创建子线程两种方式。

// 分线程执行是并发无顺序的。
-(void)createThread1
{
    [self performSelectorInBackground:@selector(run:) withObject:@"A"];
    [self performSelectorInBackground:@selector(run:) withObject:@"B"];
    [self performSelectorInBackground:@selector(run:) withObject:@"C"];
    
}

-(void)createThread2
{
    [NSThread detachNewThreadSelector:@selector(runA) toTarget:self withObject:@"D"];
    
    NSThread *thread=[[NSThread alloc] initWithTarget:self selector:@selector(runB) object:@"E"];
    thread.name=@"thread";
    [thread start];//开始线程:需要调用start才能启动，一般用init方法才可以不马上启动方法

}

#pragma mark - 2、NSRunLoop：三个应用场景。
//NSRunLoop特点：
//1、每一个线程都会配备一个NSRunLoop 事件循环 ios特有。
//2、让线程有事做事，无事就休眠,让出CPU时间片。

#pragma mark - 2.1、runLoop应用场景1: scrollview与 定时器方法.

// 视图不滚动时，定时器方法正常执行。

// 滚动视图时：1、如果加RunLoop，停止滚动定时器方法不会被中断调用；2、不加RunLoop，会被中断调用。
-(void)runloopUser1
{
    NSTimer *timer=[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(run) userInfo:nil repeats:YES];
    
    //修改timer在runloop模式下，运行的模式。由默认改为NSRunLoopCommonModes。
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];

}

#pragma mark - 2.2、runLoop应用场景2: scrollview与 异步请求的代理方法 的关系。（环境：主线程中，runloop加到异步请求中）

// 视图不滚动时，异步请求的代理方法 正常执行。

// 滚动视图时：1、如果加RunLoop，异步请求的代理方法 不会被中断调用；2、不加RunLoop，会被中断调用。
-(void)runloopUser2
{
    NSURLRequest *request=[NSURLRequest requestWithURL:[NSURL URLWithString:QQURL]];//下载QQ，文件大才能看得出不同
//    [NSURLConnection connectionWithRequest:request delegate:self];
    NSURLConnection *connection=[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [connection start];
}

#pragma mark - 2.3、runLoop应用场景3: scrollview与 异步请求的代理方法 的关系。（环境：子线程中，runloop不加到异步请求中而是直接加runloop）

/*
 NSRunLoop 是 一种更加高明的消息处理模式，事件循环。
 
 
 */

//开辟子线程
-(void)runloopUser3
{
    [self performSelector:@selector(download) withObject:nil];
}

//子线程异步请求：1、runloop默认在主线程运行，不在子线程，scrollview先被创建；2、runloop设置为在子线程运行，下载完成，跳出循环，scrollview才被创建。
-(void)download
{
      [self createScrollView];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:QQURL]];
    
    [NSURLConnection connectionWithRequest:request delegate:self];
    
    while (!downloadFinish) {
        //NSRunLoop 的设置含义：概括，执行当前方法所在线程的的相关方法一次。此处为异步请求代理方法。
        
//        1、把执行时间片交给了runloop是所在线程：可以理解runloop在哪个线程，哪个线程就是主线程；2、runloop运行模式：跟系统默认的循环间隔判断有没有 用户交互触发事件 一样。不同的是，runloop循环间隔判断的是 子线程中任务有没有完成，没有完成则再进入下一次执行子线程方法的中去。3、每一次循环事件结束，都会把runloop放回到系统默认的主线程。4、每执行一次，都会去判断有没有任务，有任务则执行任务关联的方法。
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode  beforeDate:[NSDate distantFuture]];
    }
    NSLog(@"thead dead...");
}

#pragma mark - NSConnectionDataDelegate
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"length is %d",data.length);
}

bool downloadFinish = NO;
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    downloadFinish = YES;
}

#pragma mark - 事件响应

int timeCount = 0;
- (void)run
{
    NSLog(@"timer=====+++++++++++++++++++++++++=====%d",timeCount++);
}

// 子线程执行
int sum = 10;
int count = 0;
// 多线程同时竞争一个资源时会出错, 通过加锁解决
-(void)run:(NSString *)sender
{
   // NSLog(@"%@",sender);
    while (1) {
        [_lock lock];
        if (sum > 0) {
            [NSThread sleepForTimeInterval:0.5];
            sum--;
            count = 10-sum;
            NSLog(@"余票%d 售出%d",sum,count);
            NSLog(@"%@",sender);
        }else{
            break;
        }
        [_lock unlock];
    }
    NSLog(@"over");
}

-(void)runA
{
    [NSThread sleepForTimeInterval:1.0];
    [_condition lock];
    NSLog(@"A");
    [_condition signal];
    [_condition unlock];
}

-(void)runB
{
    [NSThread sleepForTimeInterval:0.5];
    [_condition lock];
    NSLog(@"B");
    // 等待[_condition signal]调用才会执行
    [_condition wait];
    NSLog(@"%@ do..",[NSThread currentThread].name);
    [_condition unlock];
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
