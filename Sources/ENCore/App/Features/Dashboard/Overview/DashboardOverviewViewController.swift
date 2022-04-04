/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import SnapKit
import UIKit

/// @mockable
protocol DashboardOverviewRouting: Routing {}

final class DashboardOverviewViewController: ViewController, DashboardOverviewViewControllable, DashboardCardViewListener {

    init(listener: DashboardOverviewListener, theme: Theme) {
        self.listener = listener
        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        view = internalView
        view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .popover

        navigationItem.rightBarButtonItem = navigationController?.navigationItem.rightBarButtonItem

        internalView.set(data: objects, listener: self)
    }

    // MARK: - DashboardOverviewViewControllable

    // MARK: - DashboardCardViewListener

    func didSelect(identifier: DashboardIdentifier) {
        listener?.dashboardOverviewRequestsRouteToDetail(with: identifier)
    }

    // MARK: - Private

    private weak var listener: DashboardOverviewListener?
    private lazy var internalView = OverviewView(theme: self.theme)
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
}

private final class OverviewView: View {

    override func build() {
        super.build()

        addSubview(scrollView)

        outerStackView.spacing = 16
        outerStackView.axis = .vertical

        currentSituationLabel.text = .dashboardHeader
        currentSituationLabel.font = theme.fonts.title1
        currentSituationLabel.numberOfLines = 0

        headerBackgroundView.addSubview(headerLabel)
        headerBackgroundView.backgroundColor = theme.colors.dashboardHeaderBackground
        headerBackgroundView.layer.cornerRadius = 4

        headerLabel.textColor = theme.colors.dashboardHeaderText
        headerLabel.text = .dashboardTitle.uppercased()
        headerLabel.font = theme.fonts.caption1Bold

        headerStackView.addArrangedSubview(currentSituationLabel)
        headerStackView.addArrangedSubview(headerBackgroundView)

        headerStackView.axis = .vertical
        headerStackView.spacing = 9
        headerStackView.alignment = .leading

        summaryLabel.text = .dashboardSummaryText
        summaryLabel.font = theme.fonts.body
        summaryLabel.numberOfLines = 0

        outerStackView.addArrangedSubview(headerStackView)
        outerStackView.addArrangedSubview(summaryLabel)
        outerStackView.addArrangedSubview(currentSituationLabelContainer)
        outerStackView.addArrangedSubview(cardStackView)

        cardStackView.axis = .vertical
        cardStackView.spacing = -16

        scrollView.addSubview(outerStackView)
        scrollView.clipsToBounds = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    override func setupConstraints() {
        super.setupConstraints()

        headerLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(2)
            maker.bottom.equalToSuperview().offset(-2)
            maker.left.equalToSuperview().offset(4)
            maker.right.equalToSuperview().offset(-4)
        }

        outerStackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        scrollView.snp.makeConstraints { maker in
            maker.edges.equalTo(safeAreaLayoutGuide)
        }

        scrollView.frameLayoutGuide.snp.makeConstraints { maker in
            maker.width.equalTo(outerStackView).offset(scrollView.contentInset.left + scrollView.contentInset.right)
        }
    }

    // MARK: - Private

    private var scrollView = UIScrollView()
    private var outerStackView = UIStackView()
    private var cardStackView = UIStackView()
    private var headerStackView = UIStackView()
    private var headerBackgroundView = UIView()
    private var headerLabel = UILabel()
    private var summaryLabel = UILabel()
    private var currentSituationLabelContainer = UIView()
    private var currentSituationLabel = UILabel()

    fileprivate func set(data: [DashboardCard], listener: DashboardCardViewListener) {
        data.forEach {
            cardStackView.addArrangedSubview(DashboardCardView(listener: listener, theme: theme, viewModel: $0))
        }
    }
}
