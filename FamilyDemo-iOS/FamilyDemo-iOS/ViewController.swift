//
//  ViewController.swift
//  Family
//
//  Created by Kiran Kunigiri on 12/16/16.
//  Copyright © 2016 Kiran. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: Outlets
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var devicesLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    // MARK: Properties
    let family = Family(serviceType: "family-demo")
    
    // MARK: Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textLabel.text = ""
        textField.delegate = self
        textField.returnKeyType = .done
        
        family.delegate = self
    }

    // MARK: Methods
    @IBAction func autoConnect(_ sender: UIButton) {
        family.autoConnect()
    }
    
    @IBAction func inviteAuto(_ sender: UIButton) {
        family.inviteAuto()
    }
    
    @IBAction func inviteUI(_ sender: UIButton) {
        let vc = family.inviteUI()
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func acceptAuto(_ sender: UIButton) {
        family.acceptAuto()
    }
    
    @IBAction func acceptUI(_ sender: UIButton) {
        family.acceptUI()
    }
    
    @IBAction func stopSearching(_ sender: UIButton) {
        family.stopSearching()
    }
    
    @IBAction func disconnect(_ sender: UIButton) {
        family.disconnect()
    }
    
    @IBAction func shutDown(_ sender: UIButton) {
        family.shutDown()
    }

}



// MARK: - Text field delegate
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



// MARK: - Family delegate
extension ViewController: FamilyDelegate {
    
    func receivedData(data: Data) {
        OperationQueue.main.addOperation {
            let string = data.convert() as? String
            self.textLabel.text = string
        }
    }
    
    func receivedInvitation(device: String, alert: UIAlertController?) {
        if (family.acceptMode == .UI) {
            self.present(alert!, animated: true, completion: nil)
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
