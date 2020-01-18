//
//  MemoryDataStore.swift
//  Airpay
//
//  Created by Divya Amirtharaj on 1/18/20.
//  Copyright © 2020 airpay. All rights reserved.
//

import Foundation

class MemoryDataStore {
    static var instance: MemoryDataStore? = nil
    
    var count: Int = 0
    var name: String = ""
    
    static func instantiate() {
        let instance = MemoryDataStore()
        MemoryDataStore.instance = instance
    }
    
    static func getInstance() -> MemoryDataStore {
        if MemoryDataStore.instance == nil {
            MemoryDataStore.instantiate()
        }
        return MemoryDataStore.instance!
    }
    
    init() {
        
    }
}
