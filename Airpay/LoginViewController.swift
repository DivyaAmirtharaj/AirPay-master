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
        // Do any additional setup after loading the view.
        nameTextField.delegate = self
        
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
        
//        guard let button = sender as? UIButton, button == continueButton else {
//            os_log("The continue button was not pressed, cancelling", log: OSLog.default, type: .debug)
//            return
//        }
        
        let destController = segue.destination as! PaymentViewController
        
        
        
        let name = nameTextField.text ?? ""
        
        print("Saving: " + name)
        
        user = User(name: name)
        
        destController.user = user
    }
    
    // MARK: Private Methods
    private func updateContinueButtonState() {
        let text = nameTextField.text ?? ""
        continueButton.isEnabled = !text.isEmpty
    }

}

