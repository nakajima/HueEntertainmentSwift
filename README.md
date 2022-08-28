# HueEntertainmentSwift

A way to talk to the [Hue Entertainment](https://developers.meethue.com/develop/hue-entertainment/) API.

Sort of (very) in flux at the moment.

## Usage

```swift
// Get a session
let session = HueSession()

// Find the IP of the bridge
try await session.findIP()

// Get a username, clientKey and appID to be used to create a streaming session.
// You'll want to save these values.
try await session.login(device: "YOURAPP#HERE")

// Load Entertainment Areas configured in the Hue app
let areas = try await session.areas()

// Get an area to stream to
guard let area = areas.first else {	return }

// Start a streaming session for the area. This prevents other integrations
// from streaming as well.
try await session.start(area: area)

// Connect via DTLS to the bridge to enable UDP message streaming. Once called,
// you can send messages via `session.connection`
try session.connect()

// Turn on lights in the entertainment area. They'll get set randomly to the
// colors below. The `ramp` value determines how long it takes in seconds
session.on(colors: [Color.red, Color.green, Color.blue, Color.yellow], ramp: 2)

// Turn off lights in the entertainment area.
session.off()

// Stop the streaming session. Important to call this when you're done.
try await session.stop()
```

[Basic usage](https://github.com/nakajima/HueEntertainmentSwift/blob/main/Tests/HueEntertainmentAPITests/HueEntertainmentAPITests.swift) can be found in Tests/ as the `testExample`.

#### Warning

Using this project may potentially trigger seizures for people with photosensitive epilepsy. Use caution if you are going to run the example
