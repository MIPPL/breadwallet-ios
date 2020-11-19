//
//  HomeViewModels.swift
//  breadwallet
//
//  Created by MIP on 24/11/2019.
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import Foundation

struct HomeEventViewModel {
    var currency : CurrencyDef
    let title: String
}

struct HomeSwapViewModel {
    var currency : CurrencyDef
    let title: NSAttributedString
}

struct HomeDiceViewModel {
    var currency : CurrencyDef
    let title: String
}
