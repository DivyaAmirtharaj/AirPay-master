//
//  CheckoutViewController.swift
//  Airpay
//
//  Created by Divya Amirtharaj on 1/16/20.
//  Copyright © 2020 airpay. All rights reserved.
//

import Foundation
import Stripe


class CheckoutViewController: UIViewController {
    
    var paymentContext: STPPaymentContext
    let customerContext = STPCustomerContext(keyProvider: MyAPIClient())
    
    let theme: STPTheme
    let tableView: UITableView
    let paymentRow: CheckoutRowView
    let shippingRow: CheckoutRowView?
    let totalRow: CheckoutRowView
    let buyButton: BuyButton
    let rowHeight: CGFloat = 52
    let activityIndicator = UIActivityIndicatorView(style: .gray)
    let numberFormatter: NumberFormatter
    let country: String
    //var products: [Product]
    var paymentInProgress: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                if self.paymentInProgress {
                    self.activityIndicator.startAnimating()
                    self.activityIndicator.alpha = 1
                    self.buyButton.alpha = 0
                } else {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.alpha = 0
                    self.buyButton.alpha = 1
                }
            }, completion: nil)
        }
    }
    
    
    init() {
        self.paymentContext = STPPaymentContext(customerContext: customerContext)
        super.init(nibName: nil, bundle: nil)
        self.paymentContext.delegate = self as! STPPaymentContextDelegate
        self.paymentContext.hostViewController = self
        self.paymentContext.paymentAmount = 5000 // This is in cents, i.e. $50 USD
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
