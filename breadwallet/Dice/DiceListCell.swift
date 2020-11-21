//
//  DiceListCell.swift
//  breadwallet
//
//  Created by MIP on 20/11/2020.
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import UIKit

class DiceListCell: UITableViewCell {

     // MARK: - Views
        
        private let timestamp = UILabel(font: .customBody(size: 16.0), color: .darkText)
        private let diceType = UILabel(font: .customBody(size: 14.0), color: .primaryText)
        private let dice1 = UILabel(font: .customBody(size: 14.0), color: .primaryText)
        private let dice2 = UILabel(font: .customBody(size: 14.0), color: .primaryText)
        private let selectedOutcome = UILabel(font: .customBody(size: 14.0), color: .primaryText)
        private let result = UILabel(font: .customBody(size: 14.0), color: .primaryText)
        private let betAmount = UILabel(font: .customBody(size: 14.0), color: .primaryText)
        private let payoutAmount = UILabel(font: .customBold(size: 18.0))
        private let separator = UIView(color: .separatorGray)
        
        // MARK: Vars
        private var viewModel: BetDiceGamesEntity!
        
        // MARK: - Init
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupViews()
        }
        
        func setDiceBet(_ viewModel: BetDiceGamesEntity, isSyncing: Bool ) {
            self.viewModel = viewModel
            
            diceType.text = viewModel.diceGameType.description
            betAmount.text = String.init(format: "%@ = %.f", S.Dice.Bet, viewModel.amount)
            dice1.text = String.init(format: "%@ 1 = %d", S.Dice.Dice, viewModel.dice1)
            dice2.text = String.init(format: "%@ 2 = %d", S.Dice.Dice, viewModel.dice2)
            result.text = String.init(format: "%@ = %d", S.Dice.Result, viewModel.result)
            selectedOutcome.text = viewModel.selectedOutcomeText
            payoutAmount.attributedText = viewModel.getAttrPayoutAmount()
            timestamp.text = viewModel.shortBetTimestamp
        }
        
        // MARK: - Private
        
        private func setupViews() {
            addSubviews()
            addConstraints()
            setupStyle()
        }
        
        private func addSubviews() {
            contentView.addSubview(timestamp)
            contentView.addSubview(diceType)
            contentView.addSubview(dice1)
            contentView.addSubview(dice2)
            contentView.addSubview(selectedOutcome)
            contentView.addSubview(result)
            contentView.addSubview(betAmount)
            contentView.addSubview(payoutAmount)
            contentView.addSubview(separator)
        }
        
        private func addConstraints() {
            timestamp.constrain([
                timestamp.topAnchor.constraint(equalTo: contentView.topAnchor, constant: C.padding[1]),
                timestamp.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: C.padding[2])])
            descriptionLabel.constrain([
                descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,constant: C.padding[1]),
                descriptionLabel.trailingAnchor.constraint(equalTo: timestamp.trailingAnchor)])
            pendingConstraints = [
                descriptionLabel.centerYAnchor.constraint(equalTo: status.centerYAnchor),
                descriptionLabel.leadingAnchor.constraint(equalTo: status.trailingAnchor, constant: C.padding[1]),
                descriptionLabel.heightAnchor.constraint(equalToConstant: 48.0)]
            completeConstraints = [
                descriptionLabel.topAnchor.constraint(equalTo: timestamp.bottomAnchor),
                descriptionLabel.leadingAnchor.constraint(equalTo: timestamp.leadingAnchor),]
            status.constrain([
                status.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                status.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: C.padding[2])])
            amount.constrain([
                amount.topAnchor.constraint(equalTo: contentView.topAnchor),
                amount.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                amount.leadingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor, constant: C.padding[6]),
                amount.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -C.padding[2])])
            separator.constrainBottomCorners(height: 0.5)
        }
        
        private func setupStyle() {
            selectionStyle = .none
            payoutAmount.textAlignment = .right
            payoutAmount.setContentHuggingPriority(.required, for: .horizontal)
            timestamp.setContentHuggingPriority(.required, for: .vertical)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
