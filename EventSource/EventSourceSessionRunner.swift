//
//  EventSourceSessionRunner.swift
//  EventSource
//
//  Created by Mike Yu on 26/03/2018.
//  Copyright © 2018 Inaka. All rights reserved.
//

import Foundation

protocol EventSourceHTTPClientBridging: HTTPURLRequestExecutable {
    weak var taskEventDelegate: URLSessionTaskEventDelegate? {get set}
}

public class EventSourceSessionRunner: NSObject, URLSessionTaskEventDelegate {
    let httpClientBridge: EventSourceHTTPClientBridging
    var sessions = Set<EventSourceSession>()
    
    init(httpClientWrapper: EventSourceHTTPClientBridging = URLSessionBridge()) {
        self.httpClientBridge = httpClientWrapper
        super.init()
        httpClientWrapper.taskEventDelegate = self
    }
    
    func run(_ eventSource: EventSourceSession) throws {
        try checkSessionIsClean(eventSource)
        sessions.insert(eventSource)
        eventSource.httpURLRequestExecutor = httpClientBridge
        eventSource.connect()
    }
    
    private func checkSessionIsClean(_ eventSource: EventSourceSession) throws {
        let error = NSError(domain: "com.inaka.EventSource", code: -999, userInfo: [NSLocalizedDescriptionKey: "Session isn't clean"])
        guard eventSource.httpURLRequestExecutor == nil, eventSource.readyState == .closed else {
            throw error
        }
    }
    
    func forceRun(_ eventSource: EventSourceSession) {
        do {
            try run(eventSource)
        } catch let error {
            assertionFailure(error.localizedDescription)
        }
    }
    
    func didReceiveData(_ data: Data, forTask dataTask: URLSessionDataTask) {
        taskEventDelegate(for: dataTask)?.didReceiveData(data, forTask: dataTask)
    }
    
    private func taskEventDelegate(for task: URLSessionTask) -> URLSessionTaskEventDelegate? {
        return sessions.first{$0.task == task}
    }

    func didCompleteTask(_ task: URLSessionTask, withError error: Error?) {
        taskEventDelegate(for: task)?.didCompleteTask(task, withError: error)
    }
    
    func didReceiveResponse(_ response: URLResponse, forTask dataTask: URLSessionDataTask) {
        taskEventDelegate(for: dataTask)?.didReceiveResponse(response, forTask: dataTask)
    }
}

