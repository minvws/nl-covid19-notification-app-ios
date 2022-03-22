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
    private var headerContainer = UIView()
    private var headerStackView = UIStackView()
    private var headerBackgroundView = UIView()
    private var headerLabel = UILabel()
    private var currentSituationLabelContainer = UIView()
    private var currentSituationLabel = UILabel()

    override init(theme: Theme) {
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        layer.zPosition = 10

        addSubview(outerStackView)

        outerStackView.spacing = 3
        outerStackView.axis = .vertical

        headerBackgroundView.addSubview(headerLabel)
        headerBackgroundView.backgroundColor = theme.colors.dashboardHeaderBackground
        headerBackgroundView.layer.cornerRadius = 4

        headerLabel.textColor = theme.colors.dashboardHeaderText
        headerLabel.text = .dashboardTitle.uppercased()
        headerLabel.font = theme.fonts.caption1Bold

        currentSituationLabel.text = .dashboardHeader
        currentSituationLabel.font = theme.fonts.headlineBold

        headerStackView.addArrangedSubview(headerBackgroundView)
        headerStackView.addArrangedSubview(currentSituationLabel)

        headerStackView.axis = .vertical
        headerStackView.spacing = 9
        headerStackView.alignment = .leading

        headerContainer.addSubview(headerStackView)

        outerStackView.addArrangedSubview(headerContainer)
        outerStackView.addArrangedSubview(currentSituationLabelContainer)
        outerStackView.addArrangedSubview(scrollView)

        cardStackView.axis = .horizontal
        cardStackView.spacing = 16
        cardStackView.distribution = .equalSpacing

        let positiveTestsCard = DashboardCardView(theme: theme,
                                                  config: .init(icon: .dashboardTestsIcon,
                                                                title: .dashboardPositiveTestResultsHeader,
                                                                graph: .init(values: (0 ..< 20).map { _ in UInt.random(in: 30000 ... 45000) }),
                                                                date: Date(),
                                                                displayedAmount: 54225))
        let activeUsersCard = DashboardCardView(theme: theme,
                                                config: .init(icon: .dashboardUsersIcon,
                                                              title: .dashboardCoronaMelderUsersHeader,
                                                              visual: .dashboardUsersIllustration!,
                                                              date: Date(),
                                                              displayedAmount: 2680672))
        let hospitalCard = DashboardCardView(theme: theme,
                                             config: .init(icon: .dashboardHospitalIcon,
                                                           title: .dashboardHospitalAdmissionsHeader,
                                                           graph: .init(values: (0 ..< 20).map { _ in UInt.random(in: 100 ... 250) }),
                                                           date: Date(timeIntervalSinceNow: -24 * 3600),
                                                           displayedAmount: 233))

        let vaccinationsCard = DashboardCardView(theme: theme,
                                                 config: .init(icon: .dashboardVaccinationsIcon,
                                                               title: .dashboardVaccinationCoverageHeader,
                                                               bars: [(0.861, .dashboardVaccinationCoverageElderLabel), (0.533, .dashboardVaccinationCoverageBoosterLabel)]))

        cardStackView.addArrangedSubview(positiveTestsCard)
        cardStackView.addArrangedSubview(activeUsersCard)
        cardStackView.addArrangedSubview(hospitalCard)
        cardStackView.addArrangedSubview(vaccinationsCard)

        scrollView.addSubview(cardStackView)
        scrollView.clipsToBounds = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    override func setupConstraints() {
        super.setupConstraints()

        heightConstraint = heightAnchor.constraint(equalToConstant: 0).withPriority(.defaultHigh + 100)

        headerLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(2)
            maker.bottom.equalToSuperview().offset(-2)
            maker.left.equalToSuperview().offset(4)
            maker.right.equalToSuperview().offset(-4)
        }

        headerStackView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(0)
            maker.bottom.equalToSuperview().offset(0)
            maker.left.equalToSuperview().offset(16)
            maker.right.equalToSuperview().offset(-16)
        }

        outerStackView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(16)
            maker.bottom.equalToSuperview()
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
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

    struct Config {
        let icon: UIImage?
        let title: String
        let visual: UIImage?
        let graph: GraphData?
        let bars: [(amount: Double, title: String)]?
        let date: Date?
        let displayedAmount: Int?

        init(icon: UIImage?, title: String, visual: UIImage, date: Date, displayedAmount: Int) {
            self.icon = icon
            self.title = title
            self.visual = visual
            self.date = date
            self.displayedAmount = displayedAmount

            self.graph = nil
            self.bars = nil
        }

        init(icon: UIImage?, title: String, graph: GraphData, date: Date, displayedAmount: Int) {
            self.icon = icon
            self.title = title
            self.graph = graph
            self.date = date
            self.displayedAmount = displayedAmount

            self.visual = nil
            self.bars = nil
        }

        init(icon: UIImage?, title: String, bars: [(amount: Double, title: String)]) {
            self.icon = icon
            self.title = title
            self.bars = bars

            self.date = nil
            self.displayedAmount = nil
            self.graph = nil
            self.visual = nil
        }
    }

    static let shadowMargin = UIEdgeInsets(top: 8, left: 16, bottom: 24, right: 16)

    private let backgroundView = UIImageView(image: .dashboardCardBackground)
    private let contentLayoutGuide = UILayoutGuide()

    private var graphView: GraphView!
    private let outerStackView = UIStackView()
    private let titleStackView = UIStackView()
    private let amountStackView = UIStackView()
    private let visualView = UIImageView()
    private let amountLabel = UILabel()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let chevron = UIImageView(image: .chevron)
    private let config: Config

    init(theme: Theme, config: Config) {
        self.config = config

        super.init(theme: theme)

        setContentHuggingPriority(.required, for: .horizontal)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        addSubview(backgroundView)
        addLayoutGuide(contentLayoutGuide)
        addSubview(outerStackView)

        outerStackView.axis = .vertical
        outerStackView.spacing = 8

        titleLabel.text = config.title
        titleLabel.numberOfLines = 0
        titleLabel.font = theme.fonts.subheadBold

        let iconView = UIImageView(image: config.icon)
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleStackView.spacing = 4
        titleStackView.alignment = .top
        titleStackView.addArrangedSubview(iconView)
        titleStackView.addArrangedSubview(titleLabel)

        if let date = config.date {
            let now = currentDate()
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none

            let dateString = dateFormatter.string(from: date)
            let daysAgo = now.days(sinceDate: date) ?? 0

            dateLabel.text = .dashboardHighlightedDate(daysAgo: daysAgo, date: dateString)
            dateLabel.font = theme.fonts.caption1
            dateLabel.textColor = theme.colors.captionGray
        } else {
            dateLabel.isHidden = true
        }

        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = .decimal

        amountLabel.text = numberFormatter.string(for: config.displayedAmount)
        amountLabel.numberOfLines = 0
        amountLabel.font = theme.fonts.title2

        outerStackView.addArrangedSubview(titleStackView)

        if let graph = config.graph {
            graphView = GraphView(theme: theme, data: graph, style: .compact)
            outerStackView.addArrangedSubview(graphView)
        }

        outerStackView.addArrangedSubview(visualView)

        if let visual = config.visual {
            visualView.image = visual
            visualView.contentMode = .right
        } else {
            visualView.isHidden = true
        }

        if let bars = config.bars {
            let barViews = bars.map { BarView(theme: theme, amount: $0.amount, label: $0.title) }

            let barStackView = UIStackView(arrangedSubviews: barViews)
            barStackView.spacing = 16
            barStackView.axis = .vertical

            outerStackView.addArrangedSubview(barStackView)
        }

        outerStackView.addArrangedSubview(dateLabel)
        outerStackView.addArrangedSubview(amountStackView)

        amountStackView.axis = .horizontal
        amountStackView.addArrangedSubview(amountLabel)
        amountStackView.addArrangedSubview(chevron)

        chevron.contentMode = .center
    }

    override func setupConstraints() {
        super.setupConstraints()

        contentLayoutGuide.snp.makeConstraints { maker in
            maker.left.equalToSuperview().offset(16)
            maker.right.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(Self.shadowMargin.top + 16)
            maker.bottom.equalToSuperview().offset(-Self.shadowMargin.bottom - 16)
        }

        outerStackView.snp.makeConstraints { maker in
            maker.edges.equalTo(contentLayoutGuide)
        }

        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.setContentCompressionResistancePriority(.required, for: .horizontal)

        backgroundView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.left.equalToSuperview().offset(-Self.shadowMargin.left)
            maker.right.equalToSuperview().offset(Self.shadowMargin.right)
        }

        visualView.snp.makeConstraints { maker in
            maker.height.equalTo(48).priority(.high)
        }

        amountStackView.snp.makeConstraints { maker in
            maker.height.greaterThanOrEqualTo(27)
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 256, height: 186 + Self.shadowMargin.top + Self.shadowMargin.bottom)
    }
}

