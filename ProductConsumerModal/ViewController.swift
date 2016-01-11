//
//  ViewController.swift
//  ProductConsumerModal
//
//  Created by KeSen on 16/1/11.
//  Copyright © 2016年 KeSen. All rights reserved.
//

import UIKit


class ViewController: UIViewController {
    
    var semaphore: dispatch_semaphore_t;
    
    required init?(coder aDecoder: NSCoder) {
        self.semaphore = dispatch_semaphore_create(1)
        super.init(coder: aDecoder)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. semaphore
//        self.test_semaphore()
        
        // 2. dispatch_after
//        self.dispatchAfter()
        
        // 3. dispatch_apply————相当于异步的for循环，值不过所有循环都是异步执行的
//        self.dispatchApply()
        
        // 4. dispatch_group
//        self.dispatchGroup()
        
        // 5. dispatch_group_enter/dispatch_group_leave
        self.dispatchGroup_EnterAndLeave_Concurrent()
    }
    
    // -------------------使用队列组模拟三个下载任务--------------------
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
        
        // 设置等待时间，在等待时间结束后，如果还没有执行完任务组，则返回。返回0代表执行成功，非0则执行失败
        // 等待直到完成
        let result = dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        if (result != 0) {
            print("Now viewDidLoad is done")
        }
    }

    // -------------------dispatch_apply 的使用--------------------
    func dispatchApply() {

        self.testPerformance { () -> () in
            dispatch_apply(50, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { (index: Int) -> Void in
                print(index)
                print(NSThread.currentThread())
            }
            NSLog("Dispatch_after is over")
        }
        
        self.testPerformance { () -> () in
            for i:Int in 1...50 {
                print(i)
                print(NSThread.currentThread())
            }
        }
        
    }
    
    // -------------------dispatch_after 的使用--------------------
    func dispatchAfter() {
        let delay: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC)))
        dispatch_after(delay, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            print("viewDidLoad()")
        }
    }
    
    // -------------------使用信号量进行加锁操作--------------------
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
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER)
        print("First tast starting")
        sleep(1)
        NSLog("%@", "First task is done")
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
    
    
    // ------------------- dispatch_group_enter / dispatch_group_leave -------------------
    // 将任务组中的任务未执行完毕的任务数目加减1，这种方式不使用 dispatch_group_async 来提交任务，注意：这两个函数要配合使用，有enter要有leave，这样才能保证功能完整实现。

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

}

