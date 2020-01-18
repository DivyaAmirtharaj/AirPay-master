//
//  User.swift
//  Airpay
//
//  Created by Isabelle on 1/13/20.
//  Copyright © 2020 airpay. All rights reserved.
//

import UIKit
import os.log

class User: NSObject, NSCoding {
    // MARK: Properties
    var oid: String
    var name: String
    var balance: Double
    
    
    struct PropertyKey {
        static let oid = "oid"
        static let name = "name"
        static let balance = "balance"
    }
    
    //MARK: Archiving Paths
     
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("users")
    
    
    init?(name: String) {
        guard !name.isEmpty else {
            return nil
        }
        self.oid = ""
        self.name = name
        self.balance = 0.00

    }
    
    init?(name: String, oid: String, balance: Double) {
        guard !name.isEmpty else {
            return nil
        }
        
        self.oid = oid
        self.name = name
        self.balance = balance

    }
    
    public func update(balance: Double, oid: String) {
        self.balance = balance
        self.oid = oid
    }
    
    public func addBalance(change: Double) {
        self.balance += change
        print(self.balance)
    }
    
    public func subtractBalance(change: Double) {
        self.balance -= change
    }
    public func getBalance() -> Double{
           return(self.balance)
       }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(oid, forKey: PropertyKey.oid)
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(balance, forKey: PropertyKey.balance)

    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard let name = aDecoder.decodeObject(forKey: PropertyKey.name) as? String else {
            os_log("Unable to decode the name for a User object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let oid = aDecoder.decodeObject(forKey: PropertyKey.oid) as? String else {
            os_log("Unable to decode the oid for a User object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        let balance = aDecoder.decodeDouble(forKey: PropertyKey.balance)
        
        self.init(name: name, oid: oid, balance: balance)

    }
    
}
