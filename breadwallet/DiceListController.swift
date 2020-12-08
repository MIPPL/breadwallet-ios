//
//  DiceListController.swift
//  breadwallet
//
//  Created by MIP on 21/11/2020.
//  Copyright © 2020 Wagerr Ltd.. All rights reserved.
//

import UIKit
import BRCore
import MachO

let diceHeaderHeight: CGFloat = 312.0

class DiceListController : UIViewController, Subscriber, Trackable {

    //MARK: - Public
    let currency: CurrencyDef
    
    init(currency: CurrencyDef, walletManager: WalletManager) {
        self.walletManager = walletManager
        self.currency = currency
        
        let kvStore = (walletManager.apiClient?.kv)!
        let sender = currency.createSender(walletManager: walletManager, kvStore: kvStore)
        self.headerView = DiceHeaderView(currency: currency, walletManager: walletManager as! BTCWalletManager, sender: sender as! BitcoinSender)
        
        super.init(nibName: nil, bundle: nil)
        self.transactionsTableView = DiceTableViewController(currency: currency, walletManager: walletManager, didSelectBet: didSelectBet)

        if let btcWalletManager = walletManager as? BTCWalletManager {
            headerView.isWatchOnly = btcWalletManager.isWatchOnly
        } else {
            headerView.isWatchOnly = false
        }
        
        headerView.presentVerifyPin = { [weak self] bodyText, success in
            guard let myself = self else { return }
            let wm = myself.walletManager as! BTCWalletManager
            let vc = VerifyPinViewController(bodyText: bodyText, pinLength: Store.state.pinLength, walletManager: wm, success: success)
            vc.transitioningDelegate = self!.headerView.verifyPinTransitionDelegate
            vc.modalPresentationStyle = .overFullScreen
            vc.modalPresentationCapturesStatusBarAppearance = true
            //nc.pushViewController(vc, animated: true)
            self?.present(vc, animated: true, completion: nil)
        }
        headerView.onPublishSuccess = { [weak self] in
            self?.presentAlert(.sendSuccess, completion: {})
        }
        headerView.doPresentConfirm = self.presentConfirmation
        headerView.doSend = self.doSend
    }
    
