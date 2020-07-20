/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import SnapKit
import UIKit

open class View: UIView, Themeable {

    public let theme: Theme

    // MARK: - Init

    init(theme: Theme) {
        self.theme = theme
        super.init(frame: .zero)

        configure()
    }

    @available(*, unavailable, message: "Use `init(theme:)`")
    init() {
        fatalError("Not Supported")
    }

    @available(*, unavailable, message: "Use `init(theme:)`")
    override public init(frame: CGRect) {
        fatalError("Not Supported")
    }

    @available(*, unavailable, message: "NSCoder and Interface Builder is not supported. Use Programmatic layout.")
    public required init?(coder: NSCoder) {
        fatalError("Not Supported")
    }

    var hasBottomMargin: Bool = false {
        didSet {
            setBottomMargin()
        }
    }

    private var bottomMargin: Float = 0
    private var bottomConstraint: Constraint?

    func constrainToSuperViewWithBottomMargin(maker: ConstraintMaker) {
        bottomConstraint = maker.bottom.equalToSuperview().inset(bottomMargin).constraint
    }

    func constrainToSafeLayoutGuidesWithBottomMargin(maker: ConstraintMaker) {
        bottomConstraint = maker.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).inset(bottomMargin).constraint
    }

    override open func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()

        setBottomMargin()
    }

    private func setBottomMargin() {
        guard hasBottomMargin else { return }

        bottomMargin = safeAreaInsets.bottom == 0 ? 20 : 0
        bottomConstraint?.update(inset: bottomMargin)
    }

    // MARK: - Internal

    func configure() {

        build()
        setupConstraints()
    }

    open func build() {
        backgroundColor = theme.colors.viewControllerBackground
    }

    open func setupConstraints() {}
}
