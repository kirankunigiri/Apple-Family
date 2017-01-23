//
//  ViewController.swift
//  Family-Mac
//
//  Created by Kiran Kunigiri on 1/21/17.
//  Copyright © 2017 Kiran. All rights reserved.
//

import Cocoa

class MacViewController: NSViewController {

    // Outlets
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var imageButton: NSButton!
    @IBOutlet weak var countLabel: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var statusLabel: NSTextField!
    
    // Properties
    let family = Family.instance
//    let ptManager = PTManager.instance
//    let signal = Signal.instance
    var panel = NSOpenPanel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        family.delegate = self
        family.initialize(portNumber: PORT_NUMBER, serviceType: "family-demo")
        
        // PTManager
//        ptManager.delegate = self
//        ptManager.connect(portNumber: PORT_NUMBER)
//        
//        // Signal
//        signal.initialize(serviceType: SERVICE_TYPE)
//        signal.delegate = self
//        signal.autoConnect()
        
        // File Chooser
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = NSImage.imageTypes()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    @IBAction func addButtonTapped(_ sender: NSButton) {
        if family.isConnected {
            let num = Int(countLabel.stringValue)! + 1
            self.countLabel.stringValue = "\(num)"
            family.sendObject(object: num, type: DataType.number.rawValue)
        }
    }
    
    @IBAction func imageButtonTapped(_ sender: NSButton) {
        if family.isConnected {
            let opened = panel.runModal()
            if opened == NSFileHandlingPanelOKButton {
                let url = panel.url!
                let image = NSImage(byReferencing: url)
                self.imageView.image = image
                
                let data = NSData(contentsOf: url)
                family.sendData(data: data as Data!, type: DataType.image.rawValue)
            }
        }
    }
    
    // MARK: - Data methods
    
//    var isConnected: Bool {
//        return ptManager.isConnected || signal.isConnected
//    }
//    
//    func sendObject(object: Any, type: UInt32) {
//        if ptManager.isConnected {
//            ptManager.sendObject(object: object, type: type)
//        } else if signal.isConnected {
//            signal.sendObject(object: object, type: type)
//        }
//    }
//    
//    func sendData(data: Data, type: UInt32) {
//        if ptManager.isConnected {
//            ptManager.sendData(data: data, type: type)
//        } else if signal.isConnected {
//            signal.sendData(data: data, type: type)
//        }
//    }
//    
//    func didReceiveData(data: Data, type: UInt32) {
//        if type == DataType.number.rawValue {
//            let count = data.convert() as! Int
//            self.countLabel.stringValue = "\(count)"
//        } else if type == DataType.image.rawValue {
//            let image = NSImage(data: data)
//            self.imageView.image = image
//        }
//    }
//    
//    func connectionsUpdated() {
//        var newDeviceList: [String] = []
//        if ptManager.isConnected {
//            newDeviceList.append("Your iDevice")
//        }
//        if signal.isConnected {
//            newDeviceList.append(contentsOf: signal.connectedDeviceNames)
//        }
//        self.statusLabel.stringValue = "Connected to: \(newDeviceList)"
//    }


}


// MARK: - Peertalk
//extension MacViewController: PTManagerDelegate {
//    
//    func peertalk(shouldAcceptDataOfType type: UInt32) -> Bool {
//        return true
//    }
//    
//    func peertalk(didReceiveData data: Data, ofType type: UInt32) {
//        if type == DataType.number.rawValue {
//            let count = data.convert() as! Int
//            self.countLabel.stringValue = "\(count)"
//        } else if type == DataType.image.rawValue {
//            let image = NSImage(data: data)
//            self.imageView.image = image
//        }
//    }
//    
//    func peertalk(didChangeConnection connected: Bool) {
//        // Shut down the signal services when the mac is connected via USB
//        if connected {
//            connectionsUpdated()
//            self.signal.shutDown()
//        } else {
//            self.signal.autoConnect()
//        }
//    }
//    
//}
//
//
//// MARK: - Signal
//extension MacViewController: SignalDelegate {
//    
//    func signal(didReceiveInvitation device: String) {
//        
//    }
//    
//    func signal(didReceiveData data: Data, ofType type: UInt32) {
//        self.didReceiveData(data: data, type: type)
//    }
//    
//    func signal(connectedDevicesChanged devices: [String]) {
//        connectionsUpdated()
//    }
//    
//}



extension MacViewController: FamilyDelegate {
    
    func family(connectedDevicesChanged devices: [String]) {
        self.statusLabel.stringValue = "Connected to: \(devices)"
    }
    
    func family(didReceiveData data: Data, ofType type: UInt32) {
        if type == DataType.number.rawValue {
            let count = data.convert() as! Int
            self.countLabel.stringValue = "\(count)"
        } else if type == DataType.image.rawValue {
            let image = NSImage(data: data)
            self.imageView.image = image
        }
    }
    
}


