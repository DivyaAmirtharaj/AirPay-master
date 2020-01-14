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
}



class PaymentViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var requestButton: UIButton!
    @IBOutlet weak var payButton: UIButton!
    
    var user: User?
    

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
            MultiPeer.instance.send(object: "-$" + message, type: DataType.message.rawValue)
            }
        
    }
    
    @IBAction func didPressPayButton(_ sender: Any) {
        
        // Device will stop advertising/browsing until after MultiPeer has sent data
        MultiPeer.instance.stopSearching()
        
        defer {
            MultiPeer.instance.autoConnect()
            }
        
        if let message = textField.text {
            MultiPeer.instance.send(object: "+$" + message, type: DataType.message.rawValue)
            }
        }
    }
    
    
    extension PaymentViewController: MultiPeerDelegate {

        func multiPeer(didReceiveData data: Data, ofType type: UInt32) {
            switch type {
            case DataType.message.rawValue:
                guard let message = data.convert() as? String else { return }
                textField.text = message
                break
            
            default:
                break
            }
        }

        func multiPeer(connectedDevicesChanged devices: [String]) {
            print("Connected devices changed: \(devices)")
        }
    }

    extension PaymentViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    // Local variable inserted by Swift 4.2 migrator.
    let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

            
            if let pickedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
               // imageView.image = pickedImage
            }
            
            dismiss(animated: true, completion: nil)
        }

    }

    extension PaymentViewController: UITextFieldDelegate {
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }

    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }

    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }

