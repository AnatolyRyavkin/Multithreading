//
//  ViewController.swift
//  Multithreading
//
//  Created by Anatoly Ryavkin on 22.03.2020.
//  Copyright © 2020 AnatolyRyavkin. All rights reserved.
//

import UIKit
import Foundation


let imageURL1: URL = URL.init(string: /*"https://www.youtube.com/watch?v=Tz8XZ5stG2g&list=PLmTuDg46zmKCKjZqxXqJFjGXwzqGQi4D3&index=12")!*/ "https://aquamarine.online/files/upload_image/3_rp14.jpg")!
let imageURL2: URL = URL.init(string: "https://aquamarine.online/files/upload_image/2_rp15.jpg")!
let imageURL3: URL = URL.init(string: "https://avatars.mds.yandex.net/get-pdb/2510610/a0a72856-daec-4e6c-b562-49d9a67ba18b/s1200")!

let arrayURL  = [imageURL1, imageURL2, imageURL3]


class ViewController: UIViewController {

    var array = [String]()

    enum ErrorMy: Error{
        case unknowe
        case fatal
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //executingMutex()

        //executingRecursiveMutex()

        //executingConditionMutex()

        //executingSynchronized()

        //readWriteBlock()

        //unfairLock()

        //dispatchQueueExample()

        //loadImageView()

        //asyncAfterZZZConcurrentPerform()

        //initiallyInactive()

        //dispatchWorkItemMy()

        //        firstFetchImage()
        //        secondFetchImage()
        //        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(6)) {
        //            self.thirdFetchImage()
        //        }

        //semafore()

        //dispatchGroup()

        //self.loadThreeImage()

        //dispatchBarrier()

        //dispatchSource()

        operation()


    }

    //MARK: Operation&OperationQueue&OperationBlock
    //MARK: CastomCreateOperation(with Notification!!!)

    func operation(){

        let operationQueue = OperationQueue.init()
        print("begin",Thread.current)
        var address: UnsafeMutablePointer<String>!
        var string = "@@@"
        _ = withUnsafeMutablePointer(to: &string) {
            //print("\($0)")
            address = $0
        }

        sleep(1)
        let blockOperation1 = BlockOperation{
            print("b1",Thread.current)
            for i in 0...5{
                print("b1 ------- ",i)
                sleep(UInt32(i))
            }
            print("b1 - END")
        }

        let operation1 = Operation.init()

        operation1.completionBlock = {
            print("o1",Thread.current)
            sleep(3)
            string = "%%%"
            print("o1")
        }

        class OperationMy: Operation{
            var boolCancel = false
            var boolFinish = false
            var address: UnsafeMutablePointer<String>!
            convenience init( _ address: UnsafeMutablePointer<String>){
                self.init()
                self.address = address
            }
            override var isFinished: Bool{
                return boolFinish
            }
            override var isCancelled: Bool{
                return boolCancel
            }
            override func cancel() {
                willChangeValue(forKey: "isFinished")
                willChangeValue(forKey: "isCancelled")
                boolCancel = true
                boolFinish = true
                didChangeValue(forKey: "isFinished")
                didChangeValue(forKey: "isCancelled")
                //super.cancel() -вызывает нотификацию isCancelled
            }
            override func main(){
                if isCancelled{
                    return
                }
                print("main execution", Thread.current)
                for i in 0...5{
                    if isCancelled{
                        return
                    }
                    print("run main - ",i)
                    sleep(UInt32(i))
                }
                if isCancelled{
                    return
                }
                boolFinish = true
            }
            override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
                print("keyPath = ", keyPath!)
                if let operation = object as? OperationMy{
                    let bool = (operation.value(forKey: keyPath!) as! Int) == 1 ? true : false
                    print("operation.\(keyPath!) = ", bool)
                }
            }
        }

        let operationMy = OperationMy(address!)
        operationMy.completionBlock = {
            print("completion!")
        }

        operationMy.addObserver(operationMy, forKeyPath: "isFinished", options: [.new, .old], context: nil)
        operationMy.addObserver(operationMy, forKeyPath: "isCancelled", options: [.new, .old], context: nil)
        operationMy.addObserver(operationMy, forKeyPath: "isReady", options: [.new, .old], context: nil)

