//
//  DiceDetailDataSource.swift
//  Wagerr Pro
//
//  Created by MIP on 2020-11-21.
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import UIKit

class DiceDetailDataSource: NSObject {
    
    // MARK: - Types
    
    enum Field: String {
        case transactionId
        case diceType
        case betAmount
        case selectedOutcome
        case dice1
        case dice2
        case result
        case payoutAmount
        case payoutTxHash
        case timestamp
        
        var cellType: UITableViewCell.Type {
            switch self {
            case .payoutTxHash, .transactionId:
                return TxAddressCell.self
            default:
                return TxLabelCell.self
            }
        }
        
        func registerCell(forTableView tableView: UITableView) {
            tableView.register(cellType, forCellReuseIdentifier: self.rawValue)
        }
    }
    
    // MARK: - Vars
    
    fileprivate var fields: [Field]
    fileprivate let viewModel: BetDiceGamesEntity
    
    // MARK: - Init
    
    init(viewModel: BetDiceGamesEntity) {
        self.viewModel = viewModel
        
        // define visible rows and order
        fields = [.transactionId, .timestamp, .diceType, .betAmount, .selectedOutcome, .dice1, .dice2, .result, .payoutAmount, .payoutTxHash ]
    }
    
    func registerCells(forTableView tableView: UITableView) {
        fields.forEach { $0.registerCell(forTableView: tableView) }
    }
    
    fileprivate func title(forField field: Field) -> String {
        switch field {
        case .transactionId:
            return S.Dice.transactionId
        case .diceType:
            return S.Dice.diceTypeTitle
        case .betAmount:
            return S.Dice.betAmountTitle
        case .selectedOutcome:
            return S.Dice.SelectedOutcome
        case .dice1:
            return String.init(format: "%@ 1", S.Dice.Dice)
        case .dice2:
            return String.init(format: "%@ 2", S.Dice.Dice)
        case .result:
            return S.Dice.resultTitle
        case .payoutAmount:
            return S.Dice.payoutAmountTitle
        case .payoutTxHash:
            return S.Dice.payoutHashTitle
        case .timestamp:
            return S.Dice.timestampTitle
        default:
            return ""
        }
    }
}

// MARK: -
extension DiceDetailDataSource: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let field = fields[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: field.rawValue,
                                                 for: indexPath)
        
        if let rowCell = cell as? TxAddressCell {
            rowCell.title = title(forField: field)
        }
        
        if let rowCell = cell as? TxLabelCell {
            rowCell.title = title(forField: field)
        }

        switch field {
        case .transactionId:
            let transactionCell = cell as! TxAddressCell
            transactionCell.set(address: viewModel.txHash)
        case .diceType:
            let diceTypeCell = cell as! TxLabelCell
            diceTypeCell.value = viewModel.diceGameType.description
        case .betAmount:
            let betAmountCell = cell as! TxLabelCell
            betAmountCell.value = viewModel.amountTx
        case .selectedOutcome:
            let selectedOutcomeCell = cell as! TxLabelCell
            selectedOutcomeCell.value = viewModel.selectedOutcomeText
        case .dice1:
            let dice1Cell = cell as! TxLabelCell
            dice1Cell.value = String(viewModel.dice1)
        case .dice2:
            let dice2Cell = cell as! TxLabelCell
            dice2Cell.value = String(viewModel.dice2)
        case .result:
            let resultCell = cell as! TxLabelCell
            resultCell.value = String(viewModel.result)
        case .payoutAmount:
            let payoutAmountCell = cell as! TxLabelCell
            payoutAmountCell.attrValue = viewModel.getAttrPayoutAmount()
        case .payoutTxHash:
            let payoutHashCell = cell as! TxAddressCell
            payoutHashCell.set(address: viewModel.payoutTxHash)
        case .timestamp:
            let timestampCell = cell as! TxLabelCell
            resultCell.value = viewModel.longBetTimestamp        
        return cell

    }
    
}
