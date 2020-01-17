
//  PaymentController.swift
//  Airpay
//
//  Created by Isabelle on 1/13/20.
//  Copyright © 2020 airpay. All rights reserved.
//

import UIKit
import MultiPeer
import Stripe
import Alamofire

enum DataType: UInt32 {
    case initialRequest = 1 // requesting $x
    case initialResponse = 2 // responding with username
    case finalRequest = 3 // requesting $x from y usernames
    case finalResponse = 4 // username accepts or declines request
    case payConfirm = 5 // payee is alerted of payment
}

extension String {

  subscript (r: CountableClosedRange<Int>) -> String {
    get {
      let startIndex =  self.index(self.startIndex, offsetBy: r.lowerBound)
      let endIndex = self.index(startIndex, offsetBy: r.upperBound - r.lowerBound)
      return String(self[startIndex...endIndex])
    }
  }
}


class PaymentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIApplicationDelegate {

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
    var selectedUsers = [String]()
    
    var baseURLString: String? = nil
    var baseURL: URL {
        if let urlString = self.baseURLString, let url = URL(string: urlString) {
            return url
        } else {
            fatalError()
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        STPPaymentConfiguration.shared().publishableKey = "pk_test_Qw0haIYdMjpZwWVGPKolFtnt007eI4imFa"
        // do any other necessary launch configuration
        return true
    }
    
    
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
        


        self.textField.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.allowsMultipleSelection = true
        
        
        
    self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
                        
        if let username = user?.name {
            MultiPeer.instance.delegate = self

        MultiPeer.instance.initialize(serviceType: "sample-app", deviceName: username)
            MultiPeer.instance.autoConnect()
        }
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
    
    @IBAction func didPressRequestButton(_ sender: Any) {
        
        // Device will stop advertising/browsing until after MultiPeer has sent data
        MultiPeer.instance.stopSearching()
        
        defer {
            MultiPeer.instance.autoConnect()
            }
        
        
        
        if let message = textField.text {
               if !message.isEmpty {
                    if let username = user?.name {
                        
                        let obj = ["message": message, "requester": username,
                                   "selectedUsers": selectedUsers] as [String : Any]
                        
                        
                        print(obj)
                        
                MultiPeer.instance.send(object: obj, type: DataType.finalRequest.rawValue)
                
            }
        }
        }
    }
    
    @IBAction func didPressPayButton(_ sender: Any) {
        // Device will stop advertising/browsing until after MultiPeer has sent data
        MultiPeer.instance.stopSearching()
        
        defer {
            MultiPeer.instance.autoConnect()
            }
                
        if let message = textField.text {
               if !message.isEmpty {
                    if let username = user?.name {
                        
                        
                confirmAlert(username: username, message: message)
                }
            }
        }

    }
    
    // MARK: Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nearbyUsers.count
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        
        // set the text from the data model
        cell.textLabel?.text = self.nearbyUsers[indexPath.row]

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = nearbyUsers[indexPath.row]

        if !selectedUsers.contains(selectedUser) {
            selectedUsers.append(selectedUser)
        }
            
    }
    
    // MARK: Helpers
    func paymentContext(_ paymentContext: STPPaymentContext, didUpdateShippingAddress address: STPAddress, completion: @escaping STPShippingMethodsCompletionBlock) {
        let upsGround = PKShippingMethod()
        upsGround.amount = 0
        upsGround.label = "UPS Ground"
        upsGround.detail = "Arrives in 3-5 days"
        upsGround.identifier = "ups_ground"
        let fedEx = PKShippingMethod()
        fedEx.amount = 5.99
        fedEx.label = "FedEx"
        fedEx.detail = "Arrives tomorrow"
        fedEx.identifier = "fedex"
        if address.country == "US" {
            completion(.valid, nil, [upsGround, fedEx], upsGround)
        }
        else {
            completion(.invalid, nil, nil, nil)
        }
    }
    
    func sendFinalRequest() {
        let selectedUsers = nearbyUsers // TODO: change
        if let message = textField.text {
               if !message.isEmpty {
                    if let username = user?.name {
                        let obj = ["message": message, "requester": username,
                                   "selectedUsers": selectedUsers] as [String : Any]
                        print(obj)
                MultiPeer.instance.send(object: obj, type: DataType.finalRequest.rawValue)
                    }
                }
        }
    }
    
