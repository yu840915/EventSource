//
//  EventSourceSessionManager.swift
//  EventSource
//
//  Created by Mike Yu on 26/03/2018.
//  Copyright © 2018 Inaka. All rights reserved.
//

import Foundation

public class EventSourceSessionManager: NSObject, URLSessionDataDelegate {
    private var operationQueue = OperationQueue()
    var urlSession: Foundation.URLSession!
    var eventSources = Set<EventSource>()
    func add(_ eventSource: EventSource) {
        eventSources.insert(eventSource)
        eventSource.httpClientCommunicator = self
        eventSource.connect()
    }
    
    func connect(withRequest request: URLRequest) -> URLSessionDataTask? {
        let task = urlSession.dataTask(with: request)
        task.resume()
        return task
    }
    
    public override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = TimeInterval(INT_MAX)
        urlSession = newSession(configuration)
    }
    
    internal func newSession(_ configuration: URLSessionConfiguration) -> Foundation.URLSession {
        return Foundation.URLSession(configuration: configuration,
                                     delegate: self,
                                     delegateQueue: operationQueue)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        eventSources.forEach{$0.didReceiveData(data, forTask: dataTask)}
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(URLSession.ResponseDisposition.allow)
        eventSources.forEach{$0.didReceiveResponse(response, forTask: dataTask)}
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        eventSources.forEach{$0.didCompleteTask(task, withError: error)}
    }
}
