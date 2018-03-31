//
//  MockNSURLSessionDataTask.swift
//  EventSource
//
//  Created by Andres Canal on 6/21/16.
//  Copyright © 2016 Inaka. All rights reserved.
//

import UIKit

class MockNSURLSessionDataTask: URLSessionDataTask {

	var fakeResponse: HTTPURLResponse?
    var fakeRequest: URLRequest?

	init(response: HTTPURLResponse?, request: URLRequest? = nil) {
		self.fakeResponse = response
        fakeRequest = request
	}

	override var response: HTTPURLResponse? {
		get {
			return self.fakeResponse
		}
	}
    
    override var currentRequest: URLRequest? {
        return fakeRequest
    }
    
    override var originalRequest: URLRequest? {
        return fakeRequest
    }
    
    override func cancel() {
    }
}
