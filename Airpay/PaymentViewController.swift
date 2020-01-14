//
//  PaymentController.swift
//  Airpay
//
//  Created by Isabelle on 1/13/20.
//  Copyright © 2020 airpay. All rights reserved.
//

import UIKit
import MultiPeer

enum DataType: UInt32 {
    case message = 1
    case image = 2
    case username = 3
}



class PaymentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Properties
    
    // cell reuse id (cells that scroll out of view can be reused)
    let cellReuseIdentifier = "cell"
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var requestButton: UIButton!
    @IBOutlet weak var payButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var user: User?
    var nearbyUsers = [String]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let nameText = user?.name {
            print(nameText)
            
            nameLabel.text = nameText
        }
        
        if let balanceText = user?.balance {
            print(balanceText)
            
            balanceLabel.text = String(balanceText)
        }
        
        textField.delegate = self
    self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        tableView.delegate = self
        tableView.dataSource = self


        MultiPeer.instance.delegate = self

        MultiPeer.instance.initialize(serviceType: "sample-app")
        MultiPeer.instance.autoConnect()
        
    }
    
    
    // Dismiss keyboard on tap
      override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
          self.view.endEditing(true)
      }
    
    override func viewWillDisappear(_ animated: Bool) {
        MultiPeer.instance.disconnect()

        super.viewWillDisappear(animated)
    }
    
    
    // MARK: Actions
    
    @IBAction func didPressLoadButton(_ sender: Any) {

        }

    @IBAction func didPressRequestButton(_ sender: Any) {
        
        // Device will stop advertising/browsing until after MultiPeer has sent data
        MultiPeer.instance.stopSearching()
        
        defer {
            MultiPeer.instance.autoConnect()
            }
        
        if let username = user?.name {
            MultiPeer.instance.send(object: username, type: DataType.username.rawValue)
        }
        
        
        if let message = textField.text {
            MultiPeer.instance.send(object: "-$" + message, type: DataType.message.rawValue)
            }
        
    }
    
    @IBAction func didPressPayButton(_ sender: Any) {
        
        // Device will stop advertising/browsing until after MultiPeer has sent data
        MultiPeer.instance.stopSearching()
        
        defer {
            MultiPeer.instance.autoConnect()
            }
        
        if let username = user?.name {
            MultiPeer.instance.send(object: username, type: DataType.username.rawValue)
        }
        
        if let message = textField.text {
            MultiPeer.instance.send(object: "+$" + message, type: DataType.message.rawValue)
            }
        }
    
    // MARK: Table View
    
    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nearbyUsers.count
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = (tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell?)!

        // set the text from the data model
        cell.textLabel?.text = self.nearbyUsers[indexPath.row]

        return cell
    }
    
    }
    
    
    extension PaymentViewController: MultiPeerDelegate {

        func multiPeer(didReceiveData data: Data, ofType type: UInt32) {
            switch type {
            case DataType.message.rawValue:
                guard let message = data.convert() as? String else { return }
                textField.text = message
                break
            case DataType.username.rawValue:
                guard let username = data.convert() as? String else { return }
                nearbyUsers.append(username)
                break
            default:
                break
            }
            
            tableView.reloadData()
        }

        func multiPeer(connectedDevicesChanged devices: [String]) {
            print("Connected devices changed: \(devices)")
        }
    }


    extension PaymentViewController: UITextFieldDelegate {
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }


