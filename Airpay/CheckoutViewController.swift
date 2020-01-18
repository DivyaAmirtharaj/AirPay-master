//
//  CheckoutViewController.swift
//  Airpay
//
//  Created by Divya Amirtharaj on 1/16/20.
//  Copyright © 2020 airpay. All rights reserved.
//

import UIKit
import Stripe

class CheckoutViewController: UIViewController {
    
    // MARK: Properties
    var user: User?
    
    lazy var textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Amount to deposit"
        return textField
    }()
    lazy var cardTextField: STPPaymentCardTextField = {
        let cardTextField = STPPaymentCardTextField()
        return cardTextField
    }()
    lazy var payButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 5
        button.backgroundColor = .systemBlue
        button.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        button.setTitle("Pay", for: .normal)
        button.addTarget(self, action: #selector(pay), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let stackView = UIStackView(arrangedSubviews: [textField, cardTextField, payButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalToSystemSpacingAfter: view.leftAnchor, multiplier: 2),
            view.rightAnchor.constraint(equalToSystemSpacingAfter: stackView.rightAnchor, multiplier: 2),
            stackView.topAnchor.constraint(equalToSystemSpacingBelow: view.topAnchor, multiplier: 2),
        ])
    }

    @objc
    func pay() {
        
        print("this was called")
        
        // Create an STPCardParams instance
        let cardParams = STPCardParams()
        cardParams.number = cardTextField.cardNumber
        cardParams.expMonth = cardTextField.expirationMonth
        cardParams.expYear = cardTextField.expirationYear
        cardParams.cvc = cardTextField.cvc

        // Pass it to STPAPIClient to create a Token
        STPAPIClient.shared().createToken(withCard: cardParams) { token, error in
            guard let token = token else {
                // Handle the error
                print(error)
                return
            }
            let tokenID = token.tokenId
            guard let amountText = self.textField.text else {
                print("ANDIOOP2")
                return
            }
            
            guard let user = self.user else {
                print("ANDIOOP4")
                return
            }
                        
            let session = URLSession.shared

            guard let url = URL(string: "https://frozen-coast-06188.herokuapp.com/charge") else {
                print("ANDIOOP3")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Powered by Swift!", forHTTPHeaderField: "X-Powered-By")
            
            let json = [
                "amount": amountText,
                "stripeToken": tokenID,
                "description": "Adding to Airpay balance",
                "userId": user.oid
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
}