    //MARK: - Private
    private let alertHeight: CGFloat = 260.0
    private let walletManager: WalletManager
    private let headerView: DiceHeaderView
    private let transitionDelegate = ModalTransitionDelegate(type: .transactionDetail)
    private var transactionsTableView: DiceTableViewController!
    private var isLoginRequired = false
    private let searchHeaderview: DiceSearchHeaderView = {
        let view = DiceSearchHeaderView()
        view.isHidden = true
        return view
    }()
    private let headerContainer = UIView()
    private var loadingTimer: Timer?
    private var shouldShowStatusBar: Bool = true {
        didSet {
            if oldValue != shouldShowStatusBar {
                UIView.animate(withDuration: C.animationDuration) {
                    self.setNeedsStatusBarAppearanceUpdate()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // detect jailbreak so we can throw up an idiot warning, in viewDidLoad so it can't easily be swizzled out
        if !E.isSimulator {
            var s = stat()
            var isJailbroken = (stat("/bin/sh", &s) == 0) ? true : false
            for i in 0..<_dyld_image_count() {
                guard !isJailbroken else { break }
                // some anti-jailbreak detection tools re-sandbox apps, so do a secondary check for any MobileSubstrate dyld images
                if strstr(_dyld_get_image_name(i), "MobileSubstrate") != nil {
                    isJailbroken = true
                }
            }
            NotificationCenter.default.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: nil) { note in
                self.showJailbreakWarnings(isJailbroken: isJailbroken)
            }
            showJailbreakWarnings(isJailbroken: isJailbroken)
        }

        setupNavigationBar()
        addTransactionsView()
        addSubviews()
        addConstraints()
        addSubscriptions()
        setInitialData()
    }

    private func didSelectBet(txInfo: [BetDiceGamesEntity], selectedIndex: Int) -> Void {
        let transactionDetails = DiceDetailViewController(txInfo: txInfo[selectedIndex], wm: walletManager as! BTCWalletManager)
        transactionDetails.modalPresentationStyle = .overCurrentContext
        transactionDetails.transitioningDelegate = transitionDelegate
        transactionDetails.modalPresentationCapturesStatusBarAppearance = true
        present(transactionDetails, animated: true, completion: nil)
    }
    
    private func presentConfirmation(vc : ConfirmationViewController) {
        present(vc, animated: true, completion: nil)
    }
    
    private func doSend()   {
        let pinVerifier: PinVerifier = { [weak self] pinValidationCallback in
            self!.headerView.presentVerifyPin?(S.VerifyPin.authorize) { pin in
                pinValidationCallback(pin)
            }
        }
        
        headerView.sender.sendTransaction(allowBiometrics: true, pinVerifier: pinVerifier) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success:
                self.dismiss(animated: true, completion: {
                    Store.trigger(name: .showStatusBar)
                    self.headerView.onPublishSuccess?()
                })
                self.saveEvent("send.success")
            case .creationError(let message):
                self.showAlert(title: S.Send.createTransactionError, message: message, buttonLabel: S.Button.ok)
                self.saveEvent("send.publishFailed", attributes: ["errorMessage": message])
            case .publishFailure(let error):
                if case .posixError(let code, let description) = error {
                    self.showAlert(title: S.Alerts.sendFailure, message: "\(description) (\(code))", buttonLabel: S.Button.ok)
                    self.saveEvent("send.publishFailed", attributes: ["errorMessage": "\(description) (\(code))"])
                }
            case .insufficientGas(let rpcErrorMessage):
                self.saveEvent("send.publishFailed", attributes: ["errorMessage": rpcErrorMessage])
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        shouldShowStatusBar = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        headerView.setBalances()
        if walletManager.peerManager?.connectionStatus == BRPeerStatusDisconnected {
            DispatchQueue.walletQueue.async { [weak self] in
                self?.walletManager.peerManager?.connect()
            }
        }
    }
    
    // MARK: -
    
    private func setupNavigationBar() {
        let searchButton = UIButton(type: .system)
        searchButton.setImage(#imageLiteral(resourceName: "SearchIcon"), for: .normal)
        searchButton.frame = CGRect(x: 0.0, y: 12.0, width: 22.0, height: 22.0) // for iOS 10
        searchButton.widthAnchor.constraint(equalToConstant: 22.0).isActive = true
        searchButton.heightAnchor.constraint(equalToConstant: 22.0).isActive = true
        searchButton.tintColor = .white
        searchButton.tap = showSearchHeaderView
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: searchButton)
        
    }

    private func addSubviews() {
        view.addSubview(headerContainer)
        headerContainer.addSubview(headerView)
        headerContainer.addSubview(searchHeaderview)
    }

    private func addConstraints() {
        headerContainer.constrainTopCorners(height: diceHeaderHeight)
        headerView.constrain(toSuperviewEdges: nil)
        searchHeaderview.constrain(toSuperviewEdges: nil)
    }

    private func addSubscriptions() {
        Store.subscribe(self, selector: { $0.isLoginRequired != $1.isLoginRequired }, callback: { self.isLoginRequired = $0.isLoginRequired })
        Store.subscribe(self, name: .showStatusBar, callback: { _ in
            self.shouldShowStatusBar = true
        })
        Store.subscribe(self, name: .hideStatusBar, callback: { _ in
            self.shouldShowStatusBar = false
        })
    }

    private func setInitialData() {
        searchHeaderview.didCancel = hideSearchHeaderView
        searchHeaderview.didChangeFilters = { [weak self] filters in
            self?.transactionsTableView.filters = filters
        }
    }

    private func addTransactionsView() {
        view.backgroundColor = .whiteTint
        addChildViewController(transactionsTableView, layout: {
            if #available(iOS 11.0, *) {
                transactionsTableView.view.constrain([
                    transactionsTableView.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                transactionsTableView.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                transactionsTableView.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                transactionsTableView.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                ])
            } else {
                transactionsTableView.view.constrain(toSuperviewEdges: nil)
            }
        })
    }

    private func showJailbreakWarnings(isJailbroken: Bool) {
        guard isJailbroken else { return }
        let totalSent = walletManager.wallet?.totalSent ?? 0
        let message = totalSent > 0 ? S.JailbreakWarnings.messageWithBalance : S.JailbreakWarnings.messageWithBalance
        let alert = UIAlertController(title: S.JailbreakWarnings.title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: S.JailbreakWarnings.ignore, style: .default, handler: nil))
        if totalSent > 0 {
            alert.addAction(UIAlertAction(title: S.JailbreakWarnings.wipe, style: .default, handler: nil)) //TODO - implement wipe
        } else {
            alert.addAction(UIAlertAction(title: S.JailbreakWarnings.close, style: .default, handler: { _ in
                exit(0)
            }))
        }
        present(alert, animated: true, completion: nil)
    }
    