private final class BarView: View {

    private let percentageLabel = UILabel()
    private let titleLabel = UILabel()
    private let stackView = UIStackView()

    private let amount: Double
    private let label: String

    private let barContainerView = UIView()
    private let barFillView = UIView()

    init(theme: Theme, amount: Double, label: String) {
        self.amount = amount
        self.label = label

        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        stackView.addArrangedSubview(percentageLabel)
        stackView.addArrangedSubview(titleLabel)
        stackView.spacing = 4

        addSubview(stackView)

        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = .percent
        numberFormatter.maximumFractionDigits = 1

        percentageLabel.text = numberFormatter.string(from: NSNumber(value: amount))
        percentageLabel.font = theme.fonts.caption1Bold
        percentageLabel.setContentHuggingPriority(.required, for: .horizontal)

        titleLabel.text = label
        titleLabel.font = theme.fonts.caption1
        titleLabel.textColor = theme.colors.captionGray
        titleLabel.numberOfLines = 0

        addSubview(barContainerView)
        barContainerView.layer.cornerRadius = 4
        barContainerView.backgroundColor = theme.colors.graphFill

        barFillView.layer.cornerRadius = 4
        barFillView.backgroundColor = theme.colors.graphStroke
        barContainerView.addSubview(barFillView)
    }

    override func setupConstraints() {
        stackView.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview().offset(-12)
        }

        barContainerView.snp.makeConstraints { maker in
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.height.equalTo(8)
        }

        barFillView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.left.equalToSuperview()
            maker.width.equalToSuperview().multipliedBy(amount)
        }
    }
}
