//
//  PaymentController.swift
//  Airpay
//
//  Created by Isabelle on 1/13/20.
//  Copyright © 2020 airpay. All rights reserved.
//

import UIKit

class PaymentViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var nameLabel: UILabel!
    
    var user: User?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let nameText = user?.name {
            print(nameText)
            
            nameLabel.text = nameText
        }
        
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
