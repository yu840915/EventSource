//
//  EventSourceSessionRunner.swift
//  EventSource
//
//  Created by Mike Yu on 26/03/2018.
//  Copyright © 2018 Inaka. All rights reserved.
//

import Foundation

public protocol EventSourceHTTPClientBridging: HTTPURLRequestExecutable {
    weak var taskEventDelegate: URLSessionTaskEventDelegate? {get set}
}

public class EventSourceSessionRunner: NSObject, URLSessionTaskEventDelegate {
    let httpClientBridge: EventSourceHTTPClientBridging
    var runningSessions = Set<EventSourceSession>()
    
    public init(httpClientWrapper: EventSourceHTTPClientBridging = URLSessionBridge()) {
        self.httpClientBridge = httpClientWrapper
        super.init()
        httpClientWrapper.taskEventDelegate = self
    }
    
    public func checkAndRun(_ eventSource: EventSourceSession) throws {
        try checkSessionIsClean(eventSource)
        runningSessions.insert(eventSource)
        eventSource.httpURLRequestExecutor = httpClientBridge
        eventSource.connect()
    }
    
    private func checkSessionIsClean(_ eventSource: EventSourceSession) throws {
        let error = NSError(domain: "com.inaka.EventSource", code: -999, userInfo: [NSLocalizedDescriptionKey: "Session isn't clean"])
        guard eventSource.httpURLRequestExecutor == nil, eventSource.readyState == .closed else {
            throw error
        }
    }
    
    public func run(_ eventSource: EventSourceSession) {
        do {
            try checkAndRun(eventSource)
        } catch let error {
            assertionFailure(error.localizedDescription)
        }
    }
    
    public func stop(_ eventSource: EventSourceSession) {
        guard let session = runningSessions.remove(eventSource) else {
            return
        }
        session.close()
        session.httpURLRequestExecutor = nil
    }
    
    public func didReceiveData(_ data: Data, forTask dataTask: URLSessionDataTask) {
        taskEventDelegate(for: dataTask)?.didReceiveData(data, forTask: dataTask)
    }
    
    private func taskEventDelegate(for task: URLSessionTask) -> URLSessionTaskEventDelegate? {
        return runningSessions.first{$0.task == task}
    }

    public func didCompleteTask(_ task: URLSessionTask, withError error: Error?) {
        taskEventDelegate(for: task)?.didCompleteTask(task, withError: error)
    }
    
    public func didReceiveResponse(_ response: URLResponse, forTask dataTask: URLSessionDataTask) {
        taskEventDelegate(for: dataTask)?.didReceiveResponse(response, forTask: dataTask)
    }
}

