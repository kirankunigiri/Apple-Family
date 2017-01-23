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

enum SignalType {
    case Automatic
    case InviteAuto
    case AcceptAuto
    #if os(iOS)
    case InviteUI
    case AcceptUI
    #endif
}

class Family: NSObject {
    
    static let instance = Family()
    
    var delegate: FamilyDelegate?
    let ptManager = PTManager.instance
    let signal = Signal.instance
    var signalType = SignalType.AcceptAuto
    
    func initialize(portNumber: Int, serviceType: String, signalType: SignalType) {
        
        // PTManager
        ptManager.delegate = self
        ptManager.connect(portNumber: portNumber)
        
        // Signal
        self.signalType = signalType
        signal.initialize(serviceType: serviceType)
        signal.delegate = self
        signal.debugMode = true
        
        // Create a delay because of a bug where signal and peertalk clash on startup
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timer), userInfo: nil, repeats: false)
    }
    
    func timer() {
        #if os(macOS)
        if !ptManager.isConnected {
            self.startSignal()
        }
        #elseif os(iOS)
        self.startSignal()
        #endif
    }
    
    func startSignal() {
        #if os(macOS)
            switch signalType {
            case .Automatic:
                signal.autoConnect()
            case .InviteAuto:
                signal.inviteAuto()
            case .AcceptAuto:
                signal.acceptAuto()
            }
        #endif
            
        #if os(iOS)
            switch signalType {
            case .Automatic:
                signal.autoConnect()
            case .InviteAuto:
                signal.inviteAuto()
            case .AcceptAuto:
                signal.acceptAuto()
            case .InviteUI:
                signal.inviteUI()
            default:
                // Accept UI
                signal.acceptUI()
        }
        #endif
    }
    
    fileprivate func updateConnectionList() {
        var deviceList: [String] = []
        if ptManager.isConnected {
            #if os(iOS)
            deviceList.append("Your Mac")
            #elseif os(macOS)
            deviceList.append("Your iDevice")
            #endif
        }
        if signal.isConnected {
            deviceList.append(contentsOf: signal.connectedDeviceNames)
        }
        
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
            self.updateConnectionList()
        } else {
            self.startSignal()
            self.updateConnectionList()
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
        OperationQueue.main.addOperation {
            self.updateConnectionList()
        }
    }
    
}


