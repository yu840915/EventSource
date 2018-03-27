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
    
    var manager: EventSourceSessionManager!
    override func setUp() {
        super.setUp()
        manager = EventSourceSessionManager()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAddEventSourceToNewManager() {
        let source = EventSource(url: "https://test.cc/sse")
        manager.add(source)
        
        XCTAssertNotNil(source.httpURLRequestExecutor)
        XCTAssertTrue(manager.eventSources.contains(source))
    }
    
    func testAddEventStartConnection() {
        let client = FakeHTTPClient()
        let manager = EventSourceSessionManager(httpClientWrapper: client)
        let source = EventSource(url: "https://test.cc/sse")
        
        manager.add(source)
        
        XCTAssertEqual(client.startingConnectionCounter, 1)
    }
    
    
    
}

fileprivate class FakeHTTPClient: HTTPClientWrapping {
    weak var taskEventDelegate: URLSessionTaskEventDelegate?
    private(set) var startingConnectionCounter = 0
    func execute(_ request: URLRequest) -> URLSessionDataTask? {
        startingConnectionCounter += 1
        return nil
    }
}