        operationQueue.addOperations([operation1], waitUntilFinished: false)
        operationQueue.addBarrierBlock {
            for i in 0...4{
                print(i)
            }
        }
        operationQueue.addOperations([operationMy], waitUntilFinished: false)
        operationQueue.waitUntilAllOperationsAreFinished()
        print("***********************")
        sleep(2)
        print("***********************")
        //operationMy.cancel()
        print("***********************")
        blockOperation1.addDependency(operationMy)
        operationQueue.addOperations([blockOperation1], waitUntilFinished: true)
        sleep(2)
        blockOperation1.cancel()
        sleep(2)
        print("END!!!")
    }

    //MARK: DispatchSource

    let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
    func dispatchSource(){
        print("start")
        timer.setEventHandler {
            print("timer bac!")
        }
        timer.schedule(deadline: .now(), repeating: 1)
        timer.activate()
        sleep(5)
        timer.suspend()
        print("begin sleep")
        sleep(5)
        print("ending sleep")
        timer.resume()
    }


    //MARK: DispatchBarrier

    func dispatchBarrier(){

        func exampleBarrier(){
            let queue = DispatchQueue.init(label: "Q", qos: .background, attributes: [.concurrent])
            print("start")

            queue.async{
                sleep(1)
                print("111")
            }
            queue.async{
                sleep(2)
                print("222")
            }
            queue.async{
                sleep(3)
                print("333")
            }

            queue.async(flags: .barrier) {
                print("4444")
            }
        }

        // SafeArray

        func exampleSafeArray(){

            class SafeArray<T>{
                var array = [T]()

                let queue = DispatchQueue.init(label: "Q")

                func append( _ element: T) -> (){
                    queue.async(flags: .barrier) {
                        self.array.append(element)
                        print("------------writing index = \(self.array.count - 1) -------------",element)
                        }
                }

                func valueAtIndex ( _ index: Int) -> T?{
                    var element: T!
                    if index < array.count {
                        queue.sync(flags: .barrier) {
                            element = self.array[index]
                        }
                    }
                    print("------------reading index = \(index) -------------",element ?? "nil")
                    return element

                }

                func value () -> [T]{
                    var array: [T]!
                        queue.sync(flags: .barrier) {
                            array = self.array
                        }
                    print("------------reading array ------------")
                    return array
                }

            }

            let safeArray = SafeArray<Int>()

            DispatchQueue.concurrentPerform(iterations: 100, execute: {i in
                print(Thread.current)
                safeArray.append(i)
            })
            print(safeArray.value())
            DispatchQueue.concurrentPerform(iterations: 100, execute: {i in
                print(safeArray.valueAtIndex(i) ?? "element at index = \(i) dont exist")
            })
        }

        exampleSafeArray()
    }


    //MARK: UniversalFunctionLoadURL

    func universalFunctionLoadURL(inputURL: URL,
                                  queueLoadURL: DispatchQueue? = DispatchQueue.init(label: "Q", qos: .background, attributes: .concurrent),
                                  queueRunCompletion: DispatchQueue? = DispatchQueue.init(label: "Q1", qos: .background),//, attributes: .concurrent),
                                  completionSuccess: @escaping (Data)  -> Void,
                                  completionError: @escaping (Error) -> Void
    ) throws -> Void {

        queueLoadURL?.async{
            do{
                let data = try Data(contentsOf: inputURL)
                     queueRunCompletion?.sync {
                         completionSuccess(data)
                     }
            }
            catch let error{
                completionError(error)
            }
        }
    }


    //MARK: DispatchGroup

    // DispatchGroup load three image

    func loadThreeImage(){
        var arrayImageView = [UIImageView]()
        var arrayImage = [UIImage]()
        DispatchQueue.main.async {
            let heightImaigeView = self.view.bounds.height/3
            for i in 0...2{
                let imageView = UIImageView.init(frame: CGRect.init(x: 0, y: (heightImaigeView * CGFloat(i)), width: self.view.bounds.width, height: heightImaigeView - 10))
                self.view.addSubview(imageView)
                arrayImageView.append(imageView)
            }
        }

        let dispatchGroup = DispatchGroup.init()

        for i in 0...2{
            dispatchGroup.enter()
            do{
                try universalFunctionLoadURL(inputURL: arrayURL[i],
                                             completionSuccess: { (data) in
                                                guard let image = UIImage.init(data: data) else{
                                                    print("Error Return")
                                                    return
                                                }
                                                arrayImage.append(image)
                                                //sleep(UInt32(i*2))
//                                                DispatchQueue.main.async {
//                                                    arrayImageView[i].image = arrayImage[i] // asyng load
//                                                }
                                                dispatchGroup.leave()
                                             },
                                             completionError: {error in print("Error = ",error)})
            }
            catch let error{
                print("Error catch = ",error)
                
            }
        }

        dispatchGroup.notify(queue: .main) {
            print("END!!!")
            for i in 0...2{
                arrayImageView[i].image = arrayImage[i] //syng load
            }
        }

    }

    //DispatchGroup example

    func dispatchGroup(){


        func dispatchGroupConcurrent(){     //Serial dont work !!!
            let dispatchGroup1 = DispatchGroup.init()
            let queueConcurrent = DispatchQueue.init(label: "Concurrent", attributes: .concurrent)


            dispatchGroup1.enter()
            queueConcurrent.async {
                sleep(1)
                print("1")
                dispatchGroup1.leave()
            }


            dispatchGroup1.enter()
            queueConcurrent.async {
                sleep(3)
                print("2")
                dispatchGroup1.leave()
            }

            dispatchGroup1.wait()  //stoping while dont ending Group

            print("finish")

            dispatchGroup1.notify(queue: .main) {
                print("main finish")
            }

        }

        func dispatchGroupSerial(){     //Serial dont work !!!
            let dispatchGroup1 = DispatchGroup.init()
            let queueSerial = DispatchQueue.init(label: "Serial")

            dispatchGroup1.wait()

            dispatchGroup1.enter()
            queueSerial.sync {
                sleep(3)
                //dispatchGroup1.enter()
                print("1")
                //dispatchGroup1.leave()
            }
            //dispatchGroup1.leave()


            //dispatchGroup1.enter()
            queueSerial.sync {
                sleep(2)
                //dispatchGroup1.enter()
                print("2")
                //dispatchGroup1.leave()
            }
            dispatchGroup1.leave()



            dispatchGroup1.notify(queue: DispatchQueue.main) {
                print("finish")
            }


        }

        //dispatchGroupSerial()
        dispatchGroupConcurrent()


    }


    //MARK: GCD Semafore

    func semafore(){

        //        let semafore = DispatchSemaphore.init(value: 1)
        //        print("begin")

        //        let queue = DispatchQueue.init(label: "Q", qos: .default, attributes: .concurrent)
        //        queue.async {
        //            semafore.wait()
        //            print("-----")
        //            sleep(1)
        //            semafore.signal()
        //        }
        //        queue.async {
        //            semafore.wait()
        //            print("-----")
        //            sleep(1)
        //            semafore.signal()
        //        }
        //        queue.async {
        //            semafore.wait()
        //            print("-----")
        //            sleep(1)
        //            semafore.signal()
        //        }
        //        queue.async {
        //            semafore.wait()
        //            print("-----")
        //            sleep(1)
        //            semafore.signal()
        //        }
        //
        //        sleep(5)

        //        let semaphore1 = DispatchSemaphore(value: 1)
        //
        //        DispatchQueue.concurrentPerform(iterations: 10) { (i) in
        //            if (semaphore1.wait(timeout: DispatchTime.now() + .seconds(10) ) ) == .success{
        //                print("succes i = \(i)")
        //                sleep(1)
        //                semaphore1.signal()
        //            }else{
        //                print("dont succes i = \(i)")
        //            }
        //        }
        //
        let semaphore2 = DispatchSemaphore(value: 1)

        DispatchQueue.concurrentPerform(iterations: 10) { (i) in
            if (semaphore2.wait(wallTimeout: DispatchWallTime.now() + .seconds(1) ) ) == .success{
                print("succes i = \(i)")
                sleep(1)
                semaphore2.signal()
            }else{
                print("dont succes i = \(i)")
            }
        }

    }


    //MARK: three patch loading image

    // first - classic


    func firstFetchImage(){
        print("start")
        let queue = DispatchQueue.init(label: "aaa", qos: .userInteractive)
        queue.sync {       // very important!!!!!!
            if let data = try? Data(contentsOf: imageURL1){
                DispatchQueue.main.async {
                    let image = UIImageView.init(frame: self.view.bounds)
                    image.contentMode = UIView.ContentMode.scaleAspectFill
                    self.view.addSubview(image)
                    image.image = UIImage(data: data)
                    print("end load imade1")
                }
            }
        }

        // as variant :

        //       queue.asyncAfter(deadline: .now() + .seconds(5)) {
        //           self.secondFetchImage()
        //       }

    }

    // second - workItem

    func secondFetchImage(){

        var dataForWorkItem: Data!
        let queue = DispatchQueue.init(label: "Queue", qos: .userInteractive)
        let workItem = DispatchWorkItem.init {
            if let data = try? Data(contentsOf: imageURL2){
                dataForWorkItem = data
            }else{
                print("Error")
            }
        }
        workItem.notify(queue: DispatchQueue.main) {
            let image = UIImageView.init(frame: self.view.bounds)
            image.contentMode = UIView.ContentMode.scaleAspectFill
            self.view.addSubview(image)
            image.image = UIImage(data: dataForWorkItem)
            sleep(3)
            print("end load imade2")
        }
        queue.async(execute: workItem)
    }

    // third - URLSession

    func thirdFetchImage(){
        let task = URLSession.shared.dataTask(with: imageURL3) { (data, response, error) in
            if let imageData = data{
                DispatchQueue.main.async {
                    let image = UIImageView.init(frame: self.view.bounds)
                    image.contentMode = UIView.ContentMode.scaleAspectFill
                    self.view.addSubview(image)
                    image.image = UIImage(data: imageData)
                    print("end load imade3")
                    print(response!)
                }

            }
        }
        task.resume()
    }


    //MARK: DispatchWorkItem

    func dispatchWorkItemMy() {
        let queue = DispatchQueue.init(label: "myQueue", qos: .background, attributes: .concurrent)

        let workItem = DispatchWorkItem.init {
            for i in 1...5{
                print("workItem work - ",i)
                sleep(3)
                print(Thread.current)
            }
        }

        workItem.notify(qos: .userInteractive, flags: .assignCurrentContext, queue: queue) {
            print("workItem finish")
            print(Thread.current)
            sleep(10)
        }

        workItem.perform() // execute at sync !!!

        queue.sync(execute: workItem)

        print("execute past: queue.sync(execute: workItem)")

        queue.sync{
            for i in 1...5{
                print("queue.sync work +++++++++++++ ",i)
                sleep(2)
                print(Thread.current)
            }
        }

        print("execute past: queue.sync")

        queue.async{
            for i in 1...5{
                print("queue.async work ------------------ ",i)
                sleep(2)
                print(Thread.current)
            }
        }

        print("execute past: queue.async")

    }

    //MARK: asyncAfter, concurrentPerform , initiallyInactive

    func initiallyInactive(){
        let inactiveQueue = DispatchQueue(label: "inactiveQueue", attributes: [.initiallyInactive] )
        inactiveQueue.async {
            print("Done!")
            sleep(3)
            print("Done!")
        }
        print("not yet ...")
        inactiveQueue.activate()
        sleep(1)
        print("activity!")
        inactiveQueue.suspend()
        print("pause!")
        sleep(10)
        inactiveQueue.resume()
    }

    func asyncAfterZZZConcurrentPerform(){

        func afterBlock(seconds: Int, queue: DispatchQueue = DispatchQueue.global(), complition: @escaping () -> ()){
            queue.asyncAfter(deadline: .now() + .seconds(seconds)) {
                print("Begin - ", Thread.current)
                complition()
            }
        }
        afterBlock(seconds: 3) {
            print("first - ",Thread.current)
            DispatchQueue.global(qos: .background).sync {
                print("second - ",Thread.current)
                DispatchQueue.concurrentPerform(iterations: 10) {
                    print("i = \($0)     ",Thread.current)
                }
            }
        }
    }



    //MARK: loadImageView

    @objc func actionButton(){

        let queue = DispatchQueue.global(qos: .background)
        queue.async {
            for i in 1...1000000{
                print(i)
            }
        }

        let queue1 = DispatchQueue.init(label: "aaa", qos: .userInitiated, attributes: .concurrent)
        queue1.async {
            let imageURL: URL = URL.init(string: "https://avatars.mds.yandex.net/get-pdb/199965/40d44c67-ec18-4c90-ac0e-ac810058cbae/s1200")!
            if let data = try? Data(contentsOf: imageURL){
                DispatchQueue.main.async {
                    let image = UIImageView.init(frame: CGRect.init(x: 200, y: 300, width: 400, height: 400))
                    image.contentMode = UIView.ContentMode.scaleAspectFill
                    self.view.addSubview(image)
                    image.image = UIImage(data: data)
                }
                print("resume")
            }else{
                print("Error")
            }
        }

    }

    func loadImageView(){
        let button = UIButton.init(frame: CGRect.init(x: 100, y: 100, width: 200, height: 100))
        button.setTitle("Button", for: UIControl.State.normal)
        button.backgroundColor = UIColor.red
        button.addTarget(self, action: #selector(actionButton), for: UIControl.Event.touchUpInside)
        self.view.addSubview(button)
    }


    //MARK: DispatchQueue

    func dispatchQueueExample(){

        let queueConLounch = DispatchQueue.init(label: "queueConLounch", qos: .background, attributes: .concurrent)

        let queueCon = DispatchQueue.init(label: "queueCon", qos: .background, attributes: .concurrent)

        let queueSer = DispatchQueue.init(label: "queueSer", qos: .background)


        queueConLounch.async {
            print("1111 ---- queueConLounch - ",Thread.current)
            queueCon.async {
                print("queueCon.async - Start\n")
                for _ in 1...5{
                    sleep(1)
                    print(Thread.current)
                    print("queueCon.async - 11111111111111111\n")
                }
            }
            queueCon.sync {
                print("queueCon.sync - Start\n")
                for _ in 1...5{
                    sleep(1)
                    print(Thread.current)
                    print("queueCon.sync - 222222222222222222\n")
                }
            }
            print("B")
            sleep(5)
            print("E")
        }


        queueConLounch.async {
            print("External queueConLounch Begin - ",Thread.current)
            queueConLounch.sync {
                print("internal begin")
                sleep(4)
                print("internal end")
            }
            print("External queueConLounch End - ",Thread.current)
        }


        queueConLounch.sync {
            print("3333 ---- queueConLounch - ",Thread.current)
            queueCon.async {
                print("queueCon.sync - Start\n")
                for _ in 1...5{
                    sleep(2)
                    print(Thread.current)
                    print("queueCon.sync - 33333333333333333333\n")
                }
            }
            sleep(5)
            print("3333 ---- queueConLounch END- ",Thread.current)
        }

        print("unwite!!!")


        queueConLounch.sync {
            print("4444 ----- queueConLounch - ",Thread.current)
            queueSer.async {
                print("queueSer.async - Start\n")
                for _ in 1...5{
                    sleep(3)
                    print(Thread.current)
                    print("queueSer.async - 44444444444444444444\n")
                }
            }
            print("4444 ----- queueConLounch - END",Thread.current)
        }


        queueConLounch.sync {
            print("5555 ---- queueConLounch - ",Thread.current)
            queueSer.sync {
                print("queueSer.asyn - Start\n")
                for _ in 1...5{
                    sleep(2)
                    print(Thread.current)
                    print("queueSer.sync - 555555555555555\n")
                }
            }
            print("5555 ---- queueConLounch - END",Thread.current)
        }

    }


    //MARK: UnfairLock

    func unfairLock(){
        var array = [String]()
        var lock = os_unfair_lock_s()
        
        let thread1 = Thread.init {
            for _ in 0...50{
                os_unfair_lock_lock(&lock)
                array.append("---")
                os_unfair_lock_unlock(&lock)
            }
            print(Thread.current)
        }

        let thread2 = Thread.init {

            for _ in 0...50{
                os_unfair_lock_lock(&lock)
                array.append("+++")
                os_unfair_lock_unlock(&lock)
            }
            print(Thread.current)
        }

        //thread1.qualityOfService = .background

        thread2.start()
        thread1.start()
        sleep(2)
        print(array)

    }


    //MARK: ReadWriteBlock

    func readWriteBlock(){
        var lock = pthread_rwlock_t()
        var attribute = pthread_rwlockattr_t()
        pthread_rwlockattr_init(&attribute)
        pthread_rwlock_init(&lock, &attribute)

        var storyProperty = [Int]()

        var storySetGetProperty: [Int] {
            get{
                pthread_rwlock_wrlock(&lock)
                let temp = storyProperty
                pthread_rwlock_unlock(&lock)
                return temp
            }
            set{
                pthread_rwlock_wrlock(&lock)
                storyProperty = newValue
                pthread_rwlock_unlock(&lock)
            }
        }

        let thread1 = Thread.init {
            for i in 0...50000{
                print(storySetGetProperty[i])
            }
            print(Thread.current)
        }

        let thread2 = Thread.init {
            for i in 0...100000{
                storySetGetProperty.append(i)
            }
            print(Thread.current)
        }

        thread2.start()
        sleep(1)
        thread1.start()


    }





    //MARK: SynhronizedObjC

    func executingSynchronized() {

        let lock = NSObject()

        func first(){
            let thread = Thread.init(block:{
                objc_sync_enter(lock)
                print(Thread.current)
                for _ in 1...500{
                    objc_sync_enter(lock)
                    self.array.append("----")
                    objc_sync_exit(lock)
                }
                objc_sync_exit(lock)
            })
            thread.start()

        }

        func second(){
            let thread = Thread.init(block:{
                objc_sync_enter(lock)
                print(Thread.current)
                for _ in 1...500{
                    objc_sync_enter(lock)
                    self.array.append("++++")
                    objc_sync_exit(lock)
                }
                objc_sync_exit(lock)
            })
            thread.start()
        }

        second()
        first()
        sleep(1)
        print(array)

    }






    //MARK: executingMutex()

    func executingConditionMutex() {

        var mutex = pthread_mutex_t()
        pthread_mutex_init(&mutex, nil)

        let lock = NSLock()
        let condition = NSCondition()
        var flag = false

        func first(){
            pthread_mutex_lock(&mutex)
            //lock.lock()
            for _ in 1...5{
                array.append("----")
            }
            condition.signal()
            flag = true
            pthread_mutex_unlock(&mutex)
            //lock.unlock()
        }

        func second(){
            let thread = Thread.init(block:{
                pthread_mutex_lock(&mutex)
                //lock.lock()
                for _ in 1...5{
                    self.array.append("++++")
                    while (!flag){
                        condition.wait()
                        print("!!!")
                    }
                }
                pthread_mutex_unlock(&mutex)
                //lock.unlock()
            })
            thread.start()

        }

        second()
        sleep(1)
        first()
        sleep(1)
        print(array)

    }




    //MARK: execution Recursive Mutex

    func executingRecursiveMutex() {

        var mutex = pthread_mutex_t()
        var attribute = pthread_mutexattr_t()

        pthread_mutexattr_init(&attribute)
        pthread_mutexattr_settype(&attribute, PTHREAD_MUTEX_RECURSIVE)
        pthread_mutex_init(&mutex, &attribute)
        //pthread_mutex_init(&mutex, nil)

        let recursiveLock = NSRecursiveLock()

        func first(){
            //pthread_mutex_lock(&mutex)
            recursiveLock.lock()
            array.append("111")
            //pthread_mutex_unlock(&mutex)
            recursiveLock.unlock()
        }

        func second(){
            //pthread_mutex_lock(&mutex)
            recursiveLock.lock()
            first()
            //pthread_mutex_unlock(&mutex)
            recursiveLock.unlock()
        }

        second()
        print(array)

    }


    //MARK: executingMutex()

    func executingMutex() {

        var array = [String]()
        var mutex = pthread_mutex_t()
        pthread_mutex_init(&mutex, nil)

        let lock = NSLock()

        let thread = Thread{
            for _ in 1...50{
                //pthread_mutex_lock(&mutex)
                lock.lock()
                print("------")
                array.append("------")
                //pthread_mutex_unlock(&mutex)
                lock.unlock()
            }
        }


        thread.qualityOfService = .background
        thread.start()


        //sleep(1)

        let thread1 = Thread{
            for _ in 1...50{
                //pthread_mutex_lock(&mutex)
                lock.lock()
                print("++++++")
                array.append("++++++")
                //pthread_mutex_unlock(&mutex)
                lock.unlock()
            }
        }
        thread1.qualityOfService = .background
        thread1.start()

        sleep(2)
        print(array)

    }
}

