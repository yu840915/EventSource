//
//  EventSourceSessionRunnerTests.swift
//  EventSourceTests
//
//  Created by Mike Yu on 26/03/2018.
//  Copyright © 2018 Inaka. All rights reserved.
//

import XCTest
@testable import EventSource

class EventSourceSessionRunnerTests: XCTestCase {
    
    fileprivate var client: FakeHTTPClient!
    var runner: EventSourceSessionRunner!
    
    override func setUp() {
        super.setUp()
        client = FakeHTTPClient()
        runner = EventSourceSessionRunner(httpClientWrapper: client)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAddEventSourceToNewManager() {
        let source = EventSourceSession(url: "https://test.cc/sse")
        runner.add(source)
        
        XCTAssertNotNil(source.httpURLRequestExecutor)
        XCTAssertTrue(runner.eventSources.contains(source))
        XCTAssertEqual(client.startingConnectionCounter, 1)
        XCTAssertNotNil(source.task)
        XCTAssertEqual(source.task, client.lastTask)
    }
    
    func testRelayCallbackReceived() {
        let source = CallbackCounterEventSource(url: "https://test.cc/sse")
        
        runner.add(source)
        
        guard let task = client.lastTask else {
            XCTFail("Last task is nil")
            return
        }
        let response = HTTPURLResponse(url: URL(string:"https://test.cc/sse")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        task.fakeResponse = response
        
        XCTAssertEqual(source.readyState, .connecting)
        
        runner.didReceiveResponse(response, forTask: task)
        XCTAssertEqual(source.readyState, .open)
        XCTAssertEqual(source.didReceiveResponseCallbackCounter, 1)
        XCTAssertEqual(source.didReceiveDataCounter, 0)
        XCTAssertEqual(source.didCompleteCallbackCounter, 0)
        
        let eventData = "id: event-id\ndata:event-data\n\n".data(using: String.Encoding.utf8)!
        runner.didReceiveData(eventData, forTask: task)
        XCTAssertEqual(source.didReceiveResponseCallbackCounter, 1)
        XCTAssertEqual(source.didReceiveDataCounter, 1)
        XCTAssertEqual(source.didCompleteCallbackCounter, 0)
        
        runner.didCompleteTask(task, withError: nil)
        XCTAssertEqual(source.readyState, .closed)
        XCTAssertEqual(source.didReceiveResponseCallbackCounter, 1)
        XCTAssertEqual(source.didReceiveDataCounter, 1)
        XCTAssertEqual(source.didCompleteCallbackCounter, 1)
    }
    
    func testMultipleEventCallbackRouting() {
        let source1 = CallbackCounterEventSource(url: "https://test1.cc/sse")
        let source2 = CallbackCounterEventSource(url: "https://test2.cc/sse")
        
        runner.add(source1)
        guard let task1 = client.lastTask else {
            XCTFail("Task 1 is nil")
            return
        }
        runner.add(source2)
        guard let task2 = client.lastTask else {
            XCTFail("Task 2 is nil")
            return
        }
        
        let response1 = HTTPURLResponse(url: URL(string:"https://test1.cc/sse")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        task1.fakeResponse = response1

        let response2 = HTTPURLResponse(url: URL(string:"https://test2.cc/sse")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
        task2.fakeResponse = response2
        
        runner.didReceiveResponse(response1, forTask: task1)
        runner.didReceiveResponse(response2, forTask: task2)

        XCTAssertEqual(source1.didReceiveResponseCallbackCounter, 1)
        XCTAssertEqual(source2.didReceiveResponseCallbackCounter, 1)
        
        let eventData = "id: event-id\ndata:event-data\n\n".data(using: String.Encoding.utf8)!
        runner.didReceiveData(eventData, forTask: task1)
        runner.didReceiveData(eventData, forTask: task2)
        
        XCTAssertEqual(source1.didReceiveDataCounter, 1)
        XCTAssertEqual(source2.didReceiveDataCounter, 1)
    }
    
    func testNoMemoryLeak() {
        var bridge: URLSessionBridge? = URLSessionBridge()
        weak var bridgeRef: URLSessionBridge? = bridge
        var runner: EventSourceSessionRunner? = EventSourceSessionRunner(httpClientWrapper: bridge!)
        weak var runnerRef: EventSourceSessionRunner? = runner
        var session1: EventSourceSession? = EventSourceSession(url: "https://push.wards.io/sse")
        weak var session1Ref: EventSourceSession? = session1
        var session2: EventSourceSession? = EventSourceSession(url: "https://push.wards.io/sse")
        weak var session2Ref: EventSourceSession? = session2
        
        runner!.add(session1!)
        runner!.add(session2!)
        
        bridge = nil
        session1 = nil
        session2 = nil
        
        XCTAssertNotNil(bridgeRef)
        XCTAssertNotNil(runnerRef)
        XCTAssertNotNil(session1Ref)
        XCTAssertNotNil(session2Ref)

        runner = nil
        
        XCTAssertNil(bridgeRef)
        XCTAssertNil(runnerRef)
        XCTAssertNil(session1Ref)
        XCTAssertNil(session2Ref)
    }
}

fileprivate class FakeHTTPClient: EventSourceHTTPClientBridging {
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

fileprivate class CallbackCounterEventSource: EventSourceSession {
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
