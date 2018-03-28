//
//  EventSourceSessionManager.swift
//  EventSource
//
//  Created by Mike Yu on 26/03/2018.
//  Copyright © 2018 Inaka. All rights reserved.
//

import Foundation

protocol EventSourceHTTPClientBridging: HTTPURLRequestExecutable {
    weak var taskEventDelegate: URLSessionTaskEventDelegate? {get set}
}

public class EventSourceSessionManager: NSObject, URLSessionTaskEventDelegate {
    let httpClientBridge: EventSourceHTTPClientBridging
    var eventSources = Set<EventSource>()
    
    init(httpClientWrapper: EventSourceHTTPClientBridging = URLSessionBridge()) {
        self.httpClientBridge = httpClientWrapper
        super.init()
        httpClientWrapper.taskEventDelegate = self
    }
    
    func add(_ eventSource: EventSource) {
        eventSources.insert(eventSource)
        eventSource.httpURLRequestExecutor = httpClientBridge
        eventSource.connect()
    }
    
    func didReceiveData(_ data: Data, forTask dataTask: URLSessionDataTask) {
        taskEventDelegate(for: dataTask)?.didReceiveData(data, forTask: dataTask)
    }
    
    private func taskEventDelegate(for task: URLSessionTask) -> URLSessionTaskEventDelegate? {
        return eventSources.first{$0.task == task}
    }

    func didCompleteTask(_ task: URLSessionTask, withError error: Error?) {
        taskEventDelegate(for: task)?.didCompleteTask(task, withError: error)
    }
    
    func didReceiveResponse(_ response: URLResponse, forTask dataTask: URLSessionDataTask) {
        taskEventDelegate(for: dataTask)?.didReceiveResponse(response, forTask: dataTask)
    }
}

