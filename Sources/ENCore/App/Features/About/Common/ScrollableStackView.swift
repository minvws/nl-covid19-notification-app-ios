/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import SnapKit
import UIKit

final class ScrollableStackView: View {

    var attributedTitle: NSAttributedString? {
        didSet {
            titleLabel.attributedText = attributedTitle
        }
    }

    var spacing: CGFloat {
        get {
            stackView.spacing
        } set {
            stackView.spacing = newValue
        }
    }

    var stackViewBottomMargin: CGFloat = 0 {
        didSet {
            updateStackViewConstraints()
        }
    }

    override func build() {
        super.build()

        isAccessibilityElement = false

        stackView.isAccessibilityElement = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 40
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits = .header
        titleLabel.font = theme.fonts.largeTitle
        titleLabel.accessibilityTraits = .header

        scrollView.isAccessibilityElement = false
        addSubview(scrollView)
        scrollView.addSubview(stackView)

        titleView.addSubview(titleLabel)
        addSections([titleView])
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        scrollView.snp.makeConstraints { maker in
            maker.top.leading.trailing.bottom.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview().inset(16)
            maker.bottom.equalToSuperview()
        }

        updateStackViewConstraints()
    }

    private func updateStackViewConstraints() {
        stackView.snp.updateConstraints { maker in
            maker.top.leading.trailing.width.equalTo(scrollView)
            maker.bottom.equalTo(scrollView).inset(stackViewBottomMargin)
        }
    }

    func addSections(_ views: [UIView]) {
        for view in views {
            stackView.addArrangedSubview(view)
        }
    }

    // MARK: - Private

    private var stackViewBottomConstraint: Constraint?
    private let scrollView = UIScrollView(frame: .zero)
    private let stackView = UIStackView(frame: .zero)
    private let titleLabel = Label(frame: .zero)
    private lazy var titleView = View(theme: theme)
}
