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


}

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.textLabel.text = textField.text
        if (textField.text != nil && textField.text!.characters.count > 0) {
            family.sendData(object: textField.text!)
        }
        return true
    }
}

extension ViewController: FamilyDelegate {
    
    func receivedData(data: Data) {
        OperationQueue.main.addOperation {
            let string = data.convert() as? String
            self.textLabel.text = string
        }
    }
    
}
