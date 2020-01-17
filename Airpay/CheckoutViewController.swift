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
        let stackView = UIStackView(arrangedSubviews: [cardTextField, payButton])
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
                return
            }
            let tokenID = token.tokenId
            // Send the token identifier to your server...
        }
    }
}
