//
//  User.swift
//  Airpay
//
//  Created by Isabelle on 1/13/20.
//  Copyright © 2020 airpay. All rights reserved.
//

import UIKit
import os.log

class User {
    // MARK: Properties
    
    var name: String
    var balance: Int
    
    init?(name: String) {
        guard !name.isEmpty else {
            return nil
        }
        
        self.name = name
        self.balance = 0
    }
}
