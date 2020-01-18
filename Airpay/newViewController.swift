//
//  newViewController.swift
//  Airpay
//
//  Created by Divya Amirtharaj on 1/18/20.
//  Copyright © 2020 airpay. All rights reserved.
//

import Foundation
import UIKit

class newViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        label.text =  String(MemoryDataStore.getInstance().count)
        
    }
}
