//
//  NodeSelectorViewController.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-08-03.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit
import BRCore

class BetSettingsViewController : UIViewController {

    var delegate : BetSettingsDelegate? = nil
    let titleLabel = UILabel(font: .customBold(size: 24.0), color: .darkText)
    //private let checkIncludeFee = UIButton(type: .system)
    private let checkIncludeFee = UISwitch(frame: CGRect(x: 163, y: 150, width: 0, height: 0))
    private let labelIncludeFee = UILabel(font: UIFont.customBody(size: 14.0), color: .primaryText)

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        setInitialData()
    }

    private func addSubviews() {
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "< Back", style: UIBarButtonItemStyle.bordered, target: self, action: #selector(self.back(sender:)))
        newBackButton.tintColor = .primaryText
        self.navigationItem.leftBarButtonItem = newBackButton
        
        view.addSubview(titleLabel)
        view.addSubview(checkIncludeFee)
        view.addSubview(labelIncludeFee)
    }

    @objc func back(sender: UIBarButtonItem) {
        delegate?.didTapBetSettingsBack()
        self.navigationController?.popViewController(animated: true)
    }
    
    private func addConstraints() {
        var padding = C.padding[2]
        if delegate != nil {
            padding = C.padding[10]
        }
        titleLabel.constrain([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2])
            ])
        
        checkIncludeFee.constrain([
            checkIncludeFee.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: C.padding[2]),
            checkIncludeFee.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]),
        ])
        
        labelIncludeFee.constrain([
            labelIncludeFee.topAnchor.constraint(equalTo: checkIncludeFee.topAnchor, constant: -C.padding[1]/2 ),
            labelIncludeFee.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[4]),
            labelIncludeFee.trailingAnchor.constraint(equalTo: checkIncludeFee.leadingAnchor, constant: -C.padding[2]),
        ])
    }

    private func setInitialData() {
        view.backgroundColor = .whiteBackground
        titleLabel.text = S.BetSettings.headerMessage
        titleLabel.textAlignment = .right
        labelIncludeFee.text = S.BetSettings.useFeeCheck
        labelIncludeFee.lineBreakMode = .byWordWrapping
        labelIncludeFee.numberOfLines = 2
        checkIncludeFee.tap = strongify(self) { myself in
            UserDefaults.showNetworkFeesInOdds = self.checkIncludeFee.isOn
        }
        
        self.checkIncludeFee.isOn = UserDefaults.showNetworkFeesInOdds
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}