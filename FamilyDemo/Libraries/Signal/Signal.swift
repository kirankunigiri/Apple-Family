//
//  Signal.swift
//
//  Created by Kiran Kunigiri on 1/22/17.
//  Copyright © 2017 Kiran. All rights reserved.
//


import Foundation
import MultipeerConnectivity

#if os(iOS)
import UIKit
#endif


// MARK: - Family Protocol
protocol SignalDelegate {
    
    /** Runs when the device has received data from another peer. */
    func signal(didReceiveData data: Data, ofType type: UInt32)
    
    #if os(iOS)
    /** Runs when the device has received an invitation from another */
    func signal(didReceiveInvitation device: String, alertController: UIAlertController?)
    #elseif os(macOS)
    /** Runs when the device has received an invitation from another */
    func signal(didReceiveInvitation device: String)
    #endif
    
    /** Runs when a device connects/disconnects to the session */
    func signal(connectedDevicesChanged devices: [String])
    
}


// MARK: - Main Family Class
class Signal: NSObject {
    
    static let instance = Signal()
    
    // MARK: Properties
    
    /** The name of the signal. Limited to one hyphen (-) and 15 characters */
    var serviceType: String!
    /** The device's name that will appear to others */
    var devicePeerID: MCPeerID!
    /** The host will use this to advertise its signal */
    var serviceAdvertiser: MCNearbyServiceAdvertiser!
    /** Devices will use this to look for a hosted session */
    var serviceBrowser: MCNearbyServiceBrowser!
    /** The amount of time that can be spent connecting with a device before it times out */
    var connectionTimeout = 10.0
    /** The delegate. Conform to its methods to be informed when certain events occur */
    var delegate: SignalDelegate?
    /** Whether the device is automatically inviting all devices */
    var inviteMode = InviteMode.Auto
    /** Whether the device is automatically accepting all invitations */
    var acceptMode = InviteMode.Auto
    /** Peers */
    var availablePeers: [Peer] = []
    var connectedPeers: [Peer] = []
    var connectedDeviceNames: [String] {
        return session.connectedPeers.map({$0.displayName})
    }
    /** Prints out all errors and status updates */
    var debugMode = false
    
    // UI Elements (iOS Only)
    #if os(iOS)
    private var inviteNavigationController: UINavigationController!
    fileprivate var inviteController: InviteTableViewController!
    #endif
    
