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
        if let current_user = loadUser() {
                   os_log("Loaded user: ", log: OSLog.default, type: .debug)
                   print(current_user.name)
                   
                   self.user = current_user
                   
                   
                   let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                   let viewController2 = storyBoard.instantiateViewController(withIdentifier: "PaymentViewController") as! PaymentViewController
            
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
            
            user = User(name: name)
            saveUser()
            
            destController.user = user
    }
    
    // MARK: Private Methods
    private func updateContinueButtonState() {
        let text = nameTextField.text ?? ""
        continueButton.isEnabled = !text.isEmpty
    }
    
    private func saveUser() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(user, toFile: User.ArchiveURL.path)
        
        if isSuccessfulSave {
            os_log("User successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save user...", log: OSLog.default, type: .error)
        }
        
    }
    
    private func loadUser() -> User? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: User.ArchiveURL.path) as? User
    }
    

}

