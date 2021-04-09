//
//  CZDispatchQueueTests.swift
//
//  Created by Cheng Zhang on 3/24/17.
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import Foundation
import CZDispatchQueue

class CZDispatchQueueTests: NSObject {
    enum TestMode {
        case block, workItem, apple(NSOperationQueue)
        enum NSOperationQueue {
           case block, workItem
        }
    }
    /// label of dispatch queueu
    fileprivate var label = "com.jason.CZDispatchQueueDemo"
    /// Max concurrent blockCount for the queue
    fileprivate let maxConcurrentCount = 3
    /// Sleep interval for task
    fileprivate let sleepInterval = UInt32(1)
    fileprivate let testMode: TestMode = .block
    fileprivate var jobQueue: CZDispatchQueue?

    /// Test Cases
    func test() {
        print("Begining to test .. \nmaxConcurrentCount = \(maxConcurrentCount)\n")

        // Even we trigger 1000 asynchronous tasks in CZDispatchQueue, as we set maxConcurrentCount to 3, there should have 3 concurrent executions at maximum, other tasks will be queued until slots available
        let executionCount = 1000
        switch testMode {
        case .block:
            // Test dispatch queue with execution block
            testCZDispatchQueueBlock(count: executionCount)
        case .workItem:
            // Test dispatch queue with DispatchWorkItem: should have 3 concurrent executions at maximum
            testCZDispatchQueueWorkItem(count: executionCount)
        case .apple(.block):
            testNSDispatchQueueBlock(count: executionCount)
        default:
            break
        }

    }
}

/// MARK: - Private Methods

fileprivate extension CZDispatchQueueTests {

    func testCZDispatchQueueBlock(count: Int) {
        print("\(#function)")
        jobQueue = CZDispatchQueue(label: label, qos: .userInitiated, attributes: [.concurrent], maxConcurrentCount: maxConcurrentCount)
        for i in 0 ..< count {
            jobQueue?.async { [weak self] in
                guard let `self` = self else {
                    assertionFailure("WARNING: `self` was deallocated!")
                    return
                }
                sleep(self.sleepInterval)
                print("Completed task: \(i)")
            }
            print("Submitted task: \(i)")
        }
    }

    func testCZDispatchQueueWorkItem(count: Int) {
        print("\(#function)")

        jobQueue = CZDispatchQueue(label: label, qos: .userInitiated, attributes: [.concurrent], maxConcurrentCount: maxConcurrentCount)
        for i in 0 ..< count {
            let workItem = DispatchWorkItem(block: { [weak self] in
                guard let `self` = self else {
                    assertionFailure("WARNING: `self` was deallocated!")
                    return
                }
                sleep(self.sleepInterval)
                print("Currently working on: \(i)")
            })
            jobQueue?.async(execute: workItem)
        }
    }

    func testNSDispatchQueueBlock(count: Int) {
        print("\(#function)")
        // Test iOS NSOperationQueue
        let jobQueue = DispatchQueue(label: label, qos: .userInitiated, attributes: [.concurrent])
        for i in 0 ..< count {
            jobQueue.async { [weak self] in
                guard let `self` = self else {
                    assertionFailure("WARNING: `self` was deallocated!")
                    return
                }
                sleep(self.sleepInterval)
                print("Completed task: \(i)")
            }
            print("Submitted task: \(i)")
        }
    }
}
