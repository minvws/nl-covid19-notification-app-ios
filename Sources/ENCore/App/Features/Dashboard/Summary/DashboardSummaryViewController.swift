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
protocol DashboardSummaryRouting: Routing {
    // TODO: Add any routing functions that are called from the ViewController
    // func routeToChild()
}

final class DashboardSummaryViewController: ViewController, DashboardSummaryViewControllable, DashboardCardViewListener {

    // MARK: - Init

    init(listener: DashboardSummaryListener,
         theme: Theme) {
        self.listener = listener
        super.init(theme: theme)
    }

    // MARK: - DashboardSummaryViewControllable

    weak var router: DashboardSummaryRouting?
    weak var listener: DashboardSummaryListener?

    // MARK: - View Lifecycle

    override func loadView() {
        view = dashboardView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dashboardView.set(data: objects, listener: self)
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
    private var objects: [DashboardCard] {
        let positiveTestsCard = DashboardCardViewModel(identifier: .tests,
                                                       icon: .dashboardTestsIcon,
                                                       title: .dashboardPositiveTestResultsHeader,
                                                       graph: .init(values: (0 ..< 20).map { _ in UInt.random(in: 30000 ... 45000) }),
                                                       date: Date(),
                                                       displayedAmount: 54225)
        let activeUsersCard = DashboardCardViewModel(identifier: .users,
                                                     icon: .dashboardUsersIcon,
                                                     title: .dashboardCoronaMelderUsersHeader,
                                                     visual: .dashboardUsersIllustration!,
                                                     date: Date(),
                                                     displayedAmount: 2680672)
        let hospitalCard = DashboardCardViewModel(identifier: .hospitalAdmissions,
                                                  icon: .dashboardHospitalIcon,
                                                  title: .dashboardHospitalAdmissionsHeader,
                                                  graph: .init(values: (0 ..< 20).map { _ in UInt.random(in: 100 ... 250) }),
                                                  date: Date(timeIntervalSinceNow: -24 * 3600),
                                                  displayedAmount: 233)

        let vaccinationsCard = DashboardCardViewModel(identifier: .vaccinations,
                                                      icon: .dashboardVaccinationsIcon,
                                                      title: .dashboardVaccinationCoverageHeader,
                                                      bars: [(0.861, .dashboardVaccinationCoverageElderLabel), (0.533, .dashboardVaccinationCoverageBoosterLabel)])

        return [
            positiveTestsCard,
            activeUsersCard,
            hospitalCard,
            vaccinationsCard
        ]
    }

    // MARK: - DashboardCardViewListener

    func didSelect(identifier: DashboardIdentifier) {
        listener?.dashboardSummaryRequestsRouteToDetail(with: identifier)
    }
}

private final class DashboardView: View {

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

    // MARK: - Private

    fileprivate func set(data: [DashboardCard], listener: DashboardCardViewListener) {
        data.forEach {
            cardStackView.addArrangedSubview(DashboardCardView(listener: listener, theme: theme, viewModel: $0))
        }
    }

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
