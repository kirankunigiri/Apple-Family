//
//  Family.swift
//  Family
//
//  Created by Kiran Kunigiri on 12/16/16.
//  Copyright © 2016 Kiran. All rights reserved.
//


import Foundation
import MultipeerConnectivity



// MARK: - Family Protocol
protocol FamilyDelegate {
    
    /** Runs when the device has received data from another peer. */
    func receivedData(data: Data)
    
    /** Runs when the device has received an invitation from another */
    func receivedInvitation(device: String, alert: UIAlertController?)
    
    /** Runs when a device connects/disconnects to the session */
    func deviceConnectionsChanged(connectedDevices: [String])
    
}



// MARK: - Main Family Class
class Family: NSObject {
    
    
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
    var delegate: FamilyDelegate?
    /** Whether the device is automatically inviting all devices */
    var inviteMode = InviteMode.Auto
    /** Whether the device is automatically accepting all invitations */
    var acceptMode = InviteMode.Auto
    
    var inviteNavigationController: UINavigationController!
    var inviteController: InviteTableViewController!
    var availablePeers: [Peer] = []
    var connectedPeers: [Peer] = []
    
    /** The main object that manages the current connections */
    lazy var session: MCSession = {
        let session = MCSession(peer: self.devicePeerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        session.delegate = self
        return session
    }()
    
    
    
    // MARK: - Initializers
    
    /** Initializes the family. Service type is just the name of the signal, and is limited to one hyphen (-) and 15 characters */
    convenience init(serviceType: String) {
        self.init(serviceType: serviceType, deviceName: UIDevice.current.name)
    }
    
    /** Initializes the family. Service type is just the name of the signal, and is limited to one hyphen (-) and 15 characters. The device name is what others will see. */
    init(serviceType: String, deviceName: String) {
        super.init()
        
        // Setup device/signal properties
        self.serviceType = serviceType
        self.devicePeerID = MCPeerID(displayName: deviceName)
        
        // Setup the service advertiser
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: self.devicePeerID, discoveryInfo: nil, serviceType: serviceType)
        self.serviceAdvertiser.delegate = self
        
        // Setup the service browser
        self.serviceBrowser = MCNearbyServiceBrowser(peer: self.devicePeerID, serviceType: serviceType)
        self.serviceBrowser.delegate = self
        
        // Setup the invite view controller
        
        let storyboard = UIStoryboard(name: "Family", bundle: nil)
        inviteController = storyboard.instantiateViewController(withIdentifier: "inviteViewController") as! InviteTableViewController
        inviteController.delegate = self
        
        inviteNavigationController = UINavigationController(rootViewController: inviteController)
        inviteNavigationController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButton))
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButton))
        doneBarButton.isEnabled = false
        inviteController.navigationItem.setLeftBarButton(cancelBarButton, animated: false)
        inviteController.navigationItem.setRightBarButton(doneBarButton, animated: true)
    }
    
    // Stop the advertising and browsing services
    deinit {
        disconnect()
    }
    
    
    // MARK: - Methods
    
    
    
    // NAVIGATION CONTROLLER
    
    @objc private func cancelButton() {
        self.disconnect()
        inviteNavigationController.dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func doneButton() {
        inviteNavigationController.dismiss(animated: true, completion: nil)
    }
    
    
    
    // HOST
    
    /** Automatically invites all devices it finds */
    func inviteAuto() {
        self.inviteMode = .Auto
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    /** Returns a View Controller that you can present so the user can manually invite certain devices */
    func inviteUI() -> UIViewController {
        self.inviteMode = .UI
        self.serviceBrowser.startBrowsingForPeers()
        
        return inviteNavigationController
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
    
    /** Shuts down all family services. Stops inviting/accepting and disconnects from the session */
    func shutDown() {
        stopSearching()
        disconnect()
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
    func sendData(object: Any) {
        if (session.connectedPeers.count > 0) {
            do {
                let data = NSKeyedArchiver.archivedData(withRootObject: object)
                try session.send(data, toPeers: session.connectedPeers, with: MCSessionSendDataMode.reliable)
            } catch let error {
                print(error)
            }
        }
    }
    
}



// MARK: - Advertiser Delegate
extension Family: MCNearbyServiceAdvertiserDelegate {
    
    // Received invitation
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        print("Received invitation from: \(peerID)")
        
        if (acceptMode == .Auto) {
            // Auto: Accept the invite
            invitationHandler(true, self.session)
        } else if (acceptMode == .UI) {
            // UI: Present an alert
            let alert = UIAlertController(title: "Invite", message: "You've received an invite from \(peerID.displayName)", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Accept", style: .default, handler: { action in
                invitationHandler(true, self.session)
            }))
            alert.addAction(UIAlertAction(title: "Decline", style: .destructive, handler: { action in
                invitationHandler(false, self.session)
            }))
            delegate?.receivedInvitation(device: peerID.displayName, alert: alert)
        }
    }
    
    // Error, could not start advertising
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Could not start advertising due to error: \(error)")
    }
    
}



