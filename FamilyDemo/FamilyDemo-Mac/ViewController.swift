//
//  ViewController.swift
//  FamilyDemo-Mac
//
//  Created by Kiran Kunigiri on 12/22/16.
//  Copyright © 2016 Kiran. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    // MARK: IBOutlets
    @IBOutlet weak var textLabel: NSTextField!
    @IBOutlet weak var deviceLabel: NSTextField!
    @IBOutlet weak var textField: NSTextField!
    
    // MARK: Properties
    let family = Family(serviceType: "family-demo")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        family.delegate = self
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func textFieldAction(_ sender: NSTextField) {
        self.textLabel.stringValue = sender.stringValue
        if (textField.stringValue.characters.count > 0) {
            family.sendData(object: textField.stringValue)
        }
    }
    
    @IBAction func connect(_ sender: NSButton) {
        family.autoConnect()
    }
    
    @IBAction func stopSearching(_ sender: NSButton) {
        family.stopSearching()
    }
    
    @IBAction func disconnect(_ sender: NSButton) {
        family.disconnect()
    }
    
    @IBAction func shutDown(_ sender: NSButton) {
        family.shutDown()
    }

}



extension ViewController: FamilyDelegate {
    
    func receivedData(data: Data) {
        OperationQueue.main.addOperation {
            let string = data.convert() as! String
            self.textLabel.stringValue = string
        }
    }
    
    func receivedInvitation(device: String) {
        
    }
    
    func deviceConnectionsChanged(connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            if (connectedDevices.count > 0) {
                self.deviceLabel.stringValue = "Connected Devices: \(connectedDevices)"
            } else {
                self.deviceLabel.stringValue = "No devices conncted"
            }
        }
    }
}
