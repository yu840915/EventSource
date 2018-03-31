//
//  URLSessionBridge.swift
//  EventSource
//
//  Created by Mike Yu on 28/03/2018.
//  Copyright © 2018 Inaka. All rights reserved.
//

import Foundation

final public class URLSessionBridge: NSObject, EventSourceHTTPClientBridging {
    public weak var taskEventDelegate: URLSessionTaskEventDelegate?
    var urlSession: Foundation.URLSession!
    private var operationQueue = OperationQueue()
    private var delegateRelay: URLSessionTaskDelegateRelay!
    
    public override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = TimeInterval(INT_MAX)
        let relay = URLSessionTaskDelegateRelay()
        urlSession = Foundation.URLSession(configuration: configuration, delegate: relay, delegateQueue: operationQueue)
        delegateRelay = relay
        relay.delgate = self
    }
    
    public func execute(_ request: URLRequest) -> URLSessionDataTask? {
        let task = urlSession.dataTask(with: request)
        task.resume()
        return task
    }
    
    deinit {
        urlSession.invalidateAndCancel()
    }
}

extension URLSessionBridge: URLSessionTaskEventDelegate {
    public func didReceiveData(_ data: Data, forTask dataTask: URLSessionDataTask) {
        taskEventDelegate?.didReceiveData(data, forTask: dataTask)
    }
    
    public func didCompleteTask(_ task: URLSessionTask, withError error: Error?) {
        taskEventDelegate?.didCompleteTask(task, withError: error)
    }
    
    public func didReceiveResponse(_ response: URLResponse, forTask dataTask: URLSessionDataTask) {
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
