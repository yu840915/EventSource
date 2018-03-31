//
//  TestableEventSource.swift
//  EventSource
//
//  Created by Andres Canal on 6/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit
@testable import IKEventSource

class TestableEventSource: EventSourceSession {

	func callDidReceiveResponse() {
        didReceiveResponse(URLResponse(), forTask: task!)
	}

	func callDidReceiveDataWithResponse(_ dataTask: URLSessionDataTask) {
        didReceiveData("".data(using: String.Encoding.utf8)!, forTask: dataTask)
	}

	func callDidReceiveData(_ data: Data) {
        didReceiveData(data, forTask: task!)
	}

	func callDidCompleteWithError(_ error: String) {
        didCompleteTask(task!, withError: NSError(domain: "Mock", code: 0, userInfo: ["mock":error]))
	}
    
    override func connect() {
        super.connect()
        readyState = .open
    }
}
