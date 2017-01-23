//
//  Family.swift
//  FamilyDemo
//
//  Created by Kiran Kunigiri on 1/22/17.
//  Copyright © 2017 Kiran. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
#endif

protocol FamilyDelegate {
    
    func family(connectedDevicesChanged devices: [String])
    func family(didReceiveData data: Data, ofType type: UInt32)
    
}

class Family: NSObject {
    
    static let instance = Family()
    
    var delegate: FamilyDelegate?
    let ptManager = PTManager.instance
    let signal = Signal.instance
    
    func initialize(portNumber: Int, serviceType: String) {
        
        // PTManager
        ptManager.delegate = self
        ptManager.connect(portNumber: portNumber)
        
        // Signal
        signal.initialize(serviceType: serviceType)
        signal.delegate = self
        signal.autoConnect()
    }
    
    fileprivate func updateConnectionList() {
        var deviceList: [String] = []
        if ptManager.isConnected {
            deviceList.append("Your Mac")
        }
        if signal.isConnected {
            deviceList.append(contentsOf: signal.connectedDeviceNames)
        }
        print("CONNECTED TO MAC")
        print(signal.connectedDeviceNames)
        print(signal.connectedPeers)
        delegate?.family(connectedDevicesChanged: deviceList)
    }
    
    // MARK: - Methods
    var isConnected: Bool {
        return ptManager.isConnected || signal.isConnected
    }
    
    func sendObject(object: Any, type: UInt32) {
        if ptManager.isConnected {
            ptManager.sendObject(object: object, type: type)
        } else if signal.isConnected {
            signal.sendObject(object: object, type: type)
        }
    }
    
    func sendData(data: Data, type: UInt32) {
        if ptManager.isConnected {
            ptManager.sendData(data: data, type: type)
        } else if signal.isConnected {
            signal.sendData(data: data, type: type)
        }
    }
    
}



// MARK: - Peertalk
extension Family: PTManagerDelegate {
    
    func peertalk(shouldAcceptDataOfType type: UInt32) -> Bool {
        return true
    }
    
    func peertalk(didReceiveData data: Data, ofType type: UInt32) {
        delegate?.family(didReceiveData: data, ofType: type)
    }
    
    func peertalk(didChangeConnection connected: Bool) {
        #if os(iOS)
        updateConnectionList()
        #elseif os(macOS)
        // Shut down the signal services when the mac is connected via USB
        if connected {
            self.signal.shutDown()
            updateConnectionList()
        } else {
            self.signal.autoConnect()
        }
        #endif
    }
    
}



// MARK: - Signal
extension Family: SignalDelegate {
    
    func signal(didReceiveData data: Data, ofType type: UInt32) {
        delegate?.family(didReceiveData: data, ofType: type)
    }
    
    func signal(connectedDevicesChanged devices: [String]) {
        updateConnectionList()
    }
    
}


