 ![Upload](Images/JPGbanner.gif)

# Apple Family ![License MIT](https://img.shields.io/badge/platform-iOS-677cf4.svg)
![License MIT](https://img.shields.io/badge/license-MIT-blue.svg)
![License MIT](https://img.shields.io/badge/build-passing-brightgreen.svg)

A simple framework that brings Apple devices together - like a family. It will automatically use either bluetooth or wifi to connect multiple Apple devices and share information.

## Demo

 ![Upload](Images/demo.gif)

## Installation

Just drag the Family.swift file to your project, you're good to go!

## Guide

Family uses the Multipeer Connectivity library by Apple, and simplifies the process. The process of making a session is overcomplicated, and their library of UI elements used to host/invite other devices is often slow or does not work at all. So, this library helps fix that with a much simpler session process along with custom UI elements.

**Note:** Currently, this library is at minimum functionality, and can programmatically create instant sessions as seen in the demo above. Many more features, such as  UI elements for an invitation system, more customizability, and more will be added soon.


### Methods and Propties
`init(serviceType: String)` - Specify a name for the signal.
**Limited to one hyphen (-) and 15 characters.**
**Devices can only see each other if they have the same service name.** This means that you can use a static string to allow all devices see each other, or you can also add in password functionality by making the user input a custom service name. If you ever want to change this, just reinitialize the family object.

`init(serviceType: String, deviceName: String)` - Specify a service type, but also use a custom name. This usually defaults to whatever the name of the device is.

`host()` - Begins hosting and advertises its signal to other devices

`join()` - Begins to look for other devices and automatically joins the first one it notices

`autoConnect()` -The fastest, and what you probably want to use. Automatically begins to connect all devices with the same service type to each other. It works by running both host and join on all devices so that they connect as fast as possible.

`disconnect()` - Disconnects the user from the session

`sendData(object: Any)` - Pass in any object to be sent to all other connected devices. It works by converting it to NSData and then sending it. If you want to send multiple objects, the best way would be to use a single container class.

`connectionTimeout, (default: 10)` - The time (in seconds) a device can spend attempting to connect before quitting.

`convert(), Data class extension` - This is a method that can be used to convert data that you have received from another device back into a useful object. It will return as an Any object, but you can cast it into the right class.


### Protocol
You must assign a class to the `FamilyDelegate` and conform to its protocol. There are 2 methods that provide you with useful information.

`receivedData(data: Data)` - This runs whenever data has been broadcasted to all devices. You can use the Data extension method `convert()` in order to cast it back into a specific class. This runs in the background, so **make sure that you use the main thread for any UI changes.**

`deviceConnectionsChanged(connectedDevices: [String])` - Runs whenever a device has connected/disconnected. It gives you an array of the connected device names.

### Example

This example can also be found in the demo Xcode project. 

The initialization, pherhaps in the `viewDidLoad()` method.

```swift
// Create the family instance
let family = Family(serviceType: "family-demo")

// Start connecting all devices
family.autoConnect()
```

Send the text from a text field. Maybe on a button press.

```swift
family.sendData(object: textField.text!)
```

The protocol conformation. Get the data, convert it back to a string, and update our UI.

```swift
func receivedData(data: Data) {
    OperationQueue.main.addOperation {
        let string = data.convert() as? String
        self.textLabel.text = string
    }
}
```

And we just setup a session where people can connect and send texts to each other. It's that simple!

## Coming Soon

This project is currently at minimum functionality. It currently can just connect all users with the same service name, and send data between them. Soon, the following features will be added.

- [x] Host/Join/AutoConnect ability (programmatically)
- [x] Send and convert data to devices
- [ ] UI - Host can invite devices from a list
- [ ] UI - Devices receive an invite with the ability to accept/invite