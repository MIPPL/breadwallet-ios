//
//  DiceSearchHeader.swift
//  Wagerr Pro
//
//  Created by MIP on 20/11/2020.
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import UIKit

enum DiceSearchFilterType {
    case equal
    case notequal
    case over
    case under
    case even
    case odds
    case text(String)

    var description: String {
        switch self {
        case .equal:
            return S.Dice.Equal
        case .notequal:
            return S.Dice.NotEqual
        case .over:
            return S.Dice.Over
        case .under:
            return S.Dice.Under
        case .even:
            return S.Dice.Even
        case .odds:
            return S.Dice.Odds
        case .text(_):
            return ""
        }
    }

    var filter: DiceFilter {
        switch self {
        case .equal:
            return { $0.diceGameType == BetDiceGameType.EQUAL }
        case .notequal:
            return { $0.diceGameType == BetDiceGameType.NOT_EQUAL }
        case .over:
            return { $0.diceGameType == BetDiceGameType.TOTAL_OVER }
        case .under:
            return { $0.diceGameType == BetDiceGameType.TOTAL_UNDER}
        case .even:
            return { $0.diceGameType == BetDiceGameType.EVEN }
        case .odds:
            return { $0.diceGameType == BetDiceGameType.ODDS }
        case .text(let text):
            return { diceInfo in
                let loweredText = text.lowercased()
                if diceInfo.txHash.lowercased().contains(loweredText)
                || diceInfo.payoutTxHash.lowercased().contains(loweredText) {
                    return true
                }
                return false
            }
        }
    }
}

extension DiceSearchFilterType : Equatable {}

func ==(lhs: DiceSearchFilterType, rhs: DiceSearchFilterType) -> Bool {
    switch (lhs, rhs) {
    case (.equal, .equal):
        return true
    case (.notequal, .notequal):
        return true
    case (.over, .over):
        return true
    case (.under, .under):
        return true
    case (.even, .even):
        return true
    case (.odds, .odds):
        return true
    case (.text(_), .text(_)):
        return true
    default:
        return false
    }
}

typealias DiceFilter = (BetDiceGamesEntity) -> Bool

class DiceSearchHeaderView : UIView {

    init() {
        super.init(frame: .zero)
    }

    var didCancel: (() -> Void)?
    var didChangeFilters: (([DiceFilter]) -> Void)?
    var hasSetup = false

    func triggerUpdate() {
        didChangeFilters?(filters.map { $0.filter })
    }

    private let searchBar = UISearchBar()
    private let equal = ShadowButton(title: S.Dice.Equal, type: .search, YCompressionFactor: 1.0)
    private let notequal = ShadowButton(title: S.Dice.NotEqual, type: .search, YCompressionFactor: 1.0)
    private let over = ShadowButton(title: S.Dice.Over, type: .search, YCompressionFactor: 1.0)
    private let under = ShadowButton(title: S.Dice.Under, type: .search, YCompressionFactor: 1.0)
    private let even = ShadowButton(title: S.Dice.Even, type: .search, YCompressionFactor: 1.0)
    private let odds = ShadowButton(title: S.Dice.Odds, type: .search, YCompressionFactor: 1.0)

    private let cancel = UIButton(type: .system)
    fileprivate var filters: [DiceSearchFilterType] = [] {
        didSet {
            didChangeFilters?(filters.map { $0.filter })
        }
    }

    private let equalFilter: DiceFilter = { return $0.diceGameType == BetDiceGameType.EQUAL }
    private let notequalFilter: DiceFilter = { return $0.diceGameType == BetDiceGameType.NOT_EQUAL }
    private let overFilter: DiceFilter = { return $0.diceGameType == BetDiceGameType.TOTAL_OVER }
    private let underFilter: DiceFilter = { return $0.diceGameType == BetDiceGameType.EQUAL }
    private let evenFilter: DiceFilter = { return $0.diceGameType == BetDiceGameType.EVEN }
    private let oddsFilter: DiceFilter = { return $0.diceGameType == BetDiceGameType.ODDS }

    override func layoutSubviews() {
        guard !hasSetup else { return }
        setup()
        hasSetup = true
    }

    private func setup() {
        addSubviews()
        addFilterButtons()
        addConstraints()
        setData()
    }

    private func addSubviews() {
        addSubview(searchBar)
        addSubview(cancel)
    }

    private func addConstraints() {
        cancel.setTitle(S.Button.cancel, for: .normal)
        let titleSize = NSString(string: cancel.titleLabel!.text!).size(withAttributes: [NSAttributedStringKey.font : cancel.titleLabel!.font])
        cancel.constrain([
            cancel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            cancel.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            cancel.widthAnchor.constraint(equalToConstant: titleSize.width + C.padding[4])])
        searchBar.constrain([
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[1]),
            searchBar.topAnchor.constraint(equalTo: topAnchor, constant: E.isIPhoneXOrBetter ? C.padding[4] : C.padding[2]),
            searchBar.trailingAnchor.constraint(equalTo: cancel.leadingAnchor, constant: -C.padding[1]) ])
    }

    private func setData() {
        backgroundColor = .grayBackground
        searchBar.backgroundImage = UIImage()
        searchBar.delegate = self
        cancel.tap = { [weak self] in
            self?.didChangeFilters?([])
            self?.searchBar.resignFirstResponder()
            self?.didCancel?()
        }
        equal.isToggleable = true
        notequal.isToggleable = true
        over.isToggleable = true
        under.isToggleable = true
        even.isToggleable = true
        odds.isToggleable = true

        equal.tap = { [weak self] in
            guard let myself = self else { return }
            myself.toggleFilterType(.equal)
        }

        notequal.tap = { [weak self] in
            guard let myself = self else { return }
            myself.toggleFilterType(.notequal)
        }

        over.tap = { [weak self] in
            guard let myself = self else { return }
            myself.toggleFilterType(.over)
        }
        
        under.tap = { [weak self] in
            guard let myself = self else { return }
            myself.toggleFilterType(.under)
        }

        even.tap = { [weak self] in
            guard let myself = self else { return }
            myself.toggleFilterType(.even)
        }

        odds.tap = { [weak self] in
            guard let myself = self else { return }
            myself.toggleFilterType(.odds)
        }
    }

    @discardableResult private func toggleFilterType(_ filterType: DiceSearchFilterType) -> Bool {
        if let index = filters.index(of: filterType) {
            filters.remove(at: index)
            return false
        } else {
            filters.append(filterType)
            return true
        }
    }

    private func addFilterButtons() {
        /* if #available(iOS 9, *) {
            let stackView = UIStackView()
            addSubview(stackView)
            stackView.distribution = .fillProportionally
            stackView.spacing = C.padding[1]
            stackView.constrain([
                stackView.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor),
                stackView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: C.padding[1]),
                stackView.trailingAnchor.constraint(equalTo: cancel.trailingAnchor) ])
            stackView.addArrangedSubview(sent)
            stackView.addArrangedSubview(received)
            stackView.addArrangedSubview(pending)
            stackView.addArrangedSubview(complete)
            stackView.addArrangedSubview(bethistory)
            stackView.addArrangedSubview(payout)
        } else {
            */
            addSubview(equal)
            addSubview(notequal)
            addSubview(over)
            addSubview(under)
            addSubview(even)
            addSubview(odds)
            equal.constrain([
                equal.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor, constant: C.padding[2]),
                equal.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: C.padding[2]) ])
            notequal.constrain([
                notequal.leadingAnchor.constraint(equalTo: equal.trailingAnchor, constant: C.padding[1]),
                notequal.topAnchor.constraint(equalTo: equal.topAnchor)])
            over.constrain([
                over.leadingAnchor.constraint(equalTo: notequal.trailingAnchor, constant: C.padding[1]),
                over.topAnchor.constraint(equalTo: notequal.topAnchor)])
            under.constrain([
                under.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor, constant: C.padding[2]),
                under.topAnchor.constraint(equalTo: equal.bottomAnchor, constant: C.padding[2]) ])
            even.constrain([
                even.leadingAnchor.constraint(equalTo: under.trailingAnchor, constant: C.padding[1]),
                even.topAnchor.constraint(equalTo: under.topAnchor)])
            odds.constrain([
                odds.leadingAnchor.constraint(equalTo: even.trailingAnchor, constant: C.padding[1]),
                odds.topAnchor.constraint(equalTo: even.topAnchor)])
        //}
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DiceSearchHeaderView : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let filter: DiceSearchFilterType = .text(searchText)
        if let index = filters.index(of: filter) {
            filters.remove(at: index)
        }
        if searchText != "" {
            filters.append(filter)
        }
    }
}
