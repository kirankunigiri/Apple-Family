//
//  ViewController.swift
//  Family-iOS
//
//  Created by Kiran Kunigiri on 1/21/17.
//  Copyright © 2017 Kiran. All rights reserved.
//

import UIKit

class MobileViewController: UIViewController {
    
    // Outlets
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    
    // Properties
    let family = Family.instance
//    let ptManager = PTManager.instance
//    let signal = Signal.instance
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        family.delegate = self
        family.initialize(portNumber: PORT_NUMBER, serviceType: "family-demo")
        
//        // PTManager
//        ptManager.delegate = self
//        ptManager.connect(portNumber: PORT_NUMBER)
//        
//        // Signal
//        signal.initialize(serviceType: SERVICE_TYPE)
//        signal.delegate = self
//        signal.autoConnect()
        
        // Image picker
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
    }

    @IBAction func addButtonTapped(_ sender: UIButton) {
        if family.isConnected {
            let num = Int(countLabel.text!)! + 1
            self.countLabel.text = "\(num)"
            family.sendObject(object: num, type: DataType.number.rawValue)
        } else {
            showAlert()
        }
    }
    
    @IBAction func imageButtonTapped(_ sender: UIButton) {
        if family.isConnected {
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            showAlert()
        }
    }
    
    func showAlert() {
        let alert = UIAlertController(title: "Disconnected", message: "Please connect to a device first", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
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
//            self.countLabel.text = "\(count)"
//        } else if type == DataType.image.rawValue {
//            let image = UIImage(data: data)
//            self.imageView.image = image
//        }
//    }
//    
//    func connectionsUpdated() {
//        var newDeviceList: [String] = []
//        if ptManager.isConnected {
//            newDeviceList.append("Your Mac")
//        }
//        if signal.isConnected {
//            newDeviceList.append(contentsOf: signal.connectedDeviceNames)
//        }
//        
//        self.statusLabel.text = "Connected to: \(newDeviceList)"
//    }
}


// MARK: - Peertalk
//extension MobileViewController: PTManagerDelegate {
//    
//    func peertalk(shouldAcceptDataOfType type: UInt32) -> Bool {
//        return true
//    }
//    
//    func peertalk(didReceiveData data: Data, ofType type: UInt32) {
//        self.didReceiveData(data: data, type: type)
//    }
//    
//    func peertalk(didChangeConnection connected: Bool) {
//        connectionsUpdated()
//    }
//    
//}
//
//
//// MARK: - Signal
//extension MobileViewController: SignalDelegate {
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



// MARK: - Image Picker
extension MobileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        self.imageView.image = image
        
        DispatchQueue.global(qos: .background).async {
            let data = UIImageJPEGRepresentation(image, 1.0)!
            self.family.sendData(data: data, type: DataType.image.rawValue)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}


extension MobileViewController: FamilyDelegate {
    
    func family(connectedDevicesChanged devices: [String]) {
        self.statusLabel.text = "Connected to: \(devices)"
    }
    
    func family(didReceiveData data: Data, ofType type: UInt32) {
        if type == DataType.number.rawValue {
            let count = data.convert() as! Int
            self.countLabel.text = "\(count)"
        } else if type == DataType.image.rawValue {
            let image = UIImage(data: data)
            self.imageView.image = image
        }
    }
    
}
