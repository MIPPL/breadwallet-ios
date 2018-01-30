//
//  TxStatusIndicator.swift
//  breadwallet
//
//  Created by Ehsan Rezaie on 2017-12-22.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit

class TxStatusIndicator: UIView {

    var status: TransactionStatus = .pending {
        didSet {
            updateStatus()
        }
    }
    
    let height: CGFloat = 7.0
    private let padding: CGFloat = -7.0
    let pipWidth: CGFloat = 84.0
    var width: CGFloat {
        return (pipWidth * 3) + (padding * 2)
    }
    
    private var pips = [StatusPip]()
    
    // MARK: Init
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    private func setup() {
        layer.cornerRadius = height / 2.0
        layer.masksToBounds = true
        backgroundColor = .statusIndicatorInactive
        
        for _ in 0..<3 {
            pips.append(StatusPip())
        }
        
        pips.reversed().forEach { pip in
            addSubview(pip)
        }
        
        setupContraints()
    }
    
    private func setupContraints() {
        pips.enumerated().forEach { index, pip in
            let leadingConstraint: NSLayoutConstraint?
            if index == 0 {
                leadingConstraint = pip.constraint(.leading, toView: self, constant: 0.0)
            } else {
                leadingConstraint = NSLayoutConstraint(item: pip,
                                                       attribute: .leading,
                                                       relatedBy: .equal,
                                                       toItem: pips[index - 1],
                                                       attribute: .trailing,
                                                       multiplier: 1.0,
                                                       constant: padding)
            }
            pip.constrain([
                pip.constraint(.width, constant: pipWidth),
                pip.constraint(.height, constant: height),
                pip.constraint(.centerY, toView: self, constant: nil),
                leadingConstraint ])
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -
    
    func updateStatus() {
        let activeIndex = pipCount(forStatus: status)
        pips.enumerated().forEach { index, pip in
            if index == activeIndex {
                pip.state = .flashing
            } else if index < activeIndex {
                pip.state = .on
            } else {
                pip.state = .off
            }
        }
    }
    
    private func pipCount(forStatus status: TransactionStatus) -> Int {
        switch status {
        case .pending:
            return 1
        case .confirmed:
            return 2
        case .complete:
            return 3
        default:
            return -1
        }
    }
}

