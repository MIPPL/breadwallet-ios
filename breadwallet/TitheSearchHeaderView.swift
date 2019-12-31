//
//  TitheHeaderView.swift
//  breadwallet
//
//  Created by MIP on 30/12/2019.
//  Copyright © 2019 Biblepay All rights reserved.
//

import UIKit

enum TitheSearchFilterType {
    case text(String)

    var description: String {
        switch self {
        case .text(_):
            return ""
        }
    }

    var filter: TitheFilter {
        switch self {
        case .text(let text):
            return { titheRow in
                let loweredText = text.lowercased()
                if titheRow.address.lowercased().contains(loweredText) {
                    return true
                }
                if titheRow.name.lowercased().contains(loweredText) {
                    return true
                }
                if titheRow.organizationType.lowercased().contains(loweredText)  {
                    return true
                }
                return false
            }
        }
    }
}

extension TitheSearchFilterType : Equatable {}

func ==(lhs: TitheSearchFilterType, rhs: TitheSearchFilterType) -> Bool {
    switch (lhs, rhs) {
    case (.text(_), .text(_)):
        return true
    }
}


typealias TitheFilter = (TitheRowModel) -> Bool

class TitheSearchHeaderView : UIView {

    init() {
        super.init(frame: .zero)
    }

    var didCancel: (() -> Void)?
    var didChangeFilters: (([TitheFilter]) -> Void)?
    var hasSetup = false

    func triggerUpdate() {
        didChangeFilters?(filters.map { $0.filter })
    }

    private let searchBar = UISearchBar()
    private let cancel = UIButton(type: .system)
    fileprivate var filters: [TitheSearchFilterType] = [] {
        didSet {
            didChangeFilters?(filters.map { $0.filter })
        }
    }

    override func layoutSubviews() {
        guard !hasSetup else { return }
        setup()
        hasSetup = true
    }

    private func setup() {
        addSubviews()
        //addFilterButtons()
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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TitheSearchHeaderView : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let filter: TitheSearchFilterType = .text(searchText)
        if let index = filters.index(of: filter) {
            filters.remove(at: index)
        }
        if searchText != "" {
            filters.append(filter)
        }
    }
}
