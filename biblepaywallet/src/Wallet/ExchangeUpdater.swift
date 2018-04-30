//
//  ExchangeUpdater.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-01-27.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import Foundation

class ExchangeUpdater : Subscriber {

    //MARK: - Public
    init(store: Store, walletManager: WalletManager) {
        self.store = store
        self.walletManager = walletManager
        store.subscribe(self,
                        selector: { $0.defaultCurrencyCode != $1.defaultCurrencyCode },
                        callback: { state in
                            guard let BBPRate = state.rates.first( where: { $0.code == "BBP" }) else { return }
                            guard let BTCRate = state.rates.first( where: { $0.code == state.defaultCurrencyCode }) else { return }
                            let currentRate = Rate(code: "BBP", name: "Biblepay", rate: BTCRate.rate/BBPRate.rate)
                            self.store.perform(action: ExchangeRates.setRate(currentRate))
        })
    }

    func refresh(completion: @escaping () -> Void) {
        walletManager.apiClient?.exchangeRates { rates, error in
            guard let BBPRate = rates.first( where: { $0.code == "BBP" }) else { completion(); return }
            guard let BTCRate = rates.first( where: { $0.code == self.store.state.defaultCurrencyCode }) else { completion(); return }
            let currentRate = Rate(code: "BBP", name: "Biblepay", rate: BTCRate.rate/BBPRate.rate)
            self.store.perform(action: ExchangeRates.setRates(currentRate: currentRate, rates: rates))
            completion()
        }
    }

    //MARK: - Private
    let store: Store
    let walletManager: WalletManager
}
