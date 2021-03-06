![EventSource](header.png)

## EventSource
SSE Client written on Swift using NSURLSession.

[![Build Status](https://api.travis-ci.org/yu840915/EventSource.svg)](https://travis-ci.org/yu840915/EventSource) [![codecov.io](https://codecov.io/github/yu840915/EventSource/badge.svg?branch=master)](https://codecov.io/github/yu840915/EventSource?branch=master)

### Abstract

This is an EventSource implementation written on Swift trying to keep the API as similar as possible to the JavaScript one. Written following the [W3C EventSource](http://www.w3.org/TR/eventsource/). If something is missing or not completely right open an issue and I'll work on it!

### How to use it?

It works just like the JavaScript version, the main difference is when creating a new EventSource object you can add headers to the request, for example if your server uses basic auth you can add the headers there.

`Last-Event-Id` is completely handled by the library, so it's sent to the server if the connection drops and library needs to reconnect. Also the `Last-Event-Id` is stored in `NSUserDefaults` so we can keep the last received event for the next time the app is used to avoid receiving duplicate events.

The library automatically reconnects if connection drops. The reconnection time is 3 seconds. This time may be changed by the server sending a `retry: time-in-milliseconds` event.

Also in `sse-server` folder you will find an extremely simple `node.js` server to test the library. To run the server you just need to:

- `npm install`
- `node sse.js`

### Install

You install the library through **Carthage**:

```
github "yu840915/EventSource"

```

Then import the library:

```
import IKEventSource
```

#### Javascript API:

```JavaScript
var eventSource = new EventSource(server);

eventSource.onopen = function() {
    // When opened
}

eventSource.onerror = function() {
    // When errors
}

eventSource.onmessage = function(e) {  
    // Here you get an event without event name!
}

eventSource.addEventListener("ping", function(e) {
  // Here you get an event 'event-name'
}, false);

eventSource.close();
```

#### Swift API:

```swift
var eventSourceRunner = EventSourceSessionRunner()
var eventSource: EventSource = EventSource(url: server, headers: ["Authorization" : basicAuthAuthorization])
eventSourceRunner.run(eventSource)
   
eventSource.onOpen {
  // When opened
}
        
eventSource.onError { (error) in
  // When errors
}

eventSource.onMessage { (id, event, data) in
  // Here you get an event without event name!
}
   
eventSource.addEventListener("event-name") { (id, event, data) in
  // Here you get an event 'event-name'
}

eventSourceRunner.stop(eventSource)
```

We added the following methods that are not available on JavaScript EventSource API but we think they might be useful:

```swift
public func removeEventListener(event: String) -> Void
public func events() -> Array<String>
```

Also the following properties are available: 

- **readyState**: Status of EventSource
  - **EventSourceState.Closed**
  - **EventSourceState.Connecting**
  - **EventSourceState.Open**
- **URL**: EventSource server URL.

#### Examples:
---
**Event**:

```
id: event-id
event: event-name
data: event-data
```

**Calls** 

```
eventSource.addEventListener("event-name") { (id, event, data) in
  // Here you get an event 'event-name'
}
```
---

**Event**:

```
id: event-id
data: event-data
```

```
data: event-data
```

**Calls** 

```
eventSource.onMessage { (id, event, data) in
  // Here you get an event without event name!
}
```
---

**Event**:

```
id: event-id
data: event-data-1
data: event-data-2
data: event-data-3
```

**Calls** 

```
eventSource.onMessage { (id, event, data) in
  // Here you get an event without event name!
  // data: event-data-1\nevent-data-2\nevent-data-3
}
```
---

**Event**:

```
:heartbeat
```

**Calls** 

```
nothing it's a comment
```
---

### Live example

This is the example shipped with the app. If you run the server and run the app you will be able to see this example live. The moving box is just to show that everything works on background and the main thread performance shows no degradation. (The gif is pretty bad to see that, but if you click on the image you will be taken to the gfycat version of the gif which runs way smoother) 

![Sample](sample.gif)

### Contributors
Thanks to all the contributors for pointing out missing stuff or problems and fixing them or opening issues!!

- [hleinone](https://github.com/hleinone)
- [chrux](https://github.com/chrux)
- [danielsht86](https://github.com/danielsht86)
- [Zeeker](https://github.com/Zeeker)
- [col](https://github.com/col)
- [heyzooi](https://github.com/heyzooi)
- [alexpalman](https://github.com/alexpalman)
- [robbiet480](https://github.com/robbiet480)

### Contact Us
If you find any **bugs** or have a **problem** while using this library, please [open an issue](https://github.com/inaka/EventSource/issues/new) in this repo (or a pull request :)).

### About the Forked Version
This fork decouples the event source from the `NSURLSession` APIs. It is now able to work with any HTTP client library by providing object which implements `EventSourceHTTPClientBridging` for bridging the communications between `EventSource` and HTTP client.