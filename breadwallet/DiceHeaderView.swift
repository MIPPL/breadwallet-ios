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

class DiceHeaderView : UIView, GradientDrawable, Subscriber, UITextFieldDelegate {

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
    
    private var containerDiceOptions = UIStackView()
    private var containerEqualNotEqual1 = UIStackView()
    private var containerEqualNotEqual2 = UIStackView()
    private var containerOverUnder1 = UIStackView()
    private var containerOverUnder2 = UIStackView()
    private var containerBetBar = UIStackView()
    
    private var equalnotequalButtons : [UIButton] = []
    private let rewardEqual : [Double] = [35.65, 17.83, 11.89, 8.92, 7.138, 5.95, 7.138, 8.92, 11.89, 17.83, 35.65]
    private let rewardNotEqual : [Double] = [1.028215, 1.058212, 1.089991, 1.12375, 1.159588, 1.198, 1.159588, 1.12375, 1.089991, 1.058212, 1.028215]
    
    private var overunderButtons : [UIButton] = []
    private let rewardOverUnder : [Double] = [35.65, 11.89, 5.95, 3.574, 2.386, 1.707058, 1.380754, 1.198, 1.089991, 1.028215]
    private let rewardEvenOdd : Double = 1.99
    
    private let betLeft = UIButton(type: .system)
    private let betRight = UIButton(type: .system)
    private let currencyLabel = UILabel(font: .customBody(size: 18.0))
    
    private let diceLeft =  UIButton(type: .system)// UIImageView(image: #imageLiteral(resourceName: "BetDice"))
    private let diceRight = UIButton(type: .system)// UIImageView(image: #imageLiteral(resourceName: "BetDice"))
    private let betAmount = UITextField(frame: CGRect(x: 10.0, y: 10.0, width: 250.0, height: 35.0))
    
    private var selectedBetButton : UIButton?
    private var previousBetButton : UIButton?
    private var selectedNButton : UIButton?
    private var selectedN5Button : UIButton?
    private var previousNButton : UIButton?
    private var previousN5Button : UIButton?
    
    private let potentialRewardTitle = UILabel(font: .customBody(size: 12.0))
    private let potentialRewardLeft = UILabel(font: .customBody(size: 12.0))
    private let potentialRewardRight = UILabel(font: .customBody(size: 12.0))
    
    // MARK: Properties
    private let currency: CurrencyDef
    private var hasInitialized = false
    private var hasSetup = false
    private var walletManager : BTCWalletManager
    
    var sender: BitcoinSender
    let verifyPinTransitionDelegate = PinTransitioningDelegate()
    let confirmTransitioningDelegate = PinTransitioningDelegate()
    var presentVerifyPin: ((String, @escaping ((String) -> Void))->Void)?
    var onPublishSuccess: (()->Void)?
    var doPresentConfirm: ((ConfirmationViewController) -> Void)?
    var doSend: (()->Void)?
    
    // MARK: - Accessors
    public var amount: String {
        get {
            return betAmount.text ?? ""
        }
        set {
            betAmount.text = newValue
        }
    }
    
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
    
    init(currency: CurrencyDef, walletManager : BTCWalletManager, sender: BitcoinSender) {
        self.currency = currency
        self.isBtcSwapped = Store.state.isBtcSwapped
        self.walletManager = walletManager
        self.sender = sender
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

    func createStackView(with layout: UILayoutConstraintAxis) -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = layout
        stackView.distribution = .fillProportionally
        stackView.spacing = 5
        return stackView
    }
    
    // MARK: Private
    
    private func setup() {
        addSubviews()
        addConstraints()
        addStyles()
        setData()
        addSubscriptions()
    }
    
