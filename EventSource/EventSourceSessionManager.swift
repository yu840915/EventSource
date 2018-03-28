//
//  EventSourceSessionManager.swift
//  EventSource
//
//  Created by Mike Yu on 26/03/2018.
//  Copyright © 2018 Inaka. All rights reserved.
//

import Foundation

protocol HTTPClientWrapping: HTTPURLRequestExecutable {
    weak var taskEventDelegate: URLSessionTaskEventDelegate? {get set}
}

public class EventSourceSessionManager: NSObject, URLSessionTaskEventDelegate {
    let httpClientWrapper: HTTPClientWrapping
    var eventSources = Set<EventSource>()
    
    init(httpClientWrapper: HTTPClientWrapping = URLSessionBridge()) {
        self.httpClientWrapper = httpClientWrapper
        super.init()
        httpClientWrapper.taskEventDelegate = self
    }
    
    func add(_ eventSource: EventSource) {
        eventSources.insert(eventSource)
        eventSource.httpURLRequestExecutor = httpClientWrapper
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

public class URLSessionBridge: NSObject, HTTPClientWrapping {
    weak var taskEventDelegate: URLSessionTaskEventDelegate?
    var urlSession: Foundation.URLSession!
    private var operationQueue = OperationQueue()
    private var delegateRelay: URLSessionTaskDelegateRelay!
    
    public override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = TimeInterval(INT_MAX)
        let relay = URLSessionTaskDelegateRelay()
        relay.delgate = self
        urlSession = Foundation.URLSession(configuration: configuration, delegate: relay, delegateQueue: operationQueue)
        delegateRelay = relay
    }
    
    func execute(_ request: URLRequest) -> URLSessionDataTask? {
        let task = urlSession.dataTask(with: request)
        task.resume()
        return task
    }
}

extension URLSessionBridge: URLSessionTaskEventDelegate {
    func didReceiveData(_ data: Data, forTask dataTask: URLSessionDataTask) {
        taskEventDelegate?.didReceiveData(data, forTask: dataTask)
    }
    
    func didCompleteTask(_ task: URLSessionTask, withError error: Error?) {
        taskEventDelegate?.didCompleteTask(task, withError: error)
    }
    
    func didReceiveResponse(_ response: URLResponse, forTask dataTask: URLSessionDataTask) {
        taskEventDelegate?.didReceiveResponse(response, forTask: dataTask)
    }
}

extension URLSessionBridge {
    public class URLSessionTaskDelegateRelay: NSObject, URLSessionDataDelegate {
        weak var delgate: URLSessionTaskEventDelegate?
        
        public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            delgate?.didReceiveData(data, forTask: dataTask)
        }
        
        public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            completionHandler(URLSession.ResponseDisposition.allow)
            delgate?.didReceiveResponse(response, forTask: dataTask)
        }
        
        public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            delgate?.didCompleteTask(task, withError: error)
        }
    }
}
