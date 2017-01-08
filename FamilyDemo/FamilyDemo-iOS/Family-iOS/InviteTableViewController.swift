//
//  InviteTableViewController.swift
//  Family
//
//  Created by Kiran Kunigiri on 12/20/16.
//  Copyright © 2016 Kiran. All rights reserved.
//

import UIKit


protocol InviteDelegate {
    
    func getConnectedPeers() -> [Peer]
    func getAvailablePeers() -> [Peer]
    func invitePeer(peer: Peer)
    
}

class InviteTableViewController: UITableViewController {

    @IBOutlet weak var nearbyTableView: UITableView!
    var delegate: InviteDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Reloads the table view on the main thread
    func update() {
        OperationQueue.main.addOperation {
            self.tableView.reloadData()
        }
    }

}

// MARK - Table View Delegate
extension InviteTableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // End if a connected device was selected
        if (indexPath.section == 0) {
            return
        }
        
        // Send invitation to the peer
        let peer = delegate?.getAvailablePeers()[indexPath.row]
        delegate?.invitePeer(peer: peer!)
    }
    
}



// MARK: - Table View Data Source
extension InviteTableViewController {
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Connected"
        case 1:
            return "Available"
        default:
            return ""
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return (delegate?.getConnectedPeers().count)!
        case 1:
            return (delegate?.getAvailablePeers().count)!
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! DeviceCell
        
        // Update text
        switch indexPath.section {
        case 0:
            let peer = delegate?.getConnectedPeers()[indexPath.row]
            cell.name.text = peer?.peerID.displayName
            cell.status.text = peer?.state.stringValue()
        case 1:
            let peer = delegate?.getAvailablePeers()[indexPath.row]
            cell.name.text = peer?.peerID.displayName
            cell.status.text = peer?.state.stringValue()
        default:
            cell.name.text = ""
        }
        
        // Selection
        if (indexPath.section == 0) {
            cell.isUserInteractionEnabled = false
        } else {
            cell.isUserInteractionEnabled = true
        }
        
        return cell
    }
    
}



// MARK: - Table View Cell
class DeviceCell: UITableViewCell {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var status: UILabel!
    
}
















