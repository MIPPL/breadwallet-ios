//
//  SimpleUTXO.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-06-14.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import Foundation
import BRCore

struct SimpleUTXO {

    let hash: UInt256
    let index: UInt32
    let script: [UInt8]
    let satoshis: UInt64

    init?(json: [String: Any]) {
        guard let txid = json["tx_hash"] as? String,
            let vout = json["tx_ouput_n"] as? Int,
            let scriptPubKey = json["script"] as? String,
            let satoshis = json["value"] as? UInt64 else { return nil }
        guard let hashData = txid.hexToData,
            let scriptData = scriptPubKey.hexToData else { return nil }

        self.hash = hashData.reverse.uInt256
        self.index = UInt32(vout)
        self.script = [UInt8](scriptData)
        self.satoshis = satoshis
    }
    
    init?( hash: UInt256, index: UInt32, script: [UInt8], satoshis: UInt64) {
        self.hash = hash
        self.index = index
        self.script = script
        self.satoshis = satoshis
    }
}

struct ChainzUtxoItem : Codable {
     let tx_hash : String!
     let tx_ouput_n : UInt32!
     let value : UInt64!
     let confirmations : UInt32!
     let script :String!
     let addr : String!
    
    func ToSimpleUTXO() -> SimpleUTXO?   {
        let ret = SimpleUTXO(hash: (self.tx_hash.hexToData?.reverse.uInt256)!, index: self.tx_ouput_n, script: [UInt8](self.script.hexToData!), satoshis: self.value ) 
        
        return ret
    }
}

struct ChainzObject : Codable {
    var unspent_outputs : [ChainzUtxoItem]!
}
