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
    func receivedData(data: Data)
}



// MARK: - Main Family Class
class Family: NSObject {
    
    
    // MARK: Properties
    /** Limited to one hyphen (-) and 15 characters */
    var serviceType: String!
    var devicePeerID: MCPeerID!
    var serviceAdvertiser: MCNearbyServiceAdvertiser!
    var serviceBrowser: MCNearbyServiceBrowser!
    var connectionTimeout = 10.0
    var delegate : FamilyDelegate?
    
    lazy var session: MCSession = {
        let session = MCSession(peer: self.devicePeerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        session.delegate = self
        return session
    }()
    
    
    
    // MARK: - Initializers
    /** Initializes the family. Service type is limited to one hyphen (-) and 15 characters */
    init(serviceType: String) {
        super.init()
        
        self.serviceType = serviceType
        self.devicePeerID = MCPeerID(displayName: UIDevice.current.name)
        
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: self.devicePeerID, discoveryInfo: nil, serviceType: serviceType)
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser = MCNearbyServiceBrowser(peer: self.devicePeerID, serviceType: serviceType)
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    
    // MARK: - Methods
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
        invitationHandler(true, self.session)
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
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: connectionTimeout)
    }
    
    
    // Error, could not start browsing
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Could not start browsing due to error: \(error)")
    }
    
    // Lost a peer
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID)")
    }
    
}



// MARK: - Session Delegate
extension Family: MCSessionDelegate {
    
    // Peer changed state
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("Peer \(peerID) changed state to \(state)")
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



// MARK: - Data extension for conversion
extension Data {
    
    /** Unarchive NSData into an object. You must manually cast it into a class */
    func convert() -> Any {
        return NSKeyedUnarchiver.unarchiveObject(with: self)!
    }
    
}



// MARK: - Information data
extension MCSessionState {
    
    // TODO: Method or function var?
    /** String version of an MCSessionState */
    func stringValue() -> String {
        switch(self) {
            case .notConnected: return "Not Connected"
            case .connecting: return "Connecting"
            case .connected: return "Connected"
        }
    }
    
}








