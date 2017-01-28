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
    case automatic
    case inviteAuto
    case acceptAuto
    #if os(iOS)
    case acceptUI
    #endif
    case none
}

enum ConnectionType {
    case signal
    case usb
    case none
}

class Family: NSObject {
    
    static let instance = Family()
    
    var delegate = MulticastDelegate<FamilyDelegate>()
    let ptManager = PTManager.instance
    let signal = Signal.instance
    
    var signalType = SignalType.none
    var portNumber: Int!
    var serviceType: String!
    
    /** The list of device names connected */
    var connectedDevices: [String] = []
    
    func initialize(portNumber: Int, serviceType: String, signalType: SignalType) {
        
        self.portNumber = portNumber
        self.serviceType = serviceType
        self.signalType = signalType
        
        // PTManager
        ptManager.delegate = self
        ptManager.connect(portNumber: portNumber)
        
        // Signal
        signal.initialize(serviceType: serviceType)
        signal.delegate = self
        
        // Create a delay because of a bug where signal and peertalk clash on startup
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(timer), userInfo: nil, repeats: false)
    }
    
    @objc fileprivate func timer() {
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
            case .automatic:
                signal.autoConnect()
            case .inviteAuto:
                signal.inviteAuto()
            case .acceptAuto:
                signal.acceptAuto()
            case .none:
                return
            }
        #endif
            
        #if os(iOS)
            switch signalType {
            case .automatic:
                signal.autoConnect()
            case .inviteAuto:
                signal.inviteAuto()
            case .acceptAuto:
                signal.acceptAuto()
            case .acceptUI:
                return
            case .none:
                return
        }
        #endif
    }
    
    /** Updates the list of connected devices */
    fileprivate func updateConnectionList() {
        self.connectedDevices.removeAll()
        if ptManager.isConnected {
            #if os(iOS)
            connectedDevices.append("Your Mac")
            #elseif os(macOS)
            connectedDevices.append("Your iDevice")
            #endif
        }
        if signal.isConnected {
            connectedDevices.append(contentsOf: signal.connectedDeviceNames)
        }
        
        delegate.invoke { $0.family(connectedDevicesChanged: connectedDevices) }
    }
    
    // MARK: - Methods
    
    /** Run this method in the `applicationDidBecomeActive` method to revive the USB connection */
    func reconnect() {
        ptManager.connect(portNumber: portNumber)
    }
    
    /** Opens a View Controller where the user can invite nearby devices */
    #if os(iOS)
    func inviteSignalUI() {
        signal.inviteUI()
    }
    #endif
    
    /** Whether or not the device is currently connected */
    var isConnected: Bool {
        return ptManager.isConnected || signal.isConnected
    }
    
    /** The type of connection. Either USB, Signal, or none */
    var connectionType: ConnectionType {
        if ptManager.isConnected {
            return .usb
        } else if signal.isConnected {
            return .signal
        } else {
            return .none
        }
    }
    
    /** Sends any object with the specified type tag */
    func sendObject(object: Any, type: UInt32) {
        if ptManager.isConnected {
            ptManager.sendObject(object: object, type: type)
        } else if signal.isConnected {
            signal.sendObject(object: object, type: type)
        }
    }
    
    /** Sends data with the specified type tag */
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
        delegate.invoke { $0.family(didReceiveData: data, ofType: type) }
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
        delegate.invoke { $0.family(didReceiveData: data, ofType: type) }
    }
    
    func signal(connectedDevicesChanged devices: [String]) {
        self.updateConnectionList()
    }
    
}



// MARK: - Multicast Delegate
// Allows multiple classes to be the delegate of Family
// Credit: This class is from http://www.gregread.com/2016/02/23/multicast-delegates-in-swift/
class MulticastDelegate <T> {
    private var weakDelegates = [WeakWrapper]()
    
    func addDelegate(delegate: T) {
        // If delegate is a class, add it to our weak reference array
        if delegate is AnyObject {
            weakDelegates.append(WeakWrapper(value: delegate as AnyObject))
        }
            // Delegate being passed is "by value" (not supported)
        else {
            fatalError("MulticastDelegate does not support value types")
        }
    }
    
    func removeDelegate(delegate: T) {
        // If delegate is an object, let's loop through weakDelegates to
        // find it.  We
        if delegate is AnyObject {
            for (index, delegateInArray) in weakDelegates.enumerated().reversed() {
                // If we have a match, remove the delegate from our array
                if delegateInArray.value === (delegate as AnyObject) {
                    weakDelegates.remove(at: index)
                }
            }
        }
        
        // Else, it's a value type and we don't need to do anything
    }
    
    func invoke(invocation: (T) -> ()) {
        // Enumerating in reverse order prevents a race condition from happening when removing elements.
        for (index, delegate) in weakDelegates.enumerated().reversed() {
            // Since these are weak references, "value" may be nil
            // at some point when ARC is 0 for the object.
            if let delegate = delegate.value {
                invocation(delegate as! T)
            }
                // Else, ARC killed it, get rid of the element from our
                // array
            else {
                weakDelegates.remove(at: index)
            }
        }
    }
}

func += <T: AnyObject> (left: MulticastDelegate<T>, right: T) {
    left.addDelegate(delegate: right)
}

func -= <T: AnyObject> (left: MulticastDelegate<T>, right: T) {
    left.removeDelegate(delegate: right)
}

private class WeakWrapper {
    weak var value: AnyObject?
    
    init(value: AnyObject) {
        self.value = value
    }
}