// MARK: - Browser Delegate
extension Family: MCNearbyServiceBrowserDelegate {
    
    // Found a peer
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID)")
        
        // Update the list and the controller
        availablePeers.append(Peer(peerID: peerID, state: .notConnected))
        inviteController.update()
        
        // Invite peer in auto mode
        if (inviteMode == .Auto) {
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: connectionTimeout)
        }
    }
    
    
    // Error, could not start browsing
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Could not start browsing due to error: \(error)")
    }
    
    // Lost a peer
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID)")
        
        // Update the lost peer
        availablePeers = availablePeers.filter{ $0.peerID != peerID }
        inviteController.update()
    }
    
    // A method for debugging
    func printInfo() {
        print(availablePeers)
        print(connectedPeers)
        print("")
    }
    
}



// MARK: - Session Delegate
extension Family: MCSessionDelegate {
    
    // Peer changed state
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("Peer \(peerID.displayName) changed state to \(state.stringValue())")
        
        // If the new state is connected, then remove it from the available peers
        // Otherwise, update the state
        if state == .connected {
            availablePeers = availablePeers.filter{ $0.peerID != peerID }
        } else {
            availablePeers.filter{ $0.peerID == peerID }.first?.state = state
        }
        
        // Update all connected peers
        connectedPeers = session.connectedPeers.map{ Peer(peerID: $0, state: .connected) }
        
        // Update table view
        inviteController.update()
        
        // Send new connection list to delegate
        self.delegate?.deviceConnectionsChanged(connectedDevices: session.connectedPeers.map({$0.displayName}))
    }
    
    // Received data
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("Received data: \(data.count) bytes")
        delegate?.receivedData(data: data)
    }
    
    // Received stream
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Received stream")
    }
    
    // Finished receiving resource
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        print("Finished receiving resource with name: \(resourceName)")
    }
    
    // Started receiving resource
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Started receiving resource with name: \(resourceName)")
    }
    
}



// MARK: - Invite Tableview Delegate
extension Family: InviteDelegate {
    
    func getAvailablePeers() -> [Peer] {
        return availablePeers
    }
    
    func getConnectedPeers() -> [Peer] {
        return connectedPeers
    }
    
    func invitePeer(peer: Peer) {
        self.serviceBrowser.invitePeer(peer.peerID, to: session, withContext: nil, timeout: connectionTimeout)
    }
    
}


// MARK: - Data extension for conversion
extension Data {
    
    /** Unarchive data into an object. It will be returned as type `Any` but you can cast it into the correct type. */
    func convert() -> Any {
        return NSKeyedUnarchiver.unarchiveObject(with: self)!
    }
    
}



// MARK: - Information data
extension MCSessionState {
    
    // TODO: Method or function var?
    
    /** String version of an `MCSessionState` */
    func stringValue() -> String {
        switch(self) {
            case .notConnected: return "Available"
            case .connecting: return "Connecting"
            case .connected: return "Connected"
        }
    }
    
}


class Peer {
    
    init(peerID: MCPeerID, state: MCSessionState) {
        self.peerID = peerID
        self.state = state
    }
    
    var peerID: MCPeerID
    var state: MCSessionState
    
}