    /** The main object that manages the current connections */
    lazy var session: MCSession = {
        let session = MCSession(peer: self.devicePeerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        session.delegate = self
        return session
    }()
    
    
    
    // MARK: - Initializers
    
    /** Initializes the signal service. Service type is just the name of the signal, and is limited to one hyphen (-) and 15 characters */
    func initialize(serviceType: String) {
        #if os(iOS)
            initialize(serviceType: serviceType, deviceName: UIDevice.current.name)
        #elseif os(macOS)
            initialize(serviceType: serviceType, deviceName: Host.current().name!)
        #endif
    }
    
    /** Initializes the signal service. Service type is just the name of the signal, and is limited to one hyphen (-) and 15 characters. The device name is what others will see. */
    func initialize(serviceType: String, deviceName: String) {
        // Setup device/signal properties
        self.serviceType = serviceType
        self.devicePeerID = MCPeerID(displayName: deviceName)
        
        // Setup the service advertiser
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: self.devicePeerID, discoveryInfo: nil, serviceType: serviceType)
        self.serviceAdvertiser.delegate = self
        
        // Setup the service browser
        self.serviceBrowser = MCNearbyServiceBrowser(peer: self.devicePeerID, serviceType: serviceType)
        self.serviceBrowser.delegate = self
        
        
        #if os(iOS)
            // Setup the invite view controller
            let storyboard = UIStoryboard(name: "Signal", bundle: nil)
            inviteController = storyboard.instantiateViewController(withIdentifier: "inviteViewController") as! InviteTableViewController
            inviteController.delegate = self
            
            inviteNavigationController = UINavigationController(rootViewController: inviteController)
            inviteNavigationController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            
            let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButton))
            inviteController.navigationItem.setRightBarButton(doneBarButton, animated: true)
        #endif
    }
    
    // Stop the advertising and browsing services
    deinit {
        disconnect()
    }
    
    
    // MARK: - Methods
    
    
    #if os(iOS)
    // NAVIGATION CONTROLLER
    
    @objc private func cancelButton() {
        self.disconnect()
        inviteNavigationController.dismiss(animated: true, completion: nil)
    }
    
    @objc private func doneButton() {
        inviteNavigationController.dismiss(animated: true, completion: nil)
    }
    
    /** Returns a View Controller that you can present so the user can manually invite certain devices */
    func inviteUI() -> UIViewController {
        self.inviteMode = .UI
        self.serviceBrowser.startBrowsingForPeers()
    
        return inviteNavigationController
    }
    #endif
    
    
    
    // HOST
    
    /** Automatically invites all devices it finds */
    func inviteAuto() {
        self.inviteMode = .Auto
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    
    
    // JOIN
    
    /** Automatically accepts all invites */
    func acceptAuto() {
        self.acceptMode = .Auto
        self.serviceAdvertiser.startAdvertisingPeer()
    }
    
    /** You will now be given a UIAlertController in the protocol method so that the user can accept/decline an invitation */
    func acceptUI() {
        self.acceptMode = .UI
        self.serviceAdvertiser.startAdvertisingPeer()
    }
    
    
    
    // OTHER
    
    /** Automatically begins to connect all devices with the same service type to each other. It works by running the host and join methods on all devices so that they connect as fast as possible. */
    func autoConnect() {
        inviteAuto()
        acceptAuto()
    }
    
    /** Stops the invitation process */
    func stopInviting() {
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    /** Stops accepting invites and becomes invisible on the network */
    func stopAccepting() {
        self.serviceAdvertiser.stopAdvertisingPeer()
    }
    
    /** Stops all invite/accept services */
    func stopSearching() {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    /** Disconnects from the current session and stops all searching activity */
    func disconnect() {
        session.disconnect()
        connectedPeers.removeAll()
        availablePeers.removeAll()
    }
    
    /** Shuts down all signal services. Stops inviting/accepting and disconnects from the session */
    func shutDown() {
        stopSearching()
        disconnect()
    }
    
    var isConnected: Bool {
        return connectedPeers.count >= 1
    }
    
    enum InviteMode {
        case Auto
        case UI
    }
    
    enum AcceptMode {
        case Auto
        case UI
    }
    
    /** Sends data to all connected peers. Pass in an object, and the method will convert it into data and send it. You can use the Data extended method, `convertData()` in order to convert it back into an object. */
    func sendObject(object: Any, type: UInt32) {
        if (session.connectedPeers.count > 0) {
            do {
                let data = NSKeyedArchiver.archivedData(withRootObject: object)
                let container: [Any] = [data, type]
                let item = NSKeyedArchiver.archivedData(withRootObject: container)
                try session.send(item, toPeers: session.connectedPeers, with: MCSessionSendDataMode.reliable)
            } catch let error {
                printDebug(error.localizedDescription)
            }
        }
    }
    
    /** Sends data to all connected peers. Pass in an object, and the method will convert it into data and send it. You can use the Data extended method, `convertData()` in order to convert it back into an object. */
    func sendData(data: Data, type: UInt32) {
        if (session.connectedPeers.count > 0) {
            do {
                let container: [Any] = [data, type]
                let item = NSKeyedArchiver.archivedData(withRootObject: container)
                try session.send(item, toPeers: session.connectedPeers, with: MCSessionSendDataMode.reliable)
            } catch let error {
                printDebug(error.localizedDescription)
            }
        }
    }
    
    /** Prints only if in debug mode */
    fileprivate func printDebug(_ string: String) {
        if debugMode {
            print(string)
        }
    }
    
}



// MARK: - Advertiser Delegate
extension Signal: MCNearbyServiceAdvertiserDelegate {
    
    #if os(iOS)
    /** Creates a UI Alert given the name of the device */
    func alertForInvitation(name: String, completion: @escaping (Bool) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: "Invite", message: "You've received an invite from \(name)", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Accept", style: .default, handler: { action in
            completion(true)
        }))
        alert.addAction(UIAlertAction(title: "Decline", style: .destructive, handler: { action in
            completion(false)
        }))
        return alert
    }
    #endif
    
    // Received invitation
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        OperationQueue.main.addOperation {
            if self.acceptMode == .Auto {
                #if os(iOS)
                self.delegate?.signal(didReceiveInvitation: peerID.displayName, alertController: nil)
                #elseif os(macOS)
                self.delegate?.signal(didReceiveInvitation: peerID.displayName)
                #endif
                invitationHandler(true, self.session)
            } else if self.acceptMode == .UI {
                #if os(iOS)
                    let alert = UIAlertController(title: "Invite", message: "You've received an invite from \(peerID.displayName)", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Accept", style: .default, handler: { action in
                        invitationHandler(true, self.session)
                    }))
                    alert.addAction(UIAlertAction(title: "Decline", style: .destructive, handler: { action in
                        invitationHandler(false, self.session)
                    }))
                    self.delegate?.signal(didReceiveInvitation: peerID.displayName, alertController: alert)
                #endif
            }
        }
    }
    
    // Error, could not start advertising
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        printDebug("Could not start advertising due to error: \(error)")
    }
    
}