    private func addSubviews() {
        containerDiceOptions = createStackView(with: UILayoutConstraintAxis.horizontal)
        containerEqualNotEqual1 = createStackView(with: UILayoutConstraintAxis.horizontal)
        containerEqualNotEqual2 = createStackView(with: UILayoutConstraintAxis.horizontal)
        containerOverUnder1 = createStackView(with: UILayoutConstraintAxis.horizontal)
        containerOverUnder2 = createStackView(with: UILayoutConstraintAxis.horizontal)
        containerBetBar = createStackView(with: UILayoutConstraintAxis.horizontal)

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
        addSubview(containerDiceOptions)
        containerDiceOptions.addArrangedSubview(equalNotEqual)
        containerDiceOptions.addArrangedSubview(totalOverUnder)
        containerDiceOptions.addArrangedSubview(evenOdds)
        
        addSubview(containerEqualNotEqual1)
        addSubview(containerEqualNotEqual2)
        for _ in 0..<11 { equalnotequalButtons.append(UIButton(type: .system))  }
        for i in 0..<6  { containerEqualNotEqual1.addArrangedSubview( equalnotequalButtons[i] ) }
        for i in 6..<11  { containerEqualNotEqual2.addArrangedSubview( equalnotequalButtons[i] ) }
        
        addSubview(containerOverUnder1)
        addSubview(containerOverUnder2)
        for _ in 0..<10 { overunderButtons.append(UIButton(type: .system))  }
        for i in 0..<5  { containerOverUnder1.addArrangedSubview( overunderButtons[i] ) }
        for i in 5..<10  { containerOverUnder2.addArrangedSubview( overunderButtons[i] ) }
        
        addSubview(containerBetBar)
        containerBetBar.addArrangedSubview(diceLeft)
        containerBetBar.addArrangedSubview(betLeft)
        containerBetBar.addArrangedSubview(betAmount)
        containerBetBar.addArrangedSubview(currencyLabel)
        containerBetBar.addArrangedSubview(betRight)
        containerBetBar.addArrangedSubview(diceRight)
        
        addSubview(potentialRewardTitle)
        addSubview(potentialRewardLeft)
        addSubview(potentialRewardRight)
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
            primaryBalance.firstBaselineAnchor.constraint(equalTo: currencyName.bottomAnchor, constant: C.padding[10])
            ])
        
        secondaryBalance.constrain([
            secondaryBalance.firstBaselineAnchor.constraint(equalTo: currencyName.bottomAnchor, constant: C.padding[10]),
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
        containerDiceOptions.constrain([
            containerDiceOptions.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            containerDiceOptions.topAnchor.constraint(equalTo: primaryBalance.bottomAnchor, constant: C.padding[1]),
            containerDiceOptions.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2])
        ])
        
        containerEqualNotEqual1.constrain([
            containerEqualNotEqual1.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            containerEqualNotEqual1.topAnchor.constraint(equalTo: containerDiceOptions.bottomAnchor, constant: C.padding[1]),
            containerEqualNotEqual1.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2])
            ])
        containerEqualNotEqual2.constrain([
            containerEqualNotEqual2.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            containerEqualNotEqual2.topAnchor.constraint(equalTo: containerEqualNotEqual1.bottomAnchor, constant: C.padding[1]),
            containerEqualNotEqual2.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2])
        ])
        
        containerOverUnder1.constrain([
            containerOverUnder1.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            containerOverUnder1.topAnchor.constraint(equalTo: containerDiceOptions.bottomAnchor, constant: C.padding[1]),
            containerOverUnder1.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2])
            ])
        
        containerOverUnder2.constrain([
            containerOverUnder2.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            containerOverUnder2.topAnchor.constraint(equalTo: containerOverUnder1.bottomAnchor, constant: C.padding[1]),
            containerOverUnder2.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2])
            ])
        
        containerBetBar.constrain([
            containerBetBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            containerBetBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[3]),
            containerBetBar.heightAnchor.constraint(equalToConstant: 30.0),
            containerBetBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2])
        ])
        
        potentialRewardTitle.constrain([
            potentialRewardTitle.leadingAnchor.constraint(equalTo: betAmount.leadingAnchor),
            potentialRewardTitle.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[1]),
            potentialRewardTitle.heightAnchor.constraint(equalToConstant: 14.0),
            potentialRewardTitle.trailingAnchor.constraint(equalTo: currencyLabel.trailingAnchor)
        ])
        
        potentialRewardLeft.constrain([
            potentialRewardLeft.leadingAnchor.constraint(equalTo: betLeft.leadingAnchor),
            potentialRewardLeft.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[1]),
            potentialRewardLeft.heightAnchor.constraint(equalToConstant: 14.0),
            potentialRewardLeft.trailingAnchor.constraint(equalTo: betLeft.trailingAnchor)
        ])
        
        potentialRewardRight.constrain([
            potentialRewardRight.leadingAnchor.constraint(equalTo: betRight.leadingAnchor),
            potentialRewardRight.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[1]),
            potentialRewardRight.heightAnchor.constraint(equalToConstant: 14.0),
            potentialRewardRight.trailingAnchor.constraint(equalTo: betRight.trailingAnchor)
        ])
        
        betAmount.constrain([
            betAmount.widthAnchor.constraint(equalToConstant: 70.0)
        ])
        betLeft.constrain([
            betLeft.widthAnchor.constraint(equalToConstant: 100.0)
        ])
        betRight.constrain([
            betRight.widthAnchor.constraint(equalToConstant: 100.0)
        ])
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
        currencyLabel.text = "WGR"
        currencyLabel.textColor = .white
        
        
        equalNotEqual.setTitle(S.Dice.EqualNotEqual, for: .normal)
        equalNotEqual.tap = {
            guard self.selectedBetButton != self.equalNotEqual else { return }
            self.containerEqualNotEqual1.isHidden = false
            self.containerEqualNotEqual2.isHidden = false
            self.containerOverUnder1.isHidden = true
            self.containerOverUnder2.isHidden = true
            self.betLeft.setTitle(S.Dice.Equal, for: .normal)
            self.betRight.setTitle(S.Dice.NotEqual, for: .normal)
            self.selectedBetButton = self.equalNotEqual
            self.selectButton( selected: self.selectedBetButton, previous: self.previousBetButton)
            self.previousBetButton = self.selectedBetButton
            self.updatePotentialReward()
        }
        totalOverUnder.setTitle(S.Dice.OverUnder, for: .normal)
        totalOverUnder.tap = {
            guard self.selectedBetButton != self.totalOverUnder else { return }
            self.containerEqualNotEqual1.isHidden = true
            self.containerEqualNotEqual2.isHidden = true
            self.containerOverUnder1.isHidden = false
            self.containerOverUnder2.isHidden = false
            self.betLeft.setTitle(S.Dice.Over, for: .normal)
            self.betRight.setTitle(S.Dice.Under, for: .normal)
            self.selectedBetButton = self.totalOverUnder
            self.selectButton( selected: self.selectedBetButton, previous: self.previousBetButton)
            self.previousBetButton = self.selectedBetButton
            self.updatePotentialReward()
        }
        evenOdds.setTitle(S.Dice.EvenOdds, for: .normal)
        evenOdds.tap = {
            guard self.selectedBetButton != self.evenOdds else { return }
            self.containerEqualNotEqual1.isHidden = true
            self.containerEqualNotEqual2.isHidden = true
            self.containerOverUnder1.isHidden = true
            self.containerOverUnder2.isHidden = true
            self.betLeft.setTitle(S.Dice.Even, for: .normal)
            self.betRight.setTitle(S.Dice.Odds, for: .normal)
            self.selectedBetButton = self.evenOdds
            self.selectButton( selected: self.selectedBetButton, previous: self.previousBetButton)
            self.previousBetButton = self.selectedBetButton
            self.updatePotentialReward()
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
                self.selectedNButton = button
                self.selectButton( selected: self.selectedNButton, previous: self.previousNButton)
                self.previousNButton = self.selectedNButton
                self.updatePotentialReward()
            }
            setButtonStyle(button: button)
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
                self.selectedN5Button = button
                self.selectButton( selected: self.selectedN5Button, previous: self.previousN5Button)
                self.previousN5Button = self.selectedN5Button
                self.updatePotentialReward()
            }
            setButtonStyle(button: button)
            n+=1
        }
        
        betLeft.tap = {
            self.didTapBet(bLeft: true)
        }
        
        betRight.tap = {
            self.didTapBet(bLeft: false)
        }
        
        // initial buton status
        equalnotequalButtons[0].tap!()
        overunderButtons[0].tap!()
        equalNotEqual.tap!()
        
        // potential reward
        potentialRewardTitle.text = S.Dice.PotentialReward
    }
 
    private func updatePotentialReward()    {
        let newAmount = validateBetAmount()
        if newAmount != ""  {
            amount = newAmount
        }
        
        let potentialRewardData = potentialReward(stake: Int(Double(amount)!))
        potentialRewardLeft.text = String.init(format: "%@ (%@)", potentialRewardData.cryptoAmountLeft, potentialRewardData.fiatAmountLeft)
        potentialRewardRight.text = String.init(format: "%@ (%@)", potentialRewardData.cryptoAmountRight, potentialRewardData.fiatAmountRight)
    }
    
    // returns "" if valid, else if there is a new proposed amount
    private func validateBetAmount() -> String    {
        var ret : String = ""
        
        let balanceAmount = (Currencies.btc.state?.balance!.asUInt64)!/C.satoshis
        let minBet = Int(W.BetAmount.min)
        let maxBet = min(W.BetAmount.max, Float(balanceAmount) )
        let nAmount = Int( Double(amount) ?? Double(minBet) )

        if (nAmount <= minBet)  { ret = String(minBet) }
        if (Float(nAmount) > maxBet)  { ret = String(Int(maxBet)) }
        
        return ret
    }
    
    func potentialReward(stake: Int) -> (cryptoAmountLeft: String, fiatAmountLeft: String, cryptoAmountRight: String, fiatAmountRight: String )   {
        var oddLeft : Double = 0.0
        var oddRight : Double = 0.0
        
        switch selectedBetButton    {
        case equalNotEqual:
            guard let nIdx = equalnotequalButtons.index(of: selectedNButton!) else { return ( "","","","" ) }
            oddLeft = rewardEqual[nIdx]
            oddRight = rewardNotEqual[nIdx]
        
        case totalOverUnder:
            guard let nIdx = overunderButtons.index(of: selectedN5Button!) else { return ( "","","","" ) }
            oddLeft = rewardOverUnder[9-nIdx]
            oddRight = rewardOverUnder[nIdx]
        
        case evenOdds:
            oddLeft = rewardEvenOdd
            oddRight = rewardEvenOdd
        
        case .none:
            return ( "","","","" )
        case .some(_):
            return ( "","","","" )
        }
    
        let currency = Currencies.btc
        let rate = currency.state?.currentRate
        
        let cryptoAmountLeft: Double = Double(stake) * oddLeft
        let amountLeft = Amount(amount: UInt256(UInt64(cryptoAmountLeft * Double(C.satoshis))), currency: currency, rate: rate)
        let cryptoAmountRight: Double = Double(stake) * oddRight
        let amountRight = Amount(amount: UInt256(UInt64(cryptoAmountRight * Double(C.satoshis))), currency: currency, rate: rate)
        
        return (String.init(format: "%.2f %@", cryptoAmountLeft, currency.code), amountLeft.fiatDescription, String.init(format: "%.2f %@", cryptoAmountRight, currency.code), amountRight.fiatDescription)
    }
    
    private func selectButton(selected: UIButton!, previous: UIButton?) {
        selected.layer.borderColor = UIColor.red.cgColor
        selected.backgroundColor = .gradientStart
        if previous != nil   {
            previous!.layer.borderColor = UIColor.gray.cgColor
            previous!.backgroundColor = .gray
        }
    }
    
    private func addStyles() {
        addDiceIcon(button: diceLeft)
        addDiceIcon(button: diceRight)
        setButtonStyle(button: equalNotEqual)
        setButtonStyle(button: totalOverUnder)
        setButtonStyle(button: evenOdds)
        setButtonStyle(button: betLeft, active: true)
        setButtonStyle(button: betRight, active: true )
        
        betAmount.layer.borderWidth = 0
        //betAmount.layer.borderColor = UIColor.black.cgColor
        betAmount.backgroundColor = .whiteBackground
        betAmount.textColor = .primaryText
        betAmount.delegate = self
        betAmount.returnKeyType = UIReturnKeyType.done
        betAmount.keyboardType = UIKeyboardType.numberPad
        betAmount.font = UIFont.customBody(size: 22.0)
        
        let paddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 20))
        betAmount.leftView = paddingView
        betAmount.leftViewMode = .always
        addDoneButtonOnKeyboard()
        
        potentialRewardLeft.textColor = .white
        potentialRewardRight.textColor = .white
        potentialRewardTitle.textColor = .white
    }
    
    private func addDiceIcon( button : UIButton!) {
        button.setImage(#imageLiteral(resourceName: "BetDice"), for: .normal)
        button.frame = CGRect(x: 0.0, y: 12.0, width: 18.0, height: 18.0) // for iOS 10
        button.widthAnchor.constraint(equalToConstant: 18.0).isActive = true
        button.heightAnchor.constraint(equalToConstant: 18.0).isActive = true
        button.tintColor = .white
        button.imageView?.contentMode = .scaleAspectFit
    }
    
    private func setButtonStyle( button : UIButton!, active: Bool = false )   {
        button.layer.cornerRadius = 5.0
        button.layer.masksToBounds = true
        button.layer.borderWidth = 2.0
        button.layer.borderColor = UIColor.gray.cgColor
        button.isUserInteractionEnabled = true
        button.backgroundColor = active ? .gradientStart : .gray
        button.titleLabel!.font = UIFont.customBody(size: 14.0)
        button.setTitleColor(.white, for: .normal)
        button.titleEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
    }

    private func getDiceGameType( bLeft : Bool ) -> BetDiceGameType   {
        var ret : BetDiceGameType
        
        switch selectedBetButton    {
        case equalNotEqual:     ret = bLeft ? BetDiceGameType.EQUAL : BetDiceGameType.NOT_EQUAL
        case totalOverUnder:    ret = bLeft ? BetDiceGameType.TOTAL_OVER : BetDiceGameType.TOTAL_UNDER
        case evenOdds:          ret = bLeft ? BetDiceGameType.EVEN : BetDiceGameType.ODDS
        case .none:             ret = BetDiceGameType.UNKNOWN
        case .some(_):          ret = BetDiceGameType.UNKNOWN
        }
        return ret
    }
    
    private func getSelectedOutcome() -> Int32  {
        var ret : Int32 = 2 // default
        
        switch selectedBetButton {
        case equalNotEqual:     ret = Int32(equalnotequalButtons.index(of: selectedNButton!)! + 2)
        case totalOverUnder:    ret = Int32(overunderButtons.index(of: selectedN5Button!)! + 2)
        case evenOdds:          ret = 2
        case .none:             ret = 2
        case .some(_):          ret = 2
        }
        return ret
    }
    
    private func getSelectedOutcomeText() -> String  {
        var ret : String = ""
        
        switch selectedBetButton {
        case equalNotEqual:     ret = selectedNButton?.currentTitle ?? ""
        case totalOverUnder:    ret = selectedN5Button?.currentTitle ?? ""
        case evenOdds:          ret = ""
        case .none:             ret = ""
        case .some(_):          ret = ""
        }
        return ret
    }
    
    func didTapBet( bLeft: Bool ) {
        let betAmount = validateBetAmount()
        guard betAmount != "" else { return }
        
        guard !(currency.state?.isRescanning ?? false) else {
            let alert = UIAlertController(title: S.Alert.error, message: S.Send.isRescanning, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: S.Button.ok, style: .cancel, handler: nil))
            present(alert: alert)
            return
        }
        
        let diceGameType = getDiceGameType(bLeft: bLeft)
        let cryptoAmount = UInt256(UInt64(betAmount)! * C.satoshis)
        let transaction = walletManager.wallet?.createDiceBetTransaction(forAmount: (UInt64(betAmount)!*C.satoshis), type: BetType.QUICK_GAMES.rawValue, diceGameType: diceGameType.rawValue, selectedOutcome: getSelectedOutcome() )

        self.sender.setBetTransaction(tx: transaction)
        
        let fee = sender.fee(forAmount: cryptoAmount) ?? UInt256(0)
        let feeCurrency = Currencies.btc
        let currency = Currencies.btc
        
        let displyAmount = Amount(amount: cryptoAmount,
                                  currency: currency,
                                  rate: currency.state?.currentRate,
                                  maximumFractionDigits: Amount.highPrecisionDigits)
        let feeAmount = Amount(amount: fee,
                               currency: feeCurrency,
                               rate: (currency.state?.currentRate != nil) ? feeCurrency.state?.currentRate : nil,
                               maximumFractionDigits: Amount.highPrecisionDigits)

        let confirm = ConfirmationViewController(amount: Amount(amount: cryptoAmount, currency: currency),
                                                 fee: feeAmount,
                                                 feeType: .regular,
                                                 address: String.init(format: "%@ (%@ %@)", S.Dice.Dice, diceGameType.description, getSelectedOutcomeText() ),
                                                 isUsingBiometrics: sender.canUseBiometrics,
                                                 currency: currency)
        confirm.successCallback = doSend
        confirm.cancelCallback = sender.reset
        
        confirmTransitioningDelegate.shouldShowMaskView = false
        confirm.transitioningDelegate = confirmTransitioningDelegate
        confirm.modalPresentationStyle = .overFullScreen
        confirm.modalPresentationCapturesStatusBarAppearance = true
        doPresentConfirm!(confirm)
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

    func addDoneButtonOnKeyboard()
    {
        var doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle = UIBarStyle.blackTranslucent

        var flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        var done: UIBarButtonItem = UIBarButtonItem(title: S.RecoverWallet.done, style: UIBarButtonItemStyle.done, target: self, action: #selector(self.doneButtonAction))
        done.tintColor = .white

        var items = NSMutableArray()
        items.add(flexSpace)
        items.add(done)

        doneToolbar.items = items as! [UIBarButtonItem]
        doneToolbar.sizeToFit()

        self.betAmount.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction()
    {
        self.betAmount.resignFirstResponder()
        updatePotentialReward()
    }
    
    // amount text field delegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        updatePotentialReward()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        updatePotentialReward()
        return true
    }
    
    private func present(alert: UIAlertController) {
        Store.trigger(name: .showAlert(alert))
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
