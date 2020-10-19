/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import SnapKit
import UIKit

class HelpTableView: UITableView {

    init() {
        super.init(frame: .zero, style: .grouped)
        translatesAutoresizingMaskIntoConstraints = false

        separatorStyle = .none
        backgroundColor = .clear

        showsVerticalScrollIndicator = true
        showsHorizontalScrollIndicator = false
        isScrollEnabled = true

        estimatedRowHeight = 100
        rowHeight = UITableView.automaticDimension

        estimatedSectionHeaderHeight = 50
        sectionHeaderHeight = UITableView.automaticDimension

        allowsMultipleSelection = false
        tableFooterView = UIView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class HelpTableViewCell: UITableViewCell {

    init(theme: Theme, reuseIdentifier: String) {
        self.theme = theme
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        build()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func build() {
        separatorView.backgroundColor = theme.colors.tertiary
        addSubview(separatorView)
    }

    func setupConstraints() {
        separatorView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(14)
            maker.trailing.bottom.equalToSuperview()
            maker.height.equalTo(1)
        }

        textLabel?.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(16)
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.bottom.top.equalToSuperview().inset(14)
        }
    }

    // MARK: - Private

    private let separatorView = UIView()
    private let theme: Theme
}

final class HelpTableViewSectionHeaderView: View {

    lazy var label: Label = {
        let label = Label()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = theme.fonts.subheadBold
        label.textColor = self.theme.colors.primary
        label.accessibilityTraits = .header
        return label
    }()

    override func build() {
        super.build()

        addSubview(label)
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        label.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(16)
        }
    }
}
