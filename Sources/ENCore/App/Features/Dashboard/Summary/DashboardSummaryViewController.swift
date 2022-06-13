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
protocol DashboardSummaryRouting: Routing {}

final class DashboardSummaryViewController: ViewController, DashboardSummaryViewControllable, DashboardCardViewListener {

    // MARK: - Init

    init(listener: DashboardSummaryListener,
         theme: Theme,
         dataController: ExposureDataControlling,
         interfaceOrientationStream: InterfaceOrientationStreaming,
         exposureStateStream: ExposureStateStreaming) {
        self.listener = listener
        self.dataController = dataController
        self.interfaceOrientationStream = interfaceOrientationStream
        self.exposureStateStream = exposureStateStream
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

        dataController
            .getDashboardData()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in
                guard let self = self else { return }
                self.dashboardView.set(data: $0.convertToCards(), listener: self)
            }, onFailure: { error in
                // TODO: Handle
            }).disposed(by: disposeBag)

        interfaceOrientationStream
            .isLandscape
            .subscribe { [weak self] isLandscape in
                self?.dashboardView.landscapeOrientation = isLandscape
            }.disposed(by: disposeBag)

        exposureStateStream.exposureState
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.updateDashboardState()
            }).disposed(by: disposeBag)

        updateDashboardState()
    }

    // MARK: - Private

    private var disposeBag = DisposeBag()
    private let dataController: ExposureDataControlling
    private let interfaceOrientationStream: InterfaceOrientationStreaming
    private let exposureStateStream: ExposureStateStreaming
    private lazy var dashboardView: DashboardView = DashboardView(theme: self.theme)

    private func updateDashboardState() {
        dashboardView.showCompact = exposureStateStream.currentExposureState.shouldShowCompactDashboardView
    }

    // MARK: - DashboardCardViewListener

    func didSelect(identifier: DashboardIdentifier) {
        listener?.dashboardSummaryRequestsRouteToDetail(with: identifier)
    }
}

private extension DashboardData {

