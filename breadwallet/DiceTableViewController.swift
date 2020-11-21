//
//  DiceTableViewController.swift
//  breadwallet
//
//  Created by MIP on 21/11/2020.
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import UIKit
import SafariServices

private let promptDelay: TimeInterval = 0.6
private let minuteInterval: TimeInterval = 60

class DiceTableViewController : UITableViewController, Subscriber, Trackable {

    //MARK: - Public
    init(currency: CurrencyDef, walletManager: WalletManager, didSelectBet: @escaping ([BetDiceGamesEntity], Int) -> Void) {
        self.currency = currency
        self.walletManager = walletManager
        self.didSelectBet = didSelectBet
        self.isBtcSwapped = Store.state.isBtcSwapped
        super.init(nibName: nil, bundle: nil)
        
    }

    let didSelectBet: ([BetDiceGamesEntity], Int) -> Void
    
    func doFilter()    {
        diceTransactions = filters.reduce(allDiceTransactions, { $0.filter($1) })
        self.reload()
    }
    
    // searchbar filters
    var filters: [DiceFilter] = [] {
        didSet {
            doFilter()
        }
    }
    
    //MARK: - Private
    private let walletManager: WalletManager
    private let currency: CurrencyDef
    
    private let headerCellIdentifier = "HeaderCellIdentifier"
    private let diceCellIdentifier = "DiceCellIdentifier"
    private var diceTransactions: [BetDiceGamesEntity] = []
    private var allDiceTransactions: [BetDiceGamesEntity] = [] {
        didSet { diceTransactions = allDiceTransactions }
    }
    private var isBtcSwapped: Bool {
        didSet { reload() }
    }
    private var rate: Rate? {
        didSet { reload() }
    }
    private let emptyMessage = UILabel.wrapping(font: .customBody(size: 16.0), color: .grayTextTint)
    
    //TODO:BCH replace with recommend rescan / tx failed prompt
    private var currentPrompt: Prompt? {
        didSet {
            if currentPrompt != nil && oldValue == nil {
                tableView.beginUpdates()
                tableView.insertSections(IndexSet(integer: 0), with: .automatic)
                tableView.endUpdates()
            } else if currentPrompt == nil && oldValue != nil {
                tableView.beginUpdates()
                tableView.deleteSections(IndexSet(integer: 0), with: .automatic)
                tableView.endUpdates()
            }
        }
    }
    private var hasExtraSection: Bool {
        return (currentPrompt != nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(DiceListCell.self, forCellReuseIdentifier: diceCellIdentifier)
        tableView.register(DiceListCell.self, forCellReuseIdentifier: headerCellIdentifier)

        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 80.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = .whiteBackground
        
        emptyMessage.textAlignment = .center
        emptyMessage.text = S.TransactionDetails.emptyMessage
        
        setContentInset()

        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        Store.subscribe(self,
                        selector: { $0.isBtcSwapped != $1.isBtcSwapped },
                        callback: { self.isBtcSwapped = $0.isBtcSwapped })
        Store.subscribe(self,
                        selector: { $0[self.currency]?.currentRate != $1[self.currency]?.currentRate},
                        callback: {
                            self.rate = $0[self.currency]?.currentRate
        })
        Store.subscribe(self, selector: { $0[self.currency]?.maxDigits != $1[self.currency]?.maxDigits }, callback: {_ in
            self.reload()
        })
        
        Store.subscribe(self, selector: { $0[self.currency]?.recommendRescan != $1[self.currency]?.recommendRescan }, callback: { _ in
            //TODO:BCH show failed tx
        })
        
        Store.subscribe(self, name: .txMemoUpdated(""), callback: {
            guard let trigger = $0 else { return }
            if case .txMemoUpdated(let txHash) = trigger {
                self.reload(txHash: txHash)
            }
        })
        
        Store.subscribe(self, selector: {
            guard let oldDiceBets = $0[self.currency]?.diceTransactions else { return false }
            guard let newDiceBets = $1[self.currency]?.diceTransactions else { return false }
            return oldDiceBets != newDiceBets },
                        callback: { state in
                            self.allDiceTransactions = state[self.currency]?.diceTransactions ?? [BetDiceGamesEntity]()
                            self.reload()
        })
    }

    var receiveAddress : String {
        return (walletManager.wallet?.allAddresses[0] ?? "")
    }
    
    private func setContentInset() {
        let insets = UIEdgeInsets(top: accountHeaderHeight - 64.0 - (E.isIPhoneX ? 0.0 : 0.0), left: 0, bottom: accountFooterHeight + C.padding[2], right: 0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
    }

    private func reload(txHash: String) {
        self.diceTransactions.enumerated().forEach { i, diceBet in
            if diceBet.txHash == txHash {
                DispatchQueue.main.async {
                    self.tableView.reload(row: i, section: self.hasExtraSection ? 1 : 0)
                }
            }
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return hasExtraSection ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if hasExtraSection && section == 0 {
            return 1
        } else {
            return diceTransactions.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if hasExtraSection && indexPath.section == 0 {
            return headerCell(tableView: tableView, indexPath: indexPath)
        } else {
            return diceCell(tableView: tableView, indexPath: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if hasExtraSection && section == 1 {
            return C.padding[1]
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat( 70 )
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if hasExtraSection && section == 1 {
            return UIView(color: .clear)
        } else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if hasExtraSection && indexPath.section == 0 { return }
        didSelectBet(diceTransactions, indexPath.row)
    }

    public func reload() {
        tableView.reloadData()
        if diceTransactions.count == 0 {
            if emptyMessage.superview == nil {
                tableView.addSubview(emptyMessage)
                emptyMessage.constrain([
                    emptyMessage.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
                    emptyMessage.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -accountHeaderHeight),
                    emptyMessage.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -C.padding[2]) ])
            }
        } else {
            emptyMessage.removeFromSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - Cell Builders
extension DiceTableViewController {

    private func headerCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: headerCellIdentifier, for: indexPath)
        if let containerCell = cell as? TxListCell {
            if let prompt = currentPrompt {
                containerCell.contentView.addSubview(prompt)
                prompt.constrain(toSuperviewEdges: nil)
            }
        }
        return cell
    }

    private func diceCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: diceCellIdentifier, for: indexPath) as! DiceListCell
        let viewModel = diceTransactions[indexPath.row]
        cell.setDiceBet(viewModel, isSyncing: currency.state?.syncState != .success)
        return cell
    }
}

