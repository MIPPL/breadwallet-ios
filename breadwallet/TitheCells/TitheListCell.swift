//
//  TitheListCell.swift
//  breadwallet
//
//  Created by MIP on 30/12/2019.
//  Copyright © 2019 Biblepay. All rights reserved.
//

import UIKit

class TitheListCell: UITableViewCell {

    // MARK: - Views
    
    private let name = UILabel(font: .customBody(size: 16.0), color: .darkText)
    private let type = UILabel(font: .customBody(size: 14.0), color: .darkText)
    private let address = UILabel(font: .customBold(size: 14.0))
    private let separator = UIView(color: .separatorGray)
    
    // MARK: Vars
    private var viewModel: TitheRowModel!
    
    // MARK: - Init
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    func setTitheRow(_ viewModel: TitheRowModel, isBtcSwapped: Bool, rate: Rate, maxDigits: Int, isSyncing: Bool) {
        self.viewModel = viewModel

        name.text = viewModel.name
        address.text = viewModel.address
        type.text = viewModel.organizationType
                
    }
    
    // MARK: - Private
    
    private func setupViews() {
        addSubviews()
        addConstraints()
        setupStyle()
    }
    
    private func addSubviews() {
        contentView.addSubview(name)
        contentView.addSubview(address)
        contentView.addSubview(type)
        contentView.addSubview(separator)
    }
    
    private func addConstraints() {
        name.constrain([
            name.topAnchor.constraint(equalTo: contentView.topAnchor, constant: C.padding[1]),
            name.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: C.padding[2])])
        type.constrain([
            type.topAnchor.constraint(equalTo: name.bottomAnchor, constant: C.padding[1]/2),
            type.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: C.padding[2])])
        address.constrain([
            address.topAnchor.constraint(equalTo: type.topAnchor),
            address.leadingAnchor.constraint(equalTo: type.trailingAnchor, constant: C.padding[2])])

        separator.constrainBottomCorners(height: 0.5)
    }
    
    private func setupStyle() {
        selectionStyle = .none
        name.lineBreakMode = .byTruncatingTail
        //type.textColor = .systemGray
        address.textColor = .systemGray
        address.lineBreakMode = .byTruncatingTail
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
