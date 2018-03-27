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
        
        XCTAssertNotNil(source.httpClientCommunicator)
        XCTAssertTrue(manager.eventSources.contains(source))
    }
    
    func testAddEventStartConnection() {
        let fakeManager = FakeConnectionManager()
        let source = EventSource(url: "https://test.cc/sse")
        
        fakeManager.add(source)
        
        XCTAssertEqual(fakeManager.startingConnectionCounter, 1)
    }
    
}

fileprivate class FakeConnectionManager: EventSourceSessionManager {
    private(set) var startingConnectionCounter = 0
    override func connect(withRequest request: URLRequest) -> URLSessionDataTask? {
        startingConnectionCounter += 1
        return nil
    }
}
