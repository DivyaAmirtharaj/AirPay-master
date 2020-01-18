//
//  navigationTestViewController.swift
//  Airpay
//
//  Created by Divya Amirtharaj on 1/18/20.
//  Copyright © 2020 airpay. All rights reserved.
//

import Foundation
import UIKit

class navigationTestViewController: UIViewController, UITextFieldDelegate {
// MARK: Properties
    
    @IBOutlet weak var label: UILabel!
    @IBAction func goTapped(_ sender: Any) {
    performSegue(withIdentifier: "SegueToFirstVC", sender: self)
    }
    
    @IBAction func counterTapped(_ sender: Any) {
        MemoryDataStore.getInstance().count += 1
        self.label.text = "\(MemoryDataStore.getInstance().count)"
    }
    
    override func viewDidLoad() {
        label.text = "\(MemoryDataStore.getInstance().count)"
    }
    
}
