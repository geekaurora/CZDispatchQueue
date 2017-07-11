//
//  CZDispatchQueue.swift
//
//  Copyright © 2017 Cheng Zhang. All rights reserved.
//

import Foundation

/**
 *  Facade class encapsulating DispatchQueue: Limit the number of concurrently executing blocks in a dispatch queue, similar as maxConcurrentOperationCount on NSOperationQueue.
 *
 *  - Utilize DispatchSemaphore to fulfill the control of max concurrent executions
 *  - gateKeeperQueue   : Background serialQueue to avoid block invoker's current thread when `async` block waiting for smaphoreSignal. All pending tasks are appended to this
 *                        serial queue when reaches maxConcurrentCount.
 *  - jobQueue          : Actual working queue, queueType(Serial/Concurrent) is based on the input param of `CZDispatchQueue` initializer
 *
 *  WARNING:
 *  DispatchQueue and its invoker SHOULD BE RETAINED, to avoid queue being deallocated. (Workaround: remove [weak self] in CZDispatchQueue)
 */
open class CZDispatchQueue: NSObject {
    /// Serial queue acting as gate keeper, to ensure only one thread is blocked
    fileprivate let gateKeeperQueue: DispatchQueue
    /// Actual concurrent working queue
    fileprivate let jobQueue: DispatchQueue
    /// Max concurrent execution count
    fileprivate var maxConcurrentCount: Int
    /// Semahore to limit the max concurrent executions in dispatch queue
    fileprivate let semaphore: DispatchSemaphore

    /// Configuration constants
    fileprivate struct Config {
        static let defaultmaxConcurrentCount = 3
    }
    fileprivate enum QueueLabel: String {
        case gateKeeper, job
        func prefix(_ label: String) -> String {
            return label + "." + self.rawValue
        }
    }

    /// MARK: - Initializer

    public init(label: String,
                qos: DispatchQoS = .default,
                attributes: DispatchQueue.Attributes = [],
                autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit,
                target: DispatchQueue? = nil,
                maxConcurrentCount: Int) {
        /// Max concurrent block count
        self.maxConcurrentCount = maxConcurrentCount
        /// Initialize semaphore
        semaphore = DispatchSemaphore(value: maxConcurrentCount)

        /// Serial queue acting as gate keeper, to ensure only one thread is blocked
        gateKeeperQueue = DispatchQueue(label: QueueLabel.gateKeeper.prefix(label),
                                        qos: qos,
                                        attributes: [],
                                        autoreleaseFrequency: autoreleaseFrequency,
                                        target: target)

        /// Actual concurrent working queue
        jobQueue = DispatchQueue(label: QueueLabel.job.prefix(label),
                                 qos: qos,
                                 attributes: attributes,
                                 autoreleaseFrequency: autoreleaseFrequency,
                                 target: target)
        super.init()
    }

    /// MARK: - Sync/Async methods

    /// Asynchronization: block
    public func async(group: DispatchGroup? = nil,
        qos: DispatchQoS = .default,
        flags: DispatchWorkItemFlags = .inheritQoS,
        execute work: @escaping @convention(block) () -> Void) {
        /// Serial queue acting as gate keeper, to ensure only one thread is blocked. Otherwise all threads waiting in jobQueue are blocked.
        gateKeeperQueue.async { [weak self] in
            guard let `self` = self else {return}
            // Wait out of ThreadPool, to avoid overload system shared ThreadPool
            self.semaphore.wait()

            self.jobQueue.async { [weak self] in
                guard let `self` = self else {return}
                work()
                self.semaphore.signal()
            }
        }
    }

    /// Asynchronization: DispatchWorkItem
    public func async(execute workItem: DispatchWorkItem) {
        /// Serial queue acting as gate keeper, to ensure only one thread is blocked. Otherwise all threads waiting in jobQueue are blocked.
        gateKeeperQueue.async {[weak self] in
            guard let `self` = self else {return}
            self.semaphore.wait()
            
            /// Actual concurrent working queue
            self.jobQueue.async {[weak self] in
                guard let `self` = self else {return}
                workItem.perform()
                self.semaphore.signal()
            }
        }
    }

    /// Synchronization: block
    public func sync(execute work: () -> Void) {
        jobQueue.sync(execute: work)
    }

    /// Synchronization: DispatchWorkItem
    public func sync(execute workItem: DispatchWorkItem) {
        jobQueue.sync(execute: workItem)
    }
}
