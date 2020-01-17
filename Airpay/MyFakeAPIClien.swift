//
//  MyFakeAPIClien.swift
//  Airpay
//
//  Created by Divya Amirtharaj on 1/17/20.
//  Copyright © 2020 airpay. All rights reserved.
//

import Foundation
import Stripe

class MyFakeAPIClien: NSObject, STPCustomerEphemeralKeyProvider {
        
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        
        let dictionary: NSDictionary = [
            "helloString" : "Hello, World!",
            "magicNumber" : 42        ]
        
        completion(dictionary as? [AnyHashable : Any], nil)
    }
}
