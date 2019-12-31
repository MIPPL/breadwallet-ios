//
//  Transaction.swift
//  breadwallet
//
//  Created by Ehsan Rezaie on 2018-01-13.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import Foundation

struct HomeTitheViewModel {
    var currency : CurrencyDef
    let title: String
}

struct TitheRowModel   {
    let churchID: String
    let address: String
    let name: String
    let organizationType: String
    let dateAdded: TimeInterval
    let timeStamp: TimeInterval
    let CPK: String
    let signature: String
    let vote: String
    
    init(churchID: String, address: String, name: String, organizationType: String, timeStamp: TimeInterval )  {
        self.churchID = churchID
        self.address = address
        self.name = name
        self.organizationType = organizationType
        self.timeStamp = timeStamp
        self.dateAdded = 0
        self.CPK = ""
        self.signature = ""
        self.vote = ""
    }
}