    private func showSearchHeaderView() {
        let navBarHeight: CGFloat = 44.0
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        var contentInset = self.transactionsTableView.tableView.contentInset
        var contentOffset = self.transactionsTableView.tableView.contentOffset
        contentInset.top += navBarHeight
        contentOffset.y -= navBarHeight
        self.transactionsTableView.tableView.contentInset = contentInset
        self.transactionsTableView.tableView.contentOffset = contentOffset
        UIView.transition(from: self.headerView,
                          to: self.searchHeaderview,
                          duration: C.animationDuration,
                          options: [.transitionFlipFromBottom, .showHideTransitionViews, .curveEaseOut],
                          completion: { _ in
                            self.searchHeaderview.triggerUpdate()
                            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    private func hideSearchHeaderView() {
        let navBarHeight: CGFloat = 44.0
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        var contentInset = self.transactionsTableView.tableView.contentInset
        contentInset.top -= navBarHeight
        self.transactionsTableView.tableView.contentInset = contentInset
        UIView.transition(from: self.searchHeaderview,
                          to: self.headerView,
                          duration: C.animationDuration,
                          options: [.transitionFlipFromTop, .showHideTransitionViews, .curveEaseOut],
                          completion: { _ in
                            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return searchHeaderview.isHidden ? .lightContent : .default
    }

    override var prefersStatusBarHidden: Bool {
        return !shouldShowStatusBar
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }

    private func presentAlert(_ type: AlertType, completion: @escaping ()->Void) {
        let alertView = AlertView(type: type)
        let window = UIApplication.shared.keyWindow!
        let size = window.bounds.size
        window.addSubview(alertView)

        let topConstraint = alertView.constraint(.top, toView: window, constant: size.height)
        alertView.constrain([
            alertView.constraint(.width, constant: size.width),
            alertView.constraint(.height, constant: alertHeight + 25.0),
            alertView.constraint(.leading, toView: window, constant: nil),
            topConstraint ])
        window.layoutIfNeeded()

        UIView.spring(0.6, animations: {
            topConstraint?.constant = size.height - self.alertHeight
            window.layoutIfNeeded()
        }, completion: { _ in
            alertView.animate()
            UIView.spring(0.6, delay: 2.0, animations: {
                topConstraint?.constant = size.height
                window.layoutIfNeeded()
            }, completion: { _ in
                //TODO - Make these callbacks generic
                if case .paperKeySet(let callback) = type {
                    callback()
                }
                if case .pinSet(let callback) = type {
                    callback()
                }
                if case .sweepSuccess(let callback) = type {
                    callback()
                }
                completion()
                alertView.removeFromSuperview()
            })
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
