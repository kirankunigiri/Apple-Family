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
    var panel = NSOpenPanel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        family.delegate = self
        family.initialize(portNumber: PORT_NUMBER, serviceType: "family-demo")
        
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
}



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


