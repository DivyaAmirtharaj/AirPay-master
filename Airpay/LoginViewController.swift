//
//  ViewController.swift
//  Airpay
//
//  Created by Isabelle on 1/13/20.
//  Copyright © 2020 airpay. All rights reserved.
//

import UIKit
import os.log

class LoginViewController: UIViewController, UITextFieldDelegate {
    // MARK: Properties
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    
    
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadUser()
        if let current_user = self.user {
                   os_log("Loaded user: ", log: OSLog.default, type: .debug)
                   print(current_user.name)
                   
                   self.user = current_user
                   
                   
                   let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            
            
                   let viewController2 = storyBoard.instantiateViewController(withIdentifier: "PaymentViewController") as! PaymentViewController
            
                    viewController2.modalPresentationStyle = .fullScreen
                    viewController2.modalTransitionStyle = .crossDissolve
            
                    viewController2.user = current_user
                   self.present(viewController2, animated: true, completion: nil)
               } else {
                   os_log("Did not load user.", log: OSLog.default, type: .debug)
                   nameTextField.delegate = self
               }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        continueButton.isEnabled = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateContinueButtonState()
        navigationItem.title = textField.text
    }
    
    // MARK: Navigation
    @IBAction func onContinueButton(_ sender: Any) {
        
        performSegue(withIdentifier: "toPaymentSegue", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        let destController = segue.destination as! PaymentViewController
        
            let name = nameTextField.text ?? ""
            
            print("Saving: " + name)
            
            self.user = User(name: name)
            saveUserToServer()
            
            destController.user = user
    }
    
    // MARK: Private Methods
    private func updateContinueButtonState() {
        let text = nameTextField.text ?? ""
        continueButton.isEnabled = !text.isEmpty
    }
    

    private func saveUser() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self.user, toFile: User.ArchiveURL.path)
        
        if isSuccessfulSave {
            os_log("User successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save user...", log: OSLog.default, type: .error)
        }
        
    }
    
    private func loadUser() {
        
        if let user = NSKeyedUnarchiver.unarchiveObject(withFile: User.ArchiveURL.path) as? User {
            self.user = user
            
            if user.oid != "" {
                print("found oid: " + user.oid)
                
                loadUserFromServer(oid: user.oid)
            } else {
                print("else we saving")
                
                saveUserToServer()
            
            }
        }
        
    }
    
    private func saveUserToServer() {
        
        if let current_user = self.user {
        
            let session = URLSession.shared
            
            guard let url = URL(string: "https://frozen-coast-06188.herokuapp.com/users") else {
                print("ANDIOOP3")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Powered by Swift!", forHTTPHeaderField: "X-Powered-By")
            
            let json = [
                "name": current_user.name,
                "balance": String(current_user.balance)
                ]
            print(json)
                
            let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
            

            
            request.httpBody = jsonData
            
            let (data, response, error) = synchronousUploadTask(session: session, request: request, data: jsonData)

            if let response = response {
                print(response)
            }
            if let data = data {
                do {
                    let responsejson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSDictionary
                    let idObj = responsejson["_id"] as! NSDictionary
                    
                    let oid: String = idObj["$oid"] as! String
                    print(oid)
                    self.user?.setOid(oid: oid)
                    
                } catch {
                    print(error)
                }
            }
            
            if let error = error {
                print(error)
            }
                
            saveUser()
        }
    }
    
    private func loadUserFromServer(oid: String) {
        
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
                
                if let current_user = self.user {
                
                    current_user.balance = responsejson["balance"] as! Double
                }
            } catch {
                print(error)
            }
        }
        if let error = error {
            print(error)
        }
        
    }
        
    
    func synchronousDataTask(session: URLSession, request: URLRequest) -> (Data?, URLResponse?, Error?) {
        var data: Data?, response: URLResponse?, error: Error?

        let semaphore = DispatchSemaphore(value: 0)

        session.dataTask(with: request) {
            data = $0; response = $1; error = $2
            semaphore.signal()
            }.resume()

        semaphore.wait()

        return (data, response, error)
    }
    
    func synchronousUploadTask(session: URLSession, request: URLRequest, data: Data?) -> (Data?, URLResponse?, Error?) {
        var data: Data?, response: URLResponse?, error: Error?

        let semaphore = DispatchSemaphore(value: 0)

        session.uploadTask(with: request, from: data) {
            data = $0; response = $1; error = $2
            semaphore.signal()
            }.resume()

        semaphore.wait()

        return (data, response, error)
    }
    

}



