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



class PaymentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIApplicationDelegate, UIResponder {

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
    
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let url = self.baseURL.appendingPathComponent("ephemeral_keys")
        Alamofire.request(url, method: .post, parameters: [
            "api_version": apiVersion,"customer_id": yourObject.id
            ])
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    completion(json as? [String: AnyObject], nil)
                case .failure(let error):
                    completion(nil, error)
                }
        }
    }
    
    //let customerContext = STPCustomerContext(keyProvider: MyAPIClient())
    
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
        
        
        
        if let message = textField.text {
            if let username = user?.name {
                if !message.isEmpty {
                    let obj = ["message": message, "requester": username]
                MultiPeer.instance.send(object: obj, type: DataType.initialRequest.rawValue)
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
    
    
    // MARK: Helpers
    func sendInitialResponse(requester: String) {
        if let username = user?.name {
            
            let obj = ["requester": requester,
                       "responder": username] as [String : Any]
            
            MultiPeer.instance.send(object: obj, type: DataType.initialResponse.rawValue)
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
   
    func payeeResponse(username: String, message: String) {
         if let responder = user?.name {
                        
            let messageNumber = Double(message)!
            self.user?.addBalance(change: messageNumber)
            
            if let balanceText = self.user?.getBalance() {
                print(balanceText)
                self.balanceLabel.text = String(balanceText)
            }
        }
    }
    
    func confirmAlert(username: String, message: String) {
        let alertController = UIAlertController(title: "Confirm Payment", message: "Confirm payment of " + message + " ?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default) { (action) in
            self.payResponse(username: username, message: message)
            
            let obj = ["message": message, "requester": username] as [String : String]
            MultiPeer.instance.send(object: obj, type: DataType.payConfirm.rawValue)
        }
        alertController.addAction(okAction)

        self.present(alertController, animated: true, completion: nil)
    }
    
    func payAlert(username: String, message: String) {
        let alertController = UIAlertController(title: "Payment Received", message:
            username + " paid you " + message, preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: "Ok", style: .default) { (action) in
            self.payeeResponse(username: username, message: message)

        }
        alertController.addAction(dismissAction)

        self.present(alertController, animated: true, completion: nil)
    }
    
    func showAlert(username: String, message: String) {
        let alertController = UIAlertController(title: "Initial", message:
            username + " requested " + message, preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default) { (action) in
            self.sendInitialResponse(requester: username)

        }
        
    
        alertController.addAction(dismissAction)

        self.present(alertController, animated: true, completion: nil)
    }
    
    func showRequestAlert(username: String, message: String) {
        
        print("gotta show request alert")
        print(message)
        
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
            case DataType.initialRequest.rawValue:
                guard let message = data.convert() as? Dictionary<String, String> else { return }
                textField.text = message["message"]
                
                showAlert(username: message["requester"] ?? "Unknown user", message: message["message"] ?? "Unknown value")
                

                break
            
            case DataType.payConfirm.rawValue:
            guard let message = data.convert() as? Dictionary<String, String> else { return }
            textField.text = message["message"]
            
            payAlert(username: message["requester"] ?? "Unknown user", message: message["message"] ?? "Unknown value")
                
                break
                
                
            case DataType.initialResponse.rawValue:
                guard let message = data.convert() as? Dictionary<String, String> else { return }
                
                if let username = user?.name {
                    if let requester = message["requester"] {
                        if let responder = message["responder"] {
                            if requester == username {
                                //showAlert(username: username, message: "RECEIVED " + responder)
                                
                                print("Received: " + responder)
                                
                                if !nearbyUsers.contains(responder) {
                                    nearbyUsers.append(responder)
                                }
                                
                                sendFinalRequest()
                            }
                            
                        }
                    }
                    
                }
                                
                
                    
                    // TODO: Allow user to select which people to request
                
            
                break
            case DataType.finalRequest.rawValue:
                guard let message = data.convert() as? Dictionary<String, AnyObject> else { return }
                textField.text = message["message"] as? String
                
                
                if let username = user?.name {
                    let selectedUsers = message["selectedUsers"] as! [String]
                    
                    print(selectedUsers)
                    
                    if selectedUsers.contains(username) {
                        showRequestAlert(username: message["requester"] as! String, message: message["message"] as! String)
                    }
                    
                }
                
                
                break
            case DataType.finalResponse.rawValue:
                guard let message = data.convert() as? Dictionary<String, String> else { return }
                
                print(message)
                
                textField.text = message["message"]
                
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


