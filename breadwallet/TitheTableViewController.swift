//
//  TxDetailViewController.swift
//  breadwallet
//
//  Created by Ehsan Rezaie on 2018-01-18.
//  Copyright © 2018 breadwallet LLC. All rights reserved.
//

import UIKit

class TitheTableViewController : UITableViewController, Subscriber, Trackable, XMLParserDelegate {

    //MARK: - Public
    init(currency: CurrencyDef, walletManager: WalletManager, didSelectTithe: @escaping ([TitheRowModel], Int) -> Void) {
        self.currency = currency
        self.walletManager = walletManager
        self.didSelectTithe = didSelectTithe
        self.isBtcSwapped = Store.state.isBtcSwapped
        super.init(nibName: nil, bundle: nil)
    }

    let didSelectTithe: ([TitheRowModel], Int) -> Void

    var filters: [TitheFilter] = [] {
        didSet {
            churches = filters.reduce(allChurches, { $0.filter($1) })
            tableView.reloadData()
        }
    }

    //MARK: - Private
    private let walletManager: WalletManager
    private let currency: CurrencyDef
    
    private let headerCellIdentifier = "HeaderCellIdentifier"
    private let titheCellIdentifier = "TitheCellIdentifier"
    private var churches: [TitheRowModel] = []
    private var allChurches: [TitheRowModel] = [] {
        didSet { churches = allChurches }
    }
    private var isBtcSwapped: Bool {
        didSet { reload() }
    }
    private var rate: Rate? {
        didSet { reload() }
    }
    private let emptyMessage = UILabel.wrapping(font: .customBody(size: 16.0), color: .grayTextTint)
    
    //MARK: - XML
    var elementName = String()
    var churchID = String()
    var address = String()
    var name = String()
    var organizationType = String()
    var timeStamp = TimeInterval(0)
    
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

        tableView.register(TitheListCell.self, forCellReuseIdentifier: titheCellIdentifier)
        tableView.register(TitheListCell.self, forCellReuseIdentifier: headerCellIdentifier)

        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = .whiteTint
        
        emptyMessage.textAlignment = .center
        emptyMessage.text = S.TransactionDetails.emptyMessage
        
        setContentInset()
        setupSubscriptions()
        loadChurches()
    }
    
    private func loadChurches() {
        let url = URL(string: "https://web.biblepay.org/BMS/PARTNERS")!
        let task = URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
            guard let data = data, error == nil else {
                print(error ?? "Unknown error")
                return
            }

            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
        })
        task.resume()
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
        
    }

    private func setContentInset() {
        let insets = UIEdgeInsets(top: accountHeaderHeight - 64.0 - (E.isIPhoneX ? 28.0 : 0.0), left: 0, bottom: accountFooterHeight + C.padding[2], right: 0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return hasExtraSection ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if hasExtraSection && section == 0 {
            return 1
        } else {
            return churches.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if hasExtraSection && indexPath.section == 0 {
            return headerCell(tableView: tableView, indexPath: indexPath)
        } else {
            return titheCell(tableView: tableView, indexPath: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if hasExtraSection && section == 1 {
            return C.padding[2]
        } else {
            return 0
        }
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
        didSelectTithe(churches, indexPath.row)
    }

    private func reload() {
        tableView.reloadData()
        if churches.count == 0 {
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
extension TitheTableViewController {

    private func headerCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: headerCellIdentifier, for: indexPath)
        if let containerCell = cell as? TitheListCell {
            if let prompt = currentPrompt {
                containerCell.contentView.addSubview(prompt)
                prompt.constrain(toSuperviewEdges: nil)
            }
        }
        return cell
    }

    private func titheCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: titheCellIdentifier, for: indexPath) as! TitheListCell
        let rate = self.rate ?? Rate.empty
        let viewModel = churches[indexPath.row]
        cell.setTitheRow(viewModel,
                            isBtcSwapped: isBtcSwapped,
                            rate: rate,
                            maxDigits: currency.state?.maxDigits ?? currency.commonUnit.decimals,
                            isSyncing: currency.state?.syncState != .success)
        return cell
    }
}

//MARK: - XMLParserDelegate
extension TitheTableViewController {
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

        if elementName.lowercased() == "row" {
            churchID = String()
            address = String()
            name = String()
            organizationType = String()
            timeStamp = TimeInterval()
        }
        self.elementName = elementName
    }

    // 2
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName.lowercased() == "row" {
            let row = TitheRowModel(churchID: churchID, address: address, name: name, organizationType: organizationType, timeStamp: timeStamp)
            allChurches.append(row)
        }
        if elementName.lowercased() == "table" {
            DispatchQueue.main.async {
                self.reload()
            }
        }
    }

    // 3
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if (!data.isEmpty) {
            if self.elementName.lowercased() == "id" {
                churchID += data
            } else if self.elementName.lowercased() == "name" {
                name += data
            } else if self.elementName.lowercased() == "address" {
                address += data
            } else if self.elementName.lowercased() == "organizationtype" {
                organizationType += data
            } else if self.elementName.lowercased() == "timestamp" {
                timeStamp = TimeInterval(0)
            }
        }
    }
}
