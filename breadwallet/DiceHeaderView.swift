//
//  DiceHeaderView.swift
//  breadwallet
//
//  Created by MIP on 20/11/2020.
//  Copyright © 2020 Wagerr Ltd. All rights reserved.
//

import UIKit
import BRCore

private let largeFontSize: CGFloat = 28.0
private let smallFontSize: CGFloat = 14.0

class DiceHeaderView : UIView, GradientDrawable, Subscriber {

    // MARK: - Views
    
    private let currencyName = UILabel(font: .customBody(size: 18.0))
    private let exchangeRateLabel = UILabel(font: .customBody(size: 14.0))
    private let balanceLabel = UILabel(font: .customBody(size: 14.0))
    private let primaryBalance: UpdatingLabel
    private let secondaryBalance: UpdatingLabel
    private let conversionSymbol = UIImageView(image: #imageLiteral(resourceName: "conversion"))
    private let currencyTapView = UIView()
    private let syncIndicator = SyncingIndicator(style: .account)
    private let modeLabel = UILabel(font: .customBody(size: 12.0), color: .transparentWhiteText) // debug info
    
    private var regularConstraints: [NSLayoutConstraint] = []
    private var swappedConstraints: [NSLayoutConstraint] = []
    
    private let equalNotEqual = UIButton(type: .system )
    private let totalOverUnder = UIButton(type: .system)
    private let evenOdds = UIButton(type: .system)
    
    private let containerEqualNotEqual = UIView()
    private let containerOverUnder = UIView()
    
    private let equalnotequalButtons : [UIButton] = [UIButton].init(repeating: UIButton(type: .system), count: 11)
    private let overunderButtons : [UIButton] = [UIButton].init(repeating: UIButton(type: .system), count: 10)
    
    private let betLeft = UIButton(type: .system)
    private let betRight = UIButton(type: .system)
    private let currencyLabel = UILabel(font: .customBody(size: 18.0))
    
    private let diceLeft = UIImageView(image: #imageLiteral(resourceName: "BetDice"))
    private let diceRight = UIImageView(image: #imageLiteral(resourceName: "BetDice"))
    private let betAmount = UITextField(frame: CGRect(x: 10.0, y: 10.0, width: 250.0, height: 35.0))
    
    private var selectedNButton : UIButton?
    private var selectedN5Button : UIButton?
    private var previousNButton : UIButton?
    private var previousN5Button : UIButton?
    
    // MARK: Properties
    private let currency: CurrencyDef
    private var hasInitialized = false
    private var hasSetup = false
    
    private var isSyncIndicatorVisible: Bool = false {
        didSet {
            UIView.crossfade(balanceLabel, syncIndicator, toRight: isSyncIndicatorVisible, duration: 0.3)
        }
    }

    var isWatchOnly: Bool = false {
        didSet {
            if E.isTestnet || isWatchOnly {
                if E.isTestnet && isWatchOnly {
                    modeLabel.text = "(Testnet - Watch Only)"
                } else if E.isTestnet {
                    modeLabel.text = "(Testnet)"
                } else if isWatchOnly {
                    modeLabel.text = "(Watch Only)"
                }
                modeLabel.isHidden = false
            }
            if E.isScreenshots {
                modeLabel.isHidden = true
            }
        }
    }
    private var exchangeRate: Rate? {
        didSet {
            DispatchQueue.main.async {
                self.setBalances()
            }
        }
    }
    
    private var balance: UInt256 = 0 {
        didSet {
            DispatchQueue.main.async {
                self.setBalances()
            }
        }
    }
    
    private var isBtcSwapped: Bool {
        didSet {
            DispatchQueue.main.async {
                self.setBalances()
            }
        }
    }

    // MARK: -
    
    init(currency: CurrencyDef) {
        self.currency = currency
        self.isBtcSwapped = Store.state.isBtcSwapped
        if let rate = currency.state?.currentRate {
            let placeholderAmount = Amount(amount: 0, currency: currency, rate: rate)
            self.exchangeRate = rate
            self.secondaryBalance = UpdatingLabel(formatter: placeholderAmount.localFormat)
            self.primaryBalance = UpdatingLabel(formatter: placeholderAmount.tokenFormat)
        } else {
            self.secondaryBalance = UpdatingLabel(formatter: NumberFormatter())
            self.primaryBalance = UpdatingLabel(formatter: NumberFormatter())
        }
        super.init(frame: CGRect())
        
        setup()
    }

    // MARK: Private
    
    private func setup() {
        addSubviews()
        addConstraints()
        addStyles()
        setData()
        addSubscriptions()
    }

    private func setData() {
        currencyName.textColor = .white
        currencyName.textAlignment = .center
        currencyName.text = currency.name
        
        exchangeRateLabel.textColor = .transparentWhiteText
        exchangeRateLabel.textAlignment = .center
        
        balanceLabel.textColor = .transparentWhiteText
        balanceLabel.text = S.Account.balance
        conversionSymbol.tintColor = .whiteTint
        
        primaryBalance.textAlignment = .right
        secondaryBalance.textAlignment = .right
        
        swapLabels()

        modeLabel.isHidden = true
        syncIndicator.isHidden = true
        
        let gr = UITapGestureRecognizer(target: self, action: #selector(currencySwitchTapped))
        currencyTapView.addGestureRecognizer(gr)
        
        // dice bet buttons
        equalNotEqual.setTitle(S.Dice.EqualNotEqual, for: .normal)
        equalNotEqual.tap = {
            self.containerEqualNotEqual.isHidden = false
            self.containerOverUnder.isHidden = true
            self.betLeft.setTitle(S.Dice.Equal, for: .normal)
            self.betRight.setTitle(S.Dice.NotEqual, for: .normal)
        }
        totalOverUnder.setTitle(S.Dice.OverUnder, for: .normal)
        totalOverUnder.tap = {
            self.containerEqualNotEqual.isHidden = true
            self.containerOverUnder.isHidden = false
            self.betLeft.setTitle(S.Dice.Over, for: .normal)
            self.betRight.setTitle(S.Dice.Under, for: .normal)
        }
        evenOdds.setTitle(S.Dice.EvenOdds, for: .normal)
        evenOdds.tap = {
            self.containerEqualNotEqual.isHidden = true
            self.containerOverUnder.isHidden = true
            self.betLeft.setTitle(S.Dice.Even, for: .normal)
            self.betRight.setTitle(S.Dice.Odds, for: .normal)
        }
        var n = 2
        for button in equalnotequalButtons {
            button.setTitle(String.init(format: "%d", n), for: .normal)
            button.layer.borderColor = UIColor.gray.cgColor
            button.tap = {
                guard button != self.selectedNButton else   {   return }
                button.layer.borderColor = UIColor.red.cgColor
                if self.previousNButton != nil   {
                    self.previousNButton!.layer.borderColor = UIColor.gray.cgColor
                }
                self.previousNButton = self.selectedNButton
                self.selectedNButton = button
            }
            n+=1
        }
        n = 2
        for button in overunderButtons {
            button.setTitle(String.init(format: "%d.5", n), for: .normal)
            button.layer.borderColor = UIColor.gray.cgColor
            button.tap = {
                guard button != self.selectedN5Button else   {   return }
                button.layer.borderColor = UIColor.red.cgColor
                if self.previousN5Button != nil   {
                    self.previousN5Button!.layer.borderColor = UIColor.gray.cgColor
                }
                self.previousN5Button = self.selectedN5Button
                self.selectedN5Button = button
            }
            n+=1
        }
        
        // initial buton status
        equalNotEqual.tap!()
        equalnotequalButtons[0].tap!()
        overunderButtons[0].tap!()
    }

    private func addSubviews() {
        addSubview(currencyName)
        addSubview(exchangeRateLabel)
        addSubview(balanceLabel)
        addSubview(primaryBalance)
        addSubview(secondaryBalance)
        addSubview(conversionSymbol)
        addSubview(modeLabel)
        addSubview(syncIndicator)
        addSubview(currencyTapView)
        
        // dice controls
        addSubview(equalNotEqual)
        addSubview(totalOverUnder)
        addSubview(evenOdds)
        addSubview(containerEqualNotEqual)
        for button in equalnotequalButtons {
            containerEqualNotEqual.addSubview( button )
        }
        addSubview(containerOverUnder)
        for button in overunderButtons {
            containerOverUnder.addSubview( button )
        }
        addSubview(diceLeft)
        addSubview(betLeft)
        addSubview(betAmount)
        addSubview(currencyLabel)
        addSubview(betRight)
        addSubview(diceRight)
    }

    private func addConstraints() {
        currencyName.constrain([
            currencyName.constraint(.leading, toView: self, constant: C.padding[2]),
            currencyName.constraint(.trailing, toView: self, constant: -C.padding[2]),
            currencyName.constraint(.top, toView: self, constant: E.isIPhoneX ? C.padding[5] : C.padding[3])
            ])
        
        exchangeRateLabel.pinTo(viewAbove: currencyName)
        
        balanceLabel.constrain([
            balanceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            balanceLabel.bottomAnchor.constraint(equalTo: primaryBalance.topAnchor, constant: 0.0)
            ])
        
        primaryBalance.constrain([
            primaryBalance.firstBaselineAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[2])
            ])
        
        secondaryBalance.constrain([
            secondaryBalance.firstBaselineAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[2]),
            ])
        
        conversionSymbol.constrain([
            conversionSymbol.heightAnchor.constraint(equalToConstant: 12.0),
            conversionSymbol.heightAnchor.constraint(equalTo: conversionSymbol.widthAnchor),
            conversionSymbol.bottomAnchor.constraint(equalTo: primaryBalance.firstBaselineAnchor)
            ])
        
        currencyTapView.constrain([
            currencyTapView.trailingAnchor.constraint(equalTo: balanceLabel.trailingAnchor),
            currencyTapView.topAnchor.constraint(equalTo: primaryBalance.topAnchor, constant: -C.padding[1]),
            currencyTapView.bottomAnchor.constraint(equalTo: primaryBalance.bottomAnchor, constant: C.padding[1]) ])

        regularConstraints = [
            primaryBalance.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            primaryBalance.leadingAnchor.constraint(equalTo: conversionSymbol.trailingAnchor, constant: C.padding[1]),
            conversionSymbol.leadingAnchor.constraint(equalTo: secondaryBalance.trailingAnchor, constant: C.padding[1]),
            currencyTapView.leadingAnchor.constraint(equalTo: secondaryBalance.leadingAnchor)
        ]

        swappedConstraints = [
            secondaryBalance.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            secondaryBalance.leadingAnchor.constraint(equalTo: conversionSymbol.trailingAnchor, constant: C.padding[1]),
            conversionSymbol.leadingAnchor.constraint(equalTo: primaryBalance.trailingAnchor, constant: C.padding[1]),
            currencyTapView.leadingAnchor.constraint(equalTo: primaryBalance.leadingAnchor)
        ]

        NSLayoutConstraint.activate(isBtcSwapped ? self.swappedConstraints : self.regularConstraints)

        modeLabel.constrain([
            modeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            modeLabel.centerYAnchor.constraint(equalTo: balanceLabel.centerYAnchor)
            ])
        
        syncIndicator.constrain([
            syncIndicator.trailingAnchor.constraint(equalTo: balanceLabel.trailingAnchor),
            syncIndicator.topAnchor.constraint(equalTo: balanceLabel.topAnchor),
            syncIndicator.bottomAnchor.constraint(equalTo: balanceLabel.bottomAnchor)
            ])
        
        // Dice controls
        equalNotEqual.constrain([
            equalNotEqual.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[1]),
            equalNotEqual.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: C.padding[1])
            ])
        
        totalOverUnder.constrain([
            totalOverUnder.leadingAnchor.constraint(equalTo: equalNotEqual.trailingAnchor, constant: C.padding[2]),
            totalOverUnder.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: C.padding[1])
            ])
        
