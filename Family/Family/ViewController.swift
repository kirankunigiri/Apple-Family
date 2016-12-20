//
//  ViewController.swift
//  Family
//
//  Created by Kiran Kunigiri on 12/16/16.
//  Copyright © 2016 Kiran. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // Outlets
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var devicesLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    // Properties
    let family = Family(serviceType: "family-demo")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textLabel.text = ""
        textField.delegate = self
        textField.returnKeyType = .done
        
        family.delegate = self
    }

    @IBAction func hostButtonPressed(_ sender: UIButton) {
        family.host()
    }
    
    @IBAction func joinButtonPressed(_ sender: UIButton) {
        family.join()
    }
    
    @IBAction func autoButtonPressed(_ sender: UIButton) {
        family.autoConnect()
    }
    
    @IBAction func disconnectButtonPressed(_ sender: UIButton) {
        family.disconnect()
    }

}

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.textLabel.text = textField.text
        if (textField.text != nil && textField.text!.characters.count > 0) {
            family.sendData(object: textField.text!)
        }
        textField.resignFirstResponder()
        return false
    }
}

extension ViewController: FamilyDelegate {
    
    func receivedData(data: Data) {
        OperationQueue.main.addOperation {
            let string = data.convert() as? String
            self.textLabel.text = string
        }
    }
    
    func deviceConnectionsChanged(connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            if (connectedDevices.count > 0) {
                self.devicesLabel.text = "Connected Devices: \(connectedDevices)"
            } else {
                self.devicesLabel.text = "No devices conncted"
            }
        }
    }
    
}
