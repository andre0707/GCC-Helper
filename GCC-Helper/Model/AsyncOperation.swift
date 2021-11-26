//
//  AsyncOperation.swift
//  GCC-Helper
//
//  Created by Andre Albach on 25.11.21.
//

import Foundation

/// An operation that runs asynchronous
class AsyncOperation: Operation {
    
    /// The available state cases
    enum State: String {
        case ready
        case executing
        case finished
        
        var keyPath: String { "is\(rawValue.capitalized)" }
    }
    
    /// The queue on which the changes of state will happen, so it is thread safe
    private let stateQueue = DispatchQueue(label: "state", attributes: .concurrent)
    
    /// The current state of the operation
    private var _state = State.ready
    
    /// Computed property to access the current state thread safe
    public var state: State {
        get {
            stateQueue.sync {
                return _state
            }
        }
        set {
            let oldValue = state
            willChangeValue(forKey: state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
            stateQueue.sync(flags: .barrier) {
                _state = newValue
            }
            didChangeValue(forKey: state.keyPath)
            didChangeValue(forKey: oldValue.keyPath)
        }
    }
    
    /// Indicator if the operation is finished
    override var isFinished: Bool { state == .finished }
    /// Indicator if the operation is executing
    override var isExecuting: Bool { state == .executing }
    /// Indicator if this is an asynchronous operation
    override var isAsynchronous: Bool { true }
    /// Indicator if this operation actually completed or was cancelled instead
    private(set) var wasCancelled: Bool = false
    
    /// Called when the operation should be started
    override func start() {
        if isCancelled {
            wasCancelled = true
            state = .finished
            return
        }
        state = .executing
        main()
    }
    
    /// Call this function to cancel the operation
    override func cancel() {
        wasCancelled = true
        state = .finished
    }
}
