//
//  ViewController.swift
//  ProductConsumerModal
//
//  Created by KeSen on 16/1/11.
//  Copyright © 2016年 KeSen. All rights reserved.
//

import UIKit


class ViewController: UIViewController {
    
    var semaphore: dispatch_semaphore_t
    
    required init?(coder aDecoder: NSCoder) {
        self.semaphore = dispatch_semaphore_create(1)
        super.init(coder: aDecoder)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.test_semaphore()
        
//        self.dispatchAfter()
        
        self.dispatchApply()
        
//        self.dispatchGroup()
        
//        self.dispatchGroup_EnterAndLeave_Concurrent()
        
//        self.test_gcdTimer()
        
//        self.test_mutiThread()
//        testFunctionPerformance("test_mutiThread")
    }

    //MARK: ------------------- 使用 GCD 定时器 --------------------
    func test_gcdTimer() {
        
        let mainQueue: dispatch_queue_t = dispatch_get_main_queue();
        
        // 两秒后开始定时器，没秒执行1次，精度为2。
        let startTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, 2)
        let interval: UInt64 = 1
        let leeway: UInt64 = 2 //精度
        
        let timer: dispatch_source_t = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, mainQueue)
        dispatch_source_set_timer(timer, startTime, interval * NSEC_PER_SEC, leeway * NSEC_PER_SEC)
        dispatch_source_set_event_handler(timer) { () -> Void in
            print("Timer event")
        }
        dispatch_resume(timer)
        
        // 10秒后取消定时器
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(6 * NSEC_PER_SEC)), mainQueue) { () -> Void in
            dispatch_source_cancel(timer)
        }
    }
    
    
    //MARK: ------------------- 使用信号量进行加锁操作 --------------------
    func test_semaphore() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            self.tast_first()
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            self.tast_second()
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            self.tast_third()
        }
    }
    
    func tast_first() {
        // p操作，进入临界区
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER)

        print("First tast starting")
        sleep(1)
        NSLog("%@", "First task is done")
        
        // v操作，离开临界区
        dispatch_semaphore_signal(self.semaphore)
    }
    
    func tast_second() {
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER)
        print("Second tast starting")
        sleep(1)
        NSLog("%@", "Second task is done")
        dispatch_semaphore_signal(self.semaphore)
    }
    
    func tast_third() {
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER)
        print("Third tast starting")
        sleep(1)
        NSLog("%@", "Thrid task is done")
        dispatch_semaphore_signal(self.semaphore)
    }
    
    //MARK: ------------------- 多线程测试 --------------------
    // 详细参见：http://www.dreamingwish.com/article/gcd-practice-io-race.html
    func test_mutiThread() {
        let userSerialQueue = dispatch_queue_create("com.test.mutiThread.userSerialQueue", DISPATCH_QUEUE_SERIAL)
        let globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        let group = dispatch_group_create()
        
        // 当 "Processing data"（CUP处理速度） 速度远小于 "Reading file"（磁盘处理速度） 速度时，线程数占用过多
        // 使用信号量来限制同时执行的任务的数量
        
        let cupCount = NSProcessInfo.processInfo().processorCount // CPU 数量
        let jobSemaphore = dispatch_semaphore_create(cupCount * 2) // 限制线程个数
        
        for i:Int in 1...50 {
            
            dispatch_semaphore_wait(jobSemaphore, DISPATCH_TIME_FOREVER);
            
            dispatch_group_async(group, userSerialQueue, { () -> Void in  // 由于磁盘访问无法并发执行且速度较慢，放在串行队列中比较好
                
                print("Reading file", i, NSThread.currentThread())
                //                sleep(2)
                
                dispatch_group_async(group, globalQueue, { () -> Void in
                    print("  Processing data", i, NSThread.currentThread())
                    sleep(1)
                    
                    dispatch_group_async(group, userSerialQueue, { () -> Void in
                        print("    writing file", i, NSThread.currentThread())
                        //                        sleep(2)
                        
                        dispatch_semaphore_signal(jobSemaphore);
                    })
                })
                
            })
        }
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        
    }
    
    //MARK: ------------------- dispatch_after 的使用--------------------
    func dispatchAfter() {
        let delay: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC)))
        dispatch_after(delay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            print("viewDidLoad()")
        }
    }
    
    //MARK: ------------------- 多任务异步执行 与 dispatch_group_notify 的使用 --------------------
    func dispatchGroup() {
        let group: dispatch_group_t = dispatch_group_create()
        
        let globalQueueDefault: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        // 串行队列按照先进先出的顺序执行（FIFO）
        let userQueueSerie: dispatch_queue_t = dispatch_queue_create("com.dispatchGroup.demo", DISPATCH_QUEUE_SERIAL)
        
        // 下载任务1
        dispatch_group_async(group, userQueueSerie){
            sleep(3)
            NSLog("Task1 is done")
        }
        
        // 下载任务2
        dispatch_group_async(group, userQueueSerie){
            sleep(3)
            NSLog("Task2 is done")
        }
        
        // 下载任务3
        dispatch_group_async(group, globalQueueDefault){
            sleep(3)
            NSLog("Task3 is done")
        }
        
        // 监听任务组事件的执行完毕
        dispatch_group_notify(group, dispatch_get_main_queue()){
            
            NSLog("Group tasks are done")
        }
        
        // 设置等待时间(即设置超时)，在等待时间结束后，如果还没有执行完任务组，则返回。返回0代表执行成功，非0则执行失败
        // 等待直到完成
        let result = dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        if (result != 0) {
            print("Now viewDidLoad is done")
        }
    }
    
    //MARK: ------------------- 多任务异步执行/同步执行 与 dispatch_apply 的使用 --------------------
    func dispatchApply() {

        let iterations: Int = 20 // 迭代次数
        let globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        // 同步执行
        self.testPerformance { () -> () in
            dispatch_apply(iterations, globalQueue) { (index: Int) -> Void in
                print(index, NSThread.currentThread())
            }
            NSLog("iterations is over")
        }
        
        print("------------------------------------")
        
        // 异步执行
        self.testPerformance { () -> () in
            dispatch_apply(iterations, globalQueue, { (index: Int) -> Void in
                dispatch_async(globalQueue, { () -> Void in
                    print(index, NSThread.currentThread())
                })
            })
            NSLog("iterations is over")
        }
        
        print("------------------------------------")
        
        self.testPerformance { () -> () in
            for i:Int in 1...iterations {
                print(i, NSThread.currentThread())
            }
        }
        
    }
    
    //MARK: ------------------- dispatch_group_enter / dispatch_group_leave -------------------
    // 将任务组中的任务未执行完毕的任务数目加减1，这种方式不使用 dispatch_group_async 来提交任务，
    // 注意：这两个函数要配合使用，有enter要有leave，这样才能保证功能完整实现。

    // 串行执行三个任务
    func dispatchGroup_EnterAndLeave_Seriel() {
        let group = dispatch_group_create()
        
        for index:UInt32 in 1...3{
            dispatch_group_enter(group)//提交了一个任务，任务数目加1
            
            manualDownLoad(index){
                print("Task \(index) is done")
                
                dispatch_group_leave(group)//完成一个任务，任务数目减1
            }
        }
    }
    
    func manualDownLoad(num: UInt32, block:()->()){
        print("Downloading task ", num)
        sleep(num)
        block()
    }
    
    
    // 并行执行三个任务
    func dispatchGroup_EnterAndLeave_Concurrent() {
        let group = dispatch_group_create()//创建group
        let globalQueueDefault = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0)
        
        for index:UInt32 in 1...3{
            dispatch_group_enter(group)//提交了一个任务，任务数目加1
            
            manualDownLoad(index, queue: globalQueueDefault){
                NSLog("Task\(index) is done")
                
                dispatch_group_leave(group)//完成一个任务，任务数目减1
            }
        }
    }
    
    func manualDownLoad(num: UInt32, queue:dispatch_queue_t, block:()->()){
        dispatch_async(queue){
            NSLog("Downloading task\(num)")
            sleep(num)
            block()
        }
    }
    
    /**
     测试代码执行效率
     */
    func testPerformance(closure: ()->()) {
        let startTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, 0)
        closure()
        let endTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, 0)
        print(endTime - startTime)
    }
    
    func testFunctionPerformance(selector: Selector) {
        let startTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, 0)
        self.performSelector(selector)
        let endTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, 0)
        print(endTime - startTime)
    }

}