        evenOdds.constrain([
            evenOdds.leadingAnchor.constraint(equalTo: totalOverUnder.trailingAnchor, constant: C.padding[2]),
            evenOdds.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: C.padding[1])
            ])
        
        containerEqualNotEqual.constrain([
            containerEqualNotEqual.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerEqualNotEqual.topAnchor.constraint(equalTo: equalNotEqual.bottomAnchor, constant: C.padding[1])
            ])
        
        containerOverUnder.constrain([
            containerOverUnder.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerOverUnder.topAnchor.constraint(equalTo: equalNotEqual.bottomAnchor, constant: C.padding[1])
            ])
        
        diceLeft.constrain([
            diceLeft.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[1]),
            diceLeft.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[1])
            ])
        
        betLeft.constrain([
            betLeft.leadingAnchor.constraint(equalTo: diceLeft.trailingAnchor, constant: C.padding[1]),
            betLeft.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[1])
            ])
        
        betAmount.constrain([
            betAmount.leadingAnchor.constraint(equalTo: betLeft.trailingAnchor, constant: C.padding[1]),
            betAmount.trailingAnchor.constraint(equalTo: currencyLabel.leadingAnchor, constant: -C.padding[1]),
            betAmount.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[1])
            ])
        
        currencyLabel.constrain([
            currencyLabel.trailingAnchor.constraint(equalTo: betRight.leadingAnchor, constant: -C.padding[1]),
            currencyLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[1])
            ])
        
        betRight.constrain([
           betRight.trailingAnchor.constraint(equalTo: diceRight.leadingAnchor, constant: C.padding[1]),
           betRight.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[1])
           ])
        
        diceRight.constrain([
            diceRight.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[1]),
            diceRight.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[1])
            ])
    }

    private func addStyles() {
        diceLeft.tintColor = .white
        diceRight.tintColor = .white
    }

    private func addSubscriptions() {
        Store.lazySubscribe(self,
                            selector: { $0.isBtcSwapped != $1.isBtcSwapped },
                            callback: { self.isBtcSwapped = $0.isBtcSwapped })
        Store.lazySubscribe(self,
                            selector: { $0[self.currency]?.currentRate != $1[self.currency]?.currentRate},
                            callback: {
                                if let rate = $0[self.currency]?.currentRate {
                                    let placeholderAmount = Amount(amount: 0, currency: self.currency, rate: rate)
                                    self.secondaryBalance.formatter = placeholderAmount.localFormat
                                    self.primaryBalance.formatter = placeholderAmount.tokenFormat
                                }
                                self.exchangeRate = $0[self.currency]?.currentRate
        })
        
        Store.lazySubscribe(self,
                            selector: { $0[self.currency]?.maxDigits != $1[self.currency]?.maxDigits},
                            callback: {
                                if let rate = $0[self.currency]?.currentRate {
                                    let placeholderAmount = Amount(amount: 0, currency: self.currency, rate: rate)
                                    self.secondaryBalance.formatter = placeholderAmount.localFormat
                                    self.primaryBalance.formatter = placeholderAmount.tokenFormat
                                    self.setBalances()
                                }
        })
        Store.subscribe(self,
                        selector: { $0[self.currency]?.balance != $1[self.currency]?.balance },
                        callback: { state in
                            if let balance = state[self.currency]?.balance {
                                self.balance = balance
                            } })
        
        Store.subscribe(self, selector: { $0[self.currency]?.syncState != $1[self.currency]?.syncState },
                        callback: { state in
                            guard let syncState = state[self.currency]?.syncState else { return }
                            switch syncState {
                            case .connecting:
                                self.isSyncIndicatorVisible = true
                                self.syncIndicator.text = S.SyncingView.connecting
                            case .syncing:
                                self.isSyncIndicatorVisible = true
                                self.syncIndicator.text = S.SyncingView.syncing
                            case .success:
                                self.isSyncIndicatorVisible = false
                            }
        })
        
        Store.subscribe(self, selector: {
            return $0[self.currency]?.lastBlockTimestamp != $1[self.currency]?.lastBlockTimestamp },
                        callback: { state in
                            if let progress = state[self.currency]?.syncProgress {
                                self.syncIndicator.progress = CGFloat(progress)
                            }
        })
    }

    func setBalances() {
        guard let rate = exchangeRate else { return }
        
        exchangeRateLabel.text = String(format: S.AccountHeader.exchangeRate, rate.localString, currency.code)
        
        let amount = Amount(amount: balance, currency: currency, rate: rate)
        
        if !hasInitialized {
            primaryBalance.setValue(amount.tokenValue)
            secondaryBalance.setValue(amount.fiatValue)
            swapLabels()
            hasInitialized = true
        } else {
            if primaryBalance.isHidden {
                primaryBalance.isHidden = false
            }

            if secondaryBalance.isHidden {
                secondaryBalance.isHidden = false
            }
            
            primaryBalance.setValueAnimated(amount.tokenValue, completion: { [weak self] in
                self?.swapLabels()
            })
            secondaryBalance.setValueAnimated(amount.fiatValue, completion: { [weak self] in
                self?.swapLabels()
            })
        }
    }
    
    private func swapLabels() {
        NSLayoutConstraint.deactivate(isBtcSwapped ? regularConstraints : swappedConstraints)
        NSLayoutConstraint.activate(isBtcSwapped ? swappedConstraints : regularConstraints)
        if isBtcSwapped {
            primaryBalance.makeSecondary()
            secondaryBalance.makePrimary()
        } else {
            primaryBalance.makePrimary()
            secondaryBalance.makeSecondary()
        }
    }

    override func draw(_ rect: CGRect) {
        drawGradient(start: currency.colors.0, end: currency.colors.1, rect)
    }

    @objc private func currencySwitchTapped() {
        layoutIfNeeded()
        UIView.spring(0.7, animations: {
            self.primaryBalance.toggle()
            self.secondaryBalance.toggle()
            NSLayoutConstraint.deactivate(!self.isBtcSwapped ? self.regularConstraints : self.swappedConstraints)
            NSLayoutConstraint.activate(!self.isBtcSwapped ? self.swappedConstraints : self.regularConstraints)
            self.layoutIfNeeded()
        }) { _ in }

        Store.perform(action: CurrencyChange.toggle())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: -

private extension UILabel {
    func makePrimary() {
        font = UIFont.customBold(size: largeFontSize)
        textColor = .white
        reset()
    }
    
    func makeSecondary() {
        font = UIFont.customBody(size: largeFontSize)
        textColor = .transparentWhiteText
        shrink()
    }
    
    func shrink() {
        transform = .identity // must reset the view's transform before we calculate the next transform
        let scaleFactor: CGFloat = smallFontSize/largeFontSize
        let deltaX = frame.width * (1-scaleFactor)
        let deltaY = frame.height * (1-scaleFactor)
        let scale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        transform = scale.translatedBy(x: deltaX, y: deltaY/2.0)
    }
    
    func reset() {
        transform = .identity
    }
    
    func toggle() {
        if transform.isIdentity {
            makeSecondary()
        } else {
            makePrimary()
        }
    }
}
