//
//  EventSourceSessionManagerTests.swift
//  EventSourceTests
//
//  Created by Mike Yu on 26/03/2018.
//  Copyright © 2018 Inaka. All rights reserved.
//

import XCTest
@testable import EventSource

class EventSourceSessionManagerTests: XCTestCase {
    
    fileprivate var client: FakeHTTPClient!
    var manager: EventSourceSessionManager!
    
    override func setUp() {
        super.setUp()
        client = FakeHTTPClient()
        manager = EventSourceSessionManager(httpClientWrapper: client)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAddEventSourceToNewManager() {
        let source = EventSource(url: "https://test.cc/sse")
        manager.add(source)
        
        XCTAssertNotNil(source.httpURLRequestExecutor)
        XCTAssertTrue(manager.eventSources.contains(source))
        XCTAssertEqual(client.startingConnectionCounter, 1)
        XCTAssertNotNil(source.task)
        XCTAssertEqual(source.task, client.lastTask)
    }
    
    func testRelayCallbackReceived() {
        let source = CallbackCounterEventSource(url: "https://test.cc/sse")
        
        manager.add(source)
        
        guard let task = client.lastTask else {
            XCTFail("Last task is nil")
            return
        }
        let response = HTTPURLResponse(url: URL(string:"https://test.cc/sse")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        task.fakeResponse = response
        
        XCTAssertEqual(source.readyState, .connecting)
        
        manager.didReceiveResponse(response, forTask: task)
        XCTAssertEqual(source.readyState, .open)
        XCTAssertEqual(source.didReceiveResponseCallbackCounter, 1)
        XCTAssertEqual(source.didReceiveDataCounter, 0)
        XCTAssertEqual(source.didCompleteCallbackCounter, 0)
        
        let eventData = "id: event-id\ndata:event-data\n\n".data(using: String.Encoding.utf8)!
        manager.didReceiveData(eventData, forTask: task)
        XCTAssertEqual(source.didReceiveResponseCallbackCounter, 1)
        XCTAssertEqual(source.didReceiveDataCounter, 1)
        XCTAssertEqual(source.didCompleteCallbackCounter, 0)
        
        manager.didCompleteTask(task, withError: nil)
        XCTAssertEqual(source.readyState, .closed)
        XCTAssertEqual(source.didReceiveResponseCallbackCounter, 1)
        XCTAssertEqual(source.didReceiveDataCounter, 1)
        XCTAssertEqual(source.didCompleteCallbackCounter, 1)
    }
    
    func testMultipleEventCallbackRouting() {
        let source1 = CallbackCounterEventSource(url: "https://test1.cc/sse")
        let source2 = CallbackCounterEventSource(url: "https://test2.cc/sse")
        
        manager.add(source1)
        guard let task1 = client.lastTask else {
            XCTFail("Task 1 is nil")
            return
        }
        manager.add(source2)
        guard let task2 = client.lastTask else {
            XCTFail("Task 2 is nil")
            return
        }
        
        let response1 = HTTPURLResponse(url: URL(string:"https://test1.cc/sse")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        task1.fakeResponse = response1

        let response2 = HTTPURLResponse(url: URL(string:"https://test2.cc/sse")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        task2.fakeResponse = response2
        
        manager.didReceiveResponse(response1, forTask: task1)
        manager.didReceiveResponse(response2, forTask: task2)

        XCTAssertEqual(source1.didReceiveResponseCallbackCounter, 1)
        XCTAssertEqual(source2.didReceiveResponseCallbackCounter, 1)
        
        let eventData = "id: event-id\ndata:event-data\n\n".data(using: String.Encoding.utf8)!
        manager.didReceiveData(eventData, forTask: task1)
        manager.didReceiveData(eventData, forTask: task2)
        
        XCTAssertEqual(source1.didReceiveDataCounter, 1)
        XCTAssertEqual(source2.didReceiveDataCounter, 1)
    }
}

fileprivate class FakeHTTPClient: HTTPClientWrapping {
    weak var taskEventDelegate: URLSessionTaskEventDelegate?
    private(set) var lastTask: MockNSURLSessionDataTask?
    private(set) var startingConnectionCounter = 0
    func execute(_ request: URLRequest) -> URLSessionDataTask? {
        startingConnectionCounter += 1
        let task = MockNSURLSessionDataTask(response: nil, request: request)
        lastTask = task
        return task
    }
}

fileprivate class CallbackCounterEventSource: EventSource {
    private(set) var didReceiveResponseCallbackCounter = 0
    private(set) var didCompleteCallbackCounter = 0
    private(set) var didReceiveDataCounter = 0
    
    override func didReceiveData(_ data: Data, forTask dataTask: URLSessionDataTask) {
        super.didReceiveData(data, forTask: dataTask)
        didReceiveDataCounter += 1
    }
    
    override func didReceiveResponse(_ response: URLResponse, forTask dataTask: URLSessionDataTask) {
        super.didReceiveResponse(response, forTask: dataTask)
        didReceiveResponseCallbackCounter += 1
    }
    
    override func didCompleteTask(_ task: URLSessionTask, withError error: Error?) {
        super.didCompleteTask(task, withError: error)
        didCompleteCallbackCounter += 1
    }
}
