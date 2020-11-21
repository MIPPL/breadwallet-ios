//
//  SwapDetailViewController.swift
//  Wagerr Pro
//
//  Created by MIP on 2020-02-08.
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import UIKit

private extension C {
    static let statusRowHeight: CGFloat = 48.0
    static let compactContainerHeight: CGFloat = 352.0
    static let expandedContainerHeight: CGFloat = 476.0
    static let detailsButtonHeight: CGFloat = 65.0
}

class DiceDetailViewController: UIViewController, Subscriber {
    
    // MARK: - Private Vars
    
    private let container = UIView()
    private let tapView = UIView()
    private let header: ModalHeaderView
    private let footer = UIView()
    private let separator = UIView()
    private let detailsButton = UIButton(type: .custom)
    private let tableView = UITableView()
    private var containerHeightConstraint: NSLayoutConstraint!
    private var walletManager: BTCWalletManager?
    
    private var transaction: BetDiceGamesEntity {
        didSet {
            reload()
        }
    }
    private var viewModel: BetDiceGamesEntity
    private var dataSource: DiceDetailDataSource
    private var isExpanded: Bool = true
    
    private var compactContainerHeight: CGFloat {
        //return (viewModel.transactionState == .complete || viewModel.status == .invalid) ? C.compactContainerHeight :
        return C.compactContainerHeight + C.statusRowHeight
    }
    
    private var expandedContainerHeight: CGFloat {
        let maxHeight = view.frame.height - C.padding[4]
        let contentHeight = header.frame.height + tableView.contentSize.height + footer.frame.height + separator.frame.height
        tableView.isScrollEnabled = contentHeight > maxHeight
        return min(maxHeight, contentHeight)
    }
    
    // MARK: - Init
    
    init(txInfo: BetDiceGamesEntity, wm: BTCWalletManager) {
        self.transaction = txInfo
        self.walletManager = wm
        self.viewModel = txInfo
        self.dataSource = DiceDetailDataSource(viewModel: viewModel)
        self.header = ModalHeaderView(title: "", style: .transaction, faqInfo: ArticleIds.transactionDetails, currency: Currencies.btc )
        
        super.init(nibName: nil, bundle: nil)
        
        header.closeCallback = { [weak self] in
            self?.close()
        }
        
        setup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // refresh if tx state changes
        Store.lazySubscribe(self, selector: {
            guard let oldTransactions = $0[Currencies.btc]?.diceTransactions else { return false }
            guard let newTransactions = $1[Currencies.btc]?.diceTransactions else { return false }
            return oldTransactions != newTransactions }, callback: { [unowned self] in
                guard let tx = $0[Currencies.btc]?.diceTransactions.first(where: { $0.txHash == self.viewModel.txHash }) else { return }
                self.transaction = tx
        })
    }
    
    private func setup() {
        addSubViews()
        addConstraints()
        setupActions()
        setInitialData()
    }
    
    private func addSubViews() {
        view.addSubview(tapView)
        view.addSubview(container)
        container.addSubview(header)
        container.addSubview(tableView)
        container.addSubview(footer)
        container.addSubview(separator)
        footer.addSubview(detailsButton)
    }
    
    private func addConstraints() {
        tapView.constrain(toSuperviewEdges: nil)
        container.constrain([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        
        containerHeightConstraint = container.heightAnchor.constraint(equalToConstant: C.expandedContainerHeight)
        containerHeightConstraint.isActive = true
        
        header.constrainTopCorners(height: C.Sizes.headerHeight)
        tableView.constrain([
            tableView.topAnchor.constraint(equalTo: header.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: footer.topAnchor)
            ])
        
        footer.constrainBottomCorners(height: C.detailsButtonHeight)
        separator.constrain([
            separator.leadingAnchor.constraint(equalTo: footer.leadingAnchor),
            separator.topAnchor.constraint(equalTo: footer.topAnchor, constant: 1.0),
            separator.trailingAnchor.constraint(equalTo: footer.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5) ])
        detailsButton.constrain(toSuperviewEdges: .zero)
    }
    
    private func setupActions() {
        let gr = UITapGestureRecognizer(target: self, action: #selector(close))
        tapView.addGestureRecognizer(gr)
        tapView.isUserInteractionEnabled = true
    }
    
    private func setInitialData() {
        container.layer.cornerRadius = C.Sizes.roundedCornerRadius
        container.layer.masksToBounds = true
        
        footer.backgroundColor = .whiteBackground
        separator.backgroundColor = .secondaryShadow
        detailsButton.setTitleColor(.blueButtonText, for: .normal)
        detailsButton.setTitleColor(.blueButtonText, for: .selected)
        detailsButton.titleLabel?.font = .customBody(size: 16.0)
        
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 45.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.allowsSelection = false
        tableView.isScrollEnabled = false
        tableView.showsVerticalScrollIndicator = false
        
        dataSource.registerCells(forTableView: tableView)
        
        tableView.dataSource = dataSource
        tableView.reloadData()
        
        detailsButton.setTitle(S.TransactionDetails.showDetails, for: .normal)
        detailsButton.setTitle(S.TransactionDetails.hideDetails, for: .selected)
        detailsButton.addTarget(self, action: #selector(onToggleDetails), for: .touchUpInside)

        header.setTitle( viewModel.title )
        footer.isHidden = true
    }
    
    private func reload() {
        dataSource = DiceDetailDataSource(viewModel: viewModel)
        tableView.dataSource = dataSource
        tableView.reloadData()
    }
    
    deinit {
        Store.unsubscribe(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -
    
    @objc private func onToggleDetails() {
        isExpanded = !isExpanded
        detailsButton.isSelected = isExpanded
        
        UIView.spring(0.7, animations: {
            if self.isExpanded {
                self.containerHeightConstraint.constant = self.expandedContainerHeight
            } else {
                self.containerHeightConstraint.constant = self.compactContainerHeight
            }
            self.view.layoutIfNeeded()
        }) { _ in }
    }
    
    @objc private func close() {
        if let delegate = transitioningDelegate as? ModalTransitionDelegate {
            delegate.reset()
        }
        dismiss(animated: true, completion: nil)
    }
}
