
//  PaymentController.swift
//  Airpay
//
//  Created by Isabelle on 1/13/20.
//  Copyright © 2020 airpay. All rights reserved.
//

import UIKit
import MultiPeer
import Stripe
import Foundation

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
        
        if let oid = user?.oid {
            print("user oid: " + oid)
            
            loadUserFromServer(oid: oid)
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
    
    //MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        let destController = segue.destination as! CheckoutViewController
        
        destController.user = self.user!
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
                if CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: message)) {
                        print("tis a number")
                    if let username = user?.name {
                confirmAlert(username: username, message: message)
                    }
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
            updateBalanceOnServer()
            if let balanceText = self.user?.getBalance() {
                print(balanceText)
                self.balanceLabel.text = String(balanceText)
                
                if balanceText <= 0 {
                    balanceAlert()
                }
            }
            let obj = ["message": message, "requester": username, "responder": responder] as [String : String]
            MultiPeer.instance.send(object: obj, type: DataType.finalResponse.rawValue)
        }
    }
    
    func payResponse(username: String, message: String) {
          if let username = user?.name {
                         
             let messageNumber = Double(message)!
            self.user?.subtractBalance(change: (Double(self.selectedUsers.count) * messageNumber))
             updateBalanceOnServer()
             if let balanceText = self.user?.getBalance() {
                 print(balanceText)
                 self.balanceLabel.text = String(balanceText)
                
                 if balanceText <= 0 {
                     balanceAlert()
                 }
             }
            
            
            let obj = ["message": message, "requester": username, "selectedUsers": self.selectedUsers] as [String : Any]
             MultiPeer.instance.send(object: obj, type: DataType.payConfirm.rawValue)
             
             
         }
         
         
     }
     func balanceAlert() {
         let alertController = UIAlertController(title: "Balance Low", message:
             "Add more money to your balance", preferredStyle: .alert)
         
         let dismissAction = UIAlertAction(title: "Ok", style: .default) { (action) in
             self.performSegue(withIdentifier: "checkoutSegue", sender: self)

         }
         alertController.addAction(dismissAction)

         self.present(alertController, animated: true, completion: nil)
     }
    
     func payeeResponse(username: String, message: String) {
         let messageNumber = Double(message)!
         self.user?.addBalance(change: messageNumber)
         updateBalanceOnServer()
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
    
    // MARK: Private
    
    private func loadUserFromServer(oid: String) {
        if let user = self.user {
            let session = URLSession.shared
            
            guard let url = URL(string: "https://frozen-coast-06188.herokuapp.com/users/" + oid) else {
                print("ANDIOOP3")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Powered by Swift!", forHTTPHeaderField: "X-Powered-By")
            
            let (data, response, error) = synchronousDataTask(session: session, request: request)
            if let response = response {
                print(response)
            }
            if let data = data {
                do {
                    let responsejson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSDictionary
                    
                        user.balance = responsejson["balance"] as! Double
                        self.balanceLabel.text = String(user.balance)
                        updateBalanceOnServer()
                
                } catch {
                    print(error)
                }
            }
            if let error = error {
                print(error)
            }
            
        }
        
    }
    
    private func updateBalanceOnServer() {
        
        if let user = self.user {
            let session = URLSession.shared

            guard let url = URL(string: "https://frozen-coast-06188.herokuapp.com/users/" + user.oid) else {
                print("ANDIOOP3")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Powered by Swift!", forHTTPHeaderField: "X-Powered-By")
            
            let json = [
                "balance": user.balance
                ] as [String : Any]
            
            print(json)
            
            let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        
            request.httpBody = jsonData
            
            let task = session.uploadTask(with: request, from: jsonData) { data, response, error in
                if let response = response {
                    print(response)
                }
                if let data = data {
                    do {
                        let responsejson = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                        print(responsejson)
                    } catch {
                        print(error)
                    }
                }
            }
            
            task.resume()
            
        }
        
    }
    
    private func synchronousDataTask(session: URLSession, request: URLRequest) -> (Data?, URLResponse?, Error?) {
        var data: Data?, response: URLResponse?, error: Error?

        let semaphore = DispatchSemaphore(value: 0)

        session.dataTask(with: request) {
            data = $0; response = $1; error = $2
            semaphore.signal()
            }.resume()

        semaphore.wait()

        return (data, response, error)
    }
    
    private func formatPrice(price: Double) -> String {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        
        currencyFormatter.locale = Locale.current
        let priceString = currencyFormatter.string(from: NSNumber(value: price))!
        return priceString
        
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
                        updateBalanceOnServer()
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