    func convertToCards() -> [DashboardCard] {
        var objects = [(card: DashboardCard, sortingValue: Int)]()

        positiveTestResults.map {
            objects.append(
                (DashboardCardViewModel(identifier: .tests,
                                        icon: .dashboardTestsIcon,
                                        title: .dashboardPositiveTestResultsHeader,
                                        graph: .init(values: $0.values),
                                        date: $0.highlightedValue.date,
                                        displayedAmount: $0.highlightedValue.value),
                 $0.sortingValue))
        }

        coronaMelderUsers.map {
            objects.append(
                (DashboardCardViewModel(identifier: .users,
                                        icon: .dashboardUsersIcon,
                                        title: .dashboardCoronaMelderUsersHeader,
                                        visual: .dashboardUsersIllustration!,
                                        date: $0.highlightedValue.date,
                                        displayedAmount: $0.highlightedValue.value),
                 $0.sortingValue))
        }

        hospitalAdmissions.map {
            objects.append(
                (DashboardCardViewModel(identifier: .hospitalAdmissions,
                                        icon: .dashboardHospitalIcon,
                                        title: .dashboardHospitalAdmissionsHeader,
                                        graph: .init(values: $0.values),
                                        date: $0.highlightedValue.date,
                                        displayedAmount: $0.highlightedValue.value),
                 $0.sortingValue))
        }

        icuAdmissions.map {
            objects.append(
                (DashboardCardViewModel(identifier: .icuAdmissions,
                                        icon: .dashboardIcuIcon,
                                        title: .dashboardIcuAdmissionsHeader,
                                        graph: .init(values: $0.values),
                                        date: $0.highlightedValue.date,
                                        displayedAmount: $0.highlightedValue.value),
                 $0.sortingValue))
        }

        vaccinationCoverage.map {
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

private extension ExposureState {

    var shouldShowCompactDashboardView: Bool {
        switch (activeState, notifiedState) {
        case (.active, .notNotified):
            return false
        case (_, _):
            return true
        }
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
    private var currentSituationLabel = UILabel()
    private lazy var compactView = DashboardCompactView(theme: theme)

    private var landscapeConstraints = [NSLayoutConstraint]()

    override init(theme: Theme) {
        landscapeOrientation = false
        showCompact = false
        super.init(theme: theme)
    }

    var landscapeOrientation: Bool {
        didSet {
            landscapeConstraints.forEach { $0.isActive = landscapeOrientation }
            evaluateHeight()
        }
    }

    var showCompact: Bool {
        didSet {
            compactView.isHidden = !showCompact
            headerContainer.isHidden = showCompact
            scrollView.isHidden = showCompact
            evaluateHeight()
        }
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        layer.zPosition = 10

        addSubview(outerStackView)

        outerStackView.spacing = 12
        outerStackView.axis = .vertical

        headerBackgroundView.addSubview(headerLabel)
        headerBackgroundView.backgroundColor = theme.colors.dashboardHeaderBackground
        headerBackgroundView.layer.cornerRadius = 4

        headerLabel.textColor = theme.colors.dashboardHeaderText
        headerLabel.text = .dashboardTitle.uppercased()
        headerLabel.font = theme.fonts.caption1Bold
        headerLabel.setContentHuggingPriority(.required, for: .vertical)
        headerLabel.accessibilityTraits = .header

        currentSituationLabel.text = .dashboardHeader
        currentSituationLabel.font = theme.fonts.headlineBold
        currentSituationLabel.setContentHuggingPriority(.required, for: .vertical)
        currentSituationLabel.accessibilityTraits = .header

        headerStackView.addArrangedSubview(headerBackgroundView)
        headerStackView.addArrangedSubview(currentSituationLabel)

        headerStackView.axis = .vertical
        headerStackView.spacing = 9
        headerStackView.alignment = .leading

        headerContainer.addSubview(headerStackView)

        outerStackView.addArrangedSubview(compactView)
        outerStackView.addArrangedSubview(headerContainer)
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
            maker.left.equalTo(safeAreaLayoutGuide)
            maker.right.equalTo(safeAreaLayoutGuide)
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
        compactView.listener = listener

        data.forEach {
            let cardView = DashboardCardView(listener: listener, theme: theme, viewModel: $0)
            cardStackView.addArrangedSubview(cardView)
            setupConstraints(for: cardView)
        }
    }

    private func setupConstraints(for cardView: DashboardCardView) {
        cardView.snp.makeConstraints { maker in
            maker.width.equalTo(scrollView.frameLayoutGuide)
                .offset(-64)
                .priority(800)
        }

        let landscapeConstraint = cardView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5)
        landscapeConstraint.isActive = landscapeOrientation
        landscapeConstraints.append(landscapeConstraint)
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

private final class DashboardCompactView: UIControl, Themeable {

    override var isHighlighted: Bool {
        didSet {
            UIButton.animate(withDuration: 0.2, animations: {
                let scale: CGFloat = self.isHighlighted ? 0.98 : 1
                self.transform = CGAffineTransform(scaleX: scale, y: scale)
            })
        }
    }

    let theme: Theme

    init(theme: Theme) {
        self.theme = theme

        super.init(frame: .zero)

        build()
        setupConstraints()

        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    @available(*, unavailable, message: "NSCoder and Interface Builder is not supported. Use Programmatic layout.")
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func build() {
        addTarget(self, action: #selector(didTap), for: .touchUpInside)

        containerView.isUserInteractionEnabled = false

        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        containerView.backgroundColor = theme.colors.cardBackgroundBlue

        outerStackView.axis = .vertical
        outerStackView.spacing = 8

        addSubview(containerView)
        containerView.addSubview(outerStackView)
        containerView.addSubview(illustration)

        outerStackView.addArrangedSubview(titleLabel)
        outerStackView.addArrangedSubview(subtitleLabel)

        titleLabel.text = .dashboardHeader
        titleLabel.numberOfLines = 0
        titleLabel.font = theme.fonts.title3

        subtitleLabel.text = .dashboardSummaryCardText
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = theme.fonts.body
    }

    private func setupConstraints() {

        containerView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.left.equalToSuperview().offset(16)
            maker.right.equalToSuperview().offset(-16)
            maker.height.greaterThanOrEqualTo(illustration).offset(17)
        }

        outerStackView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(16)
            maker.bottom.equalToSuperview().offset(-16).priority(.low)
            maker.left.equalToSuperview().offset(16)
            maker.right.equalToSuperview().offset(-88)
        }

        illustration.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview()
            maker.right.equalToSuperview()
        }
    }

    @objc private func didTap() {
        Haptic.light()
        listener?.didSelect(identifier: .overview)
    }

    private lazy var containerView = View(theme: theme)
    private let outerStackView = UIStackView()
    private let titleLabel = Label()
    private let subtitleLabel = Label()
    private let illustration = UIImageView(image: .dashboardCompactIllustration)

    weak var listener: DashboardCardViewListener?
}