    func sendFinalResponse(username: String, message: String) {
        if let responder = user?.name {
            let messageNumber = Double(message)!
            self.user?.subtractBalance(change: messageNumber)
            if let balanceText = self.user?.getBalance() {
                print(balanceText)
                self.balanceLabel.text = String(balanceText)
            }
            let obj = ["message": message, "requester": username, "responder": responder] as [String : String]
            MultiPeer.instance.send(object: obj, type: DataType.finalResponse.rawValue)
        }
    }
    
    func payResponse(username: String, message: String) {
          if let username = user?.name {
                         
             let messageNumber = Double(message)!
            self.user?.subtractBalance(change: (Double(self.selectedUsers.count) * messageNumber))
             
             if let balanceText = self.user?.getBalance() {
                 print(balanceText)
                 self.balanceLabel.text = String(balanceText)
             }
            
            let obj = ["message": message, "requester": username, "selectedUsers": self.selectedUsers] as [String : Any]
             MultiPeer.instance.send(object: obj, type: DataType.payConfirm.rawValue)
             
             
         }
         
         
     }
    
     func payeeResponse(username: String, message: String) {
         let messageNumber = Double(message)!
         self.user?.addBalance(change: messageNumber)
         
         if let balanceText = self.user?.getBalance() {
             print(balanceText)
             self.balanceLabel.text = String(balanceText)
         }
         
     }
     
     func confirmAlert(username: String, message: String) {
         let alertController = UIAlertController(title: "Confirm Payment", message: "Confirm payment of " + message + " ?", preferredStyle: .alert)
         let okAction = UIAlertAction(title: "Ok", style: .default) { (action) in
             self.payResponse(username: username, message: message)
            
         }
         alertController.addAction(okAction)
         alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel))


         self.present(alertController, animated: true, completion: nil)
     }
     
     func payAlert(username: String, message: String) {
         let alertController = UIAlertController(title: "Payment Received", message:
             username + " paid " + message, preferredStyle: .alert)
         
         let dismissAction = UIAlertAction(title: "Ok", style: .default) { (action) in
             self.payeeResponse(username: username, message: message)

         }
         alertController.addAction(dismissAction)

         self.present(alertController, animated: true, completion: nil)
     }
    
    
    func showRequestAlert(username: String, message: String) {
        let requestAlertController = UIAlertController(title: "Payment Request", message:
            username + " requested " + message, preferredStyle: .alert)
        let acceptAction = UIAlertAction(title: "Accept", style: .default) { (action) in
            self.sendFinalResponse(username: username, message: message)
        }
        
        requestAlertController.addAction(acceptAction)
        requestAlertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel))

        self.present(requestAlertController, animated: true, completion: nil)
    }
}
    
    
    
    
    extension PaymentViewController: MultiPeerDelegate {

        func multiPeer(didReceiveData data: Data, ofType type: UInt32) {
            switch type {
            case DataType.payConfirm.rawValue:
                guard let message = data.convert() as? Dictionary<String, AnyObject> else { return }

                
                if let username = user?.name {
                    let selectedUsers = message["selectedUsers"] as! [String] // probably want to do this by IDs eventually lol
                    
                    print(selectedUsers)
                    
                    if selectedUsers.contains(username) {
                    
                        payAlert(username: message["requester"] as! String, message: message["message"] as! String)
                        }
                    
                }
                    
                    break
                
            case DataType.finalRequest.rawValue:
                guard let message = data.convert() as? Dictionary<String, AnyObject> else { return }
                
                
                if let username = user?.name {
                    let selectedUsers = message["selectedUsers"] as! [String] // probably want to do this by IDs eventually lol
                    
                    if selectedUsers.contains(username) {
                        showRequestAlert(username: message["requester"] as! String, message: message["message"] as! String)
                    }
                    
                }
                
                
                break
            case DataType.finalResponse.rawValue:
                guard let message = data.convert() as? Dictionary<String, String> else { return }

                if let username = user?.name {
                    if let amount = message["message"] {
                    if username == message["requester"] {
                    
                                    
                        let amountNumber = Double(amount)!
                        
                        
                        self.user?.addBalance(change: amountNumber)
                        
                        if let balanceText = self.user?.getBalance() {
                            print(balanceText)
                            self.balanceLabel.text = String(balanceText)
                        }
                        
                        }
                    }
                    
                }
            
            default:
                break
            }
        }

        func multiPeer(connectedDevicesChanged devices: [String]) {
            self.nearbyUsers = MultiPeer.instance.connectedDeviceNames; //
            self.tableView.reloadData()
        }
    }


    extension PaymentViewController: UITextFieldDelegate {
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }

