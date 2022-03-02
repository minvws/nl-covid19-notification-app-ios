/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import RxSwift
import SnapKit
import UIKit

/// @mockable
protocol DashboardRouting: Routing {
    // TODO: Add any routing functions that are called from the ViewController
    // func routeToChild()
}

final class DashboardViewController: ViewController, DashboardViewControllable {

    // MARK: - DashboardViewControllable

    weak var router: DashboardRouting?

    // MARK: - View Lifecycle

    override func loadView() {
        view = dashboardView
    }

    // TODO: Validate whether you need the below functions and remove or replace
    //       them as desired.

    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        present(viewController.uiviewController,
                animated: animated,
                completion: completion)
    }

    func dismiss(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        viewController.uiviewController.dismiss(animated: animated, completion: completion)
    }

    // MARK: - Private

    private lazy var dashboardView: DashboardView = DashboardView(theme: self.theme)
}

private final class DashboardView: View {
    weak var listener: DashboardListener?

    private var heightConstraint: NSLayoutConstraint?
    private var scrollView = UIScrollView()
    private var outerStackView = UIStackView()
    private var cardStackView = UIStackView()

    override init(theme: Theme) {
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        layer.zPosition = 10

        addSubview(outerStackView)

        outerStackView.addArrangedSubview(scrollView)

        cardStackView.axis = .horizontal
        cardStackView.spacing = 16
        cardStackView.distribution = .equalSpacing

        cardStackView.addArrangedSubview(DashboardCardView(theme: theme))
        cardStackView.addArrangedSubview(DashboardCardView(theme: theme))
        cardStackView.addArrangedSubview(DashboardCardView(theme: theme))
        cardStackView.addArrangedSubview(DashboardCardView(theme: theme))
        cardStackView.addArrangedSubview(DashboardCardView(theme: theme))

        scrollView.addSubview(cardStackView)
        scrollView.clipsToBounds = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    override func setupConstraints() {
        super.setupConstraints()

        heightConstraint = heightAnchor.constraint(equalToConstant: 0).withPriority(.defaultHigh + 100)

        outerStackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        cardStackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        scrollView.frameLayoutGuide.snp.makeConstraints { maker in
            maker.height.equalTo(cardStackView)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        evaluateHeight()
    }

    // MARK: - Internal

//    func update(with viewModel: StatusViewModel) {
//
//    }

    // MARK: - Private

    /// Calculates the desired height for the current content
    /// This is required for stretching
    private func evaluateHeight() {
        guard bounds.width > 0 else { return }

        heightConstraint?.isActive = false
        let size = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        heightConstraint?.constant = size.height
        heightConstraint?.isActive = true
    }
}

private final class DashboardCardView: View {

    static let shadowMargin = UIEdgeInsets(top: 8, left: 16, bottom: 24, right: 16)

    private let backgroundView = UIImageView(image: .dashboardCardBackground)
    private let contentLayoutGuide = UILayoutGuide()

    private lazy var graphView = GraphView(theme: theme, style: .compact)

    // MARK: - Overrides

    override func build() {
        super.build()

        addSubview(backgroundView)
        addSubview(graphView)
        addLayoutGuide(contentLayoutGuide)
    }

    override func setupConstraints() {
        super.setupConstraints()

        contentLayoutGuide.snp.makeConstraints { maker in
            maker.left.equalToSuperview().offset(16)
            maker.right.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(Self.shadowMargin.top + 16)
            maker.bottom.equalToSuperview().offset(-Self.shadowMargin.bottom - 16)
        }

        backgroundView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.left.equalToSuperview().offset(-Self.shadowMargin.left)
            maker.right.equalToSuperview().offset(Self.shadowMargin.right)
        }

        graphView.snp.makeConstraints { maker in
            maker.edges.equalTo(contentLayoutGuide)
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 256, height: 186 + Self.shadowMargin.top + Self.shadowMargin.bottom)
    }
}
