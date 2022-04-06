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

    init(listener: DashboardOverviewListener, data: DashboardData, theme: Theme) {
        self.listener = listener
        self.dashboardData = data
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
    private let dashboardData: DashboardData
    private var objects: [DashboardCard] {
        var objects = [(card: DashboardCard, sortingValue: Int)]()

        dashboardData.positiveTestResults.map {
            objects.append(
                (DashboardCardViewModel(identifier: .tests,
                                        icon: .dashboardTestsIcon,
                                        title: .dashboardPositiveTestResultsHeader,
                                        graph: .init(values: $0.values),
                                        date: $0.highlightedValue.date,
                                        displayedAmount: $0.highlightedValue.value),
                 $0.sortingValue))
        }

        dashboardData.coronaMelderUsers.map {
            objects.append(
                (DashboardCardViewModel(identifier: .users,
                                        icon: .dashboardUsersIcon,
                                        title: .dashboardCoronaMelderUsersHeader,
                                        visual: .dashboardUsersIllustration!,
                                        date: $0.highlightedValue.date,
                                        displayedAmount: $0.highlightedValue.value),
                 $0.sortingValue))
        }

        dashboardData.hospitalAdmissions.map {
            objects.append(
                (DashboardCardViewModel(identifier: .hospitalAdmissions,
                                        icon: .dashboardHospitalIcon,
                                        title: .dashboardHospitalAdmissionsHeader,
                                        graph: .init(values: $0.values),
                                        date: $0.highlightedValue.date,
                                        displayedAmount: $0.highlightedValue.value),
                 $0.sortingValue))
        }

        dashboardData.icuAdmissions.map {
            objects.append(
                (DashboardCardViewModel(identifier: .icuAdmissions,
                                        icon: .dashboardIcuIcon,
                                        title: .dashboardIcuAdmissionsHeader,
                                        graph: .init(values: $0.values),
                                        date: $0.highlightedValue.date,
                                        displayedAmount: $0.highlightedValue.value),
                 $0.sortingValue))
        }

        dashboardData.vaccinationCoverage.map {
            objects.append(
                (DashboardCardViewModel(identifier: .vaccinations,
                                        icon: .dashboardVaccinationsIcon,
                                        title: .dashboardVaccinationCoverageHeader,
                                        bars: [
                                            ($0.vaccinationCoverage18Plus / 100, .dashboardVaccinationCoverageElderLabel),
                                            ($0.boosterCoverage18Plus / 100, .dashboardVaccinationCoverageBoosterLabel)
                                        ]),
                 $0.sortingValue))
        }

        return objects
            .sorted { $0.sortingValue < $1.sortingValue }
            .map(\.card)
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