// MARK: - Browser Delegate
extension Signal: MCNearbyServiceBrowserDelegate {
    
    // Found a peer
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        printDebug("Found peer: \(peerID)")
        
        // Update the list and the controller
        availablePeers.append(Peer(peerID: peerID, state: .notConnected))
        #if os(iOS)
        inviteController.update()
        #endif
        
        // Invite peer in auto mode
        if (inviteMode == .Auto) {
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: connectionTimeout)
        }
    }
    
    
    // Error, could not start browsing
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        printDebug("Could not start browsing due to error: \(error)")
    }
    
    // Lost a peer
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        printDebug("Lost peer: \(peerID)")
        
        // Update the lost peer
        availablePeers = availablePeers.filter{ $0.peerID != peerID }
        
        #if os(iOS)
        inviteController.update()
        #endif
    }
    
}



// MARK: - Session Delegate
extension Signal: MCSessionDelegate {
    
    // Peer changed state
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        printDebug("Peer \(peerID.displayName) changed state to \(state.stringValue)")
        
        // If the new state is connected, then remove it from the available peers
        // Otherwise, update the state
        if state == .connected {
            availablePeers = availablePeers.filter{ $0.peerID != peerID }
        } else {
            availablePeers.filter{ $0.peerID == peerID }.first?.state = state
        }
        
        // Update all connected peers
        connectedPeers = session.connectedPeers.map{ Peer(peerID: $0, state: .connected) }
        
        #if os(iOS)
        // Update table view
        inviteController.update()
        #endif
        
        // Send new connection list to delegate
        OperationQueue.main.addOperation {
            self.delegate?.signal(connectedDevicesChanged: session.connectedPeers.map({$0.displayName}))
        }
    }
    
    // Received data
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        printDebug("Received data: \(data.count) bytes")
        
        let container = data.convert() as! [Any]
        let item = container[0] as! Data
        let type = container[1] as! UInt32
        
        OperationQueue.main.addOperation {
            self.delegate?.signal(didReceiveData: item, ofType: type)
        }
        
    }
    
    // Received stream
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        printDebug("Received stream")
    }
    
    // Finished receiving resource
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        printDebug("Finished receiving resource with name: \(resourceName)")
    }
    
    // Started receiving resource
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        printDebug("Started receiving resource with name: \(resourceName)")
    }
    
}



#if os(iOS)
// MARK: - Invite Tableview Delegate
extension Signal: InviteDelegate {
    
    internal func getAvailablePeers() -> [Peer] {
        return availablePeers
    }
    
    func getConnectedPeers() -> [Peer] {
        return connectedPeers
    }
    
    func invitePeer(peer: Peer) {
        self.serviceBrowser.invitePeer(peer.peerID, to: session, withContext: nil, timeout: connectionTimeout)
    }
    
}
#endif


// MARK: - Information data
extension MCSessionState {
    
    /** String version of an `MCSessionState` */
    var stringValue: String {
        switch(self) {
        case .notConnected: return "Available"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        }
    }
    
}



// MARK: - Custom Peer class
// This class is used to contain the peerID along with the state to be presented in a table view
class Peer {
    
    var peerID: MCPeerID
    var state: MCSessionState
    
    init(peerID: MCPeerID, state: MCSessionState) {
        self.peerID = peerID
        self.state = state
    }
    
}





