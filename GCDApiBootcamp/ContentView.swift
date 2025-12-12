//
//  ContentView.swift
//  GCDApiBootcamp
//
//  Created by DR ANKUR SAH on 02/12/25.
//

import Combine
import SwiftUI

class GCDFunctions: ObservableObject {
    var timerSource: DispatchSourceTimer?
    var customDataSource: DispatchSourceUserDataAdd?
    
    func dispatchWorkItemBootacmp() {
        /*
         DispatchWorkItem is a wrapper around a task (code block) that you want to execute using  Grand Central Dispatch (GCD).
         | Feature                  | Example Use Case                               |
         | ------------------------ | ---------------------------------------------- |
         | Cancel a task            | Search autocomplete → Cancel previous searches |
         | Add completion callbacks | Animation cleanup                              |
         | Execute multiple times   | Retrying tasks                                 |
         | Observe when completed   | Update UI after background work                |
         */
        var item: DispatchWorkItem?
         item = DispatchWorkItem(qos: .userInitiated) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if item?.isCancelled == true {
                    print("Task cancelled")
                } else {
                    print("Executing dispatch work item")
                }
            }
        }
        item?.perform()
        item?.cancel()
        item?.notify(queue: .main, execute: { print("Task completed") })
        print("Checking sync functionality for perform")
        if let item = item {
            DispatchQueue.global().async(execute: item)
        }
    }
    
    func dispatchGroupItem() {
        /*
         DispatchGroup is a synchronization mechanism in Grand Central Dispatch (GCD) that allows you to:

         ✔ Group multiple async tasks together
         ✔ Track when all tasks in the group are complete
         ✔ Execute a completion block after all tasks finish
         ✔ Wait for tasks to finish synchronously (if needed)
         
         * Notify never runs if we miss a single leave.
         * We can use wait() function.

         It’s useful when tasks run parallel but you need a combined result or update UI once all are done.
         */
        
        let group = DispatchGroup()
        
        group.enter()
        DispatchQueue.global().async {
            print("Task 1 completed")
            group.leave()
        }
        
        group.enter()
        let _ = group.wait(timeout: .now() + 4)
        DispatchQueue.global().async {
            print("Task 2 completed")
            group.leave()
            
        }
        group.notify(queue: .main) {
            print("All task done")
        }
    }
    
    func dispatchSemaphores() {
        /*
         DispatchSemaphore is a low-level synchronization primitive in Grand Central Dispatch (GCD). It lets you control access to a resource or coordinate threads by keeping an integer count and using wait()/signal() to decrement/increment that count. It’s powerful, but also easy to misuse — so use it carefully.We use semaphores to control how many threads can access something at the same time.
         
         A semaphore has an internal integer value (initial value you provide).

         wait() tries to decrement the value; if the value is already zero the calling thread blocks until another thread calls signal() which increments the value.

         signal() increments the count and can wake a blocked waiter.

         Think of it as a limited number of “tokens”. A task must take a token to proceed and return it when finished.
         
         Blocking = dangerous on main thread. Never call wait() on the main thread if the awaited task might run on main (deadlock). Prefer non-blocking approaches.
         
                     let semaphore = DispatchSemaphore(value: 0)

                     print("Start on main thread")

                     DispatchQueue.main.async {
                         print("This will never run!")
                         semaphore.signal()
                     }

                     // ❌ Blocking the main thread
                     semaphore.wait()

                     print("UI will freeze before this")

         Deadlocks: easiest way to create them is wait()ing for a task scheduled on the same serial queue or thread.
         */
        
        let maxConcurrent = 0
        let semaphore = DispatchSemaphore(value: maxConcurrent)

        for i in 0...5 {
            DispatchQueue.global().async {
                semaphore.wait() // acquire a token
                // perform the task
                print("Start task \(i)")
                sleep(1) // simulate work
                print("End task \(i)")
                semaphore.signal() // release token
            }
        }
    }
    
    func dispatchBarrier() {
        /*
         DispatchBarrier (exposed in Swift via DispatchQueue’s .barrier flag) is a GCD tool that lets you schedule a barrier block on a concurrent queue so that:

         All blocks submitted before the barrier finish first,

         Then the barrier block runs alone (exclusive), and

         After the barrier finishes, the queue resumes running other pending blocks concurrently.
         
         Key properties — quick summary

         Works only on custom concurrent queues you create with DispatchQueue(label:attributes:.concurrent).
         (It does not provide exclusive semantics on the global concurrent queues.)

         A barrier block waits for previously submitted tasks to finish, runs alone, then allows later tasks to run.

         Use .async(flags: .barrier) for asynchronous exclusive writes; .sync(flags: .barrier) exists but is dangerous if used incorrectly (can deadlock).

         Simpler and more efficient than creating your own locks when you want many concurrent reads and occasional exclusive writes.
         */
        
        let queue = DispatchQueue(label: "com.concurrent", attributes: .concurrent)
        
        queue.async {
            Thread.sleep(forTimeInterval: 1)
            print("1")
        }
        
        queue.async {
            Thread.sleep(forTimeInterval: 2)
            print("2")
        }
        
        queue.async(flags: .barrier) {
            print("barrier")
        }
        
        queue.async {
            print("3")
        }
        
        // Deadlock
        //        let queue = DispatchQueue(label: "com.example.concurrent", attributes: .concurrent)
        //
        //        queue.async {
        //            print("Start outer block (on queue)")
        //
        //              This will deadlock:
        //              sync blocks the calling thread untill the sync task is finished and
        //              barrier wants all its previous submitted task to be finished first
        //            queue.sync(flags: .barrier) {
        //                print("Barrier block")
        //            }
        //
        //            print("End outer block")
        //        }
        //
        //        print("Submitted outer block")
        
    }
    
    func dispatchSource() {
        /*
         DispatchSource is a GCD-based event monitor
         It listens for specific low-level system events and runs a closure when those events occur.
         Type       What it monitors    Example use
         .timer     Time-based events    Repeating tasks, countdown
         .fileSystemObject    File system changes    Monitor file updates (log files)
         .read / .write     File descriptor readable/writable    Socket communication
         .signal     UNIX signals    Graceful shutdown
         .process        Process state changes    Track child process exit
         .dataAdd / .dataOr     Custom data events    Implement custom async events
         
         DispatchSource breaks monitoring into 3 parts:

         1️⃣ Create a source for a specific event
         2️⃣ Set a handler to execute when the event happens
         3️⃣ Activate the source (it starts listening)
         
         */
        //If you don’t store the timer in a strong property, the function ends → the timerSource is released instantly → it never fires.
        let queue = DispatchQueue.global()
        
        timerSource = DispatchSource.makeTimerSource(queue: queue)
        
        timerSource?.schedule(deadline: .now(), repeating: 2)
        
//        timerSource?.setEventHandler {
//            print("Time fired", Date())
//        }
//        timerSource?.resume()
        
        customDataSource = DispatchSource.makeUserDataAddSource(queue: queue)
        
        customDataSource?.setEventHandler {
            print("Received Data: \(self.customDataSource?.data, default: "")")
        }
        
        // .suspend() doesn’t stop accumulation
        customDataSource?.resume()
        customDataSource?.add(data: 15)
        customDataSource?.add(data: 20)
        customDataSource?.suspend()
        customDataSource?.add(data: 10)
        customDataSource?.resume()
        customDataSource?.add(data: 15)
    }
}

struct ContentView: View {
    @StateObject var vm = GCDFunctions()
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            vm.dispatchSource()
        }
    }
}

#Preview {
    ContentView()
}
