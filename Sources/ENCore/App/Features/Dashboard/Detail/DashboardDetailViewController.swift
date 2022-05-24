/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import CloudKit
import ENFoundation
import UIKit

/// @mockable
protocol DashboardDetailRouting: Routing {}

final class DashboardDetailViewController: ViewController, DashboardDetailViewControllable, Logging {

    init(listener: DashboardDetailListener, data: DashboardData, identifier: DashboardIdentifier, theme: Theme) {
        self.listener = listener
        self.identifier = identifier
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

        switch identifier {
        case .tests:
            guard let data = dashboardData.positiveTestResults else {
                return logError("No data for positiveTestResults")
            }

            internalView.configureForPositiveTests(with: data)

        case .users:
            guard let data = dashboardData.coronaMelderUsers else {
                return logError("No data for coronaMelderUsers")
            }

            internalView.configureForCoronaMelderUsers(with: data)

        case .hospitalAdmissions:
            guard let data = dashboardData.hospitalAdmissions else {
                return logError("No data for hospitalAdmissions")
            }

            internalView.configureForHospitalAdmissions(with: data)

        case .icuAdmissions:
            guard let data = dashboardData.icuAdmissions else {
                return logError("No data for icuAdmissions")
            }

            internalView.configureForIcuAdmissions(with: data)

        case .vaccinations:
            guard let data = dashboardData.vaccinationCoverage else {
                return logError("No data for vaccinationCoverage")
            }

            internalView.configureForVaccinationCoverage(with: data)
        default:
            break
        }

        internalView.setButtons(buttons)
    }

    // MARK: - DashboardDetailViewControllable

    weak var router: DashboardDetailRouting?

    // MARK: - Private

    private weak var listener: DashboardDetailListener?
    private let identifier: DashboardIdentifier
    private let dashboardData: DashboardData
    private lazy var internalView = DetailView(theme: self.theme)

    private var buttons: [DashboardDetailButton] {
        var buttonsWithSorting: [(button: DashboardDetailButton, sortingValue: Int)] = []

        func dateText(for date: Date) -> String {
            let daysAgo = currentDate().days(sinceDate: date) ?? 0
            let dateString = DetailView.dateFormatter.string(from: date)
            return .dashboardHighlightedDate(daysAgo: daysAgo, date: dateString)
        }

        let buttonHandler = { [listener] (identifier: DashboardIdentifier) -> () in
            listener?.dashboardDetailRequestsRouteToDetail(with: identifier)
        }

        dashboardData.positiveTestResults.map {
            buttonsWithSorting.append(
                (DashboardDetailButton(identifier: .tests,
                                       title: .dashboardPositiveTestResultsHeader,
                                       amountPrefix: dateText(for: $0.highlightedValue.date),
                                       amount: DetailView.numberFormatter.string(from: $0.highlightedValue.value as NSNumber),
                                       icon: .dashboardTestsIcon,
                                       theme: theme,
                                       handler: buttonHandler),
                 $0.sortingValue))
        }

        dashboardData.coronaMelderUsers.map {
            buttonsWithSorting.append(
                (DashboardDetailButton(identifier: .users,
                                       title: .dashboardCoronaMelderUsersHeader,
                                       amountPrefix: dateText(for: $0.highlightedValue.date),
                                       amount: DetailView.numberFormatter.string(from: $0.highlightedValue.value as NSNumber),
                                       icon: .dashboardUsersIcon,
                                       theme: theme,
                                       handler: buttonHandler),
                 $0.sortingValue))
        }

        dashboardData.hospitalAdmissions.map {
            buttonsWithSorting.append(
                (DashboardDetailButton(identifier: .hospitalAdmissions,
                                       title: .dashboardHospitalAdmissionsHeader,
                                       amountPrefix: dateText(for: $0.highlightedValue.date),
                                       amount: DetailView.numberFormatter.string(from: $0.highlightedValue.value as NSNumber),
                                       icon: .dashboardHospitalIcon,
                                       theme: theme,
                                       handler: buttonHandler),
                 $0.sortingValue))
        }

        dashboardData.icuAdmissions.map {
            buttonsWithSorting.append(
                (DashboardDetailButton(identifier: .icuAdmissions,
                                       title: .dashboardIcuAdmissionsHeader,
                                       amountPrefix: dateText(for: $0.highlightedValue.date),
                                       amount: DetailView.numberFormatter.string(from: $0.highlightedValue.value as NSNumber),
                                       icon: .dashboardIcuIcon,
                                       theme: theme,
                                       handler: buttonHandler),
                 $0.sortingValue))
        }

        dashboardData.vaccinationCoverage.map {
            buttonsWithSorting.append(
                (DashboardDetailButton(identifier: .vaccinations,
                                       title: .dashboardVaccinationCoverageHeader,
                                       amountPrefix: .dashboardVaccinationCoverageBoosterLabel,
                                       amount: DetailView.percentageFormatter.string(from: ($0.boosterCoverage18Plus / 100) as NSNumber),
                                       icon: .dashboardVaccinationsIcon,
                                       theme: theme,
                                       handler: buttonHandler),
                 $0.sortingValue))
        }

        return buttonsWithSorting
            .filter { $0.button.identifier != identifier }
            .sorted { $0.sortingValue < $1.sortingValue }
            .map(\.button)
    }
}

private final class DetailView: View {

    static var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()

    static var percentageFormatter: NumberFormatter = {
        let percentageFormatter = NumberFormatter()
        percentageFormatter.locale = Locale.current
        percentageFormatter.numberStyle = .percent
        percentageFormatter.maximumFractionDigits = 1
        return percentageFormatter
    }()

    static var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("d MMMM")
        return dateFormatter
    }()

    override func build() {
        super.build()

        scrollView.addSubview(outerStackView)
        scrollView.clipsToBounds = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        addSubview(scrollView)

        outerStackView.spacing = 32
        outerStackView.axis = .vertical

        outerStackView.addArrangedSubview(textStackView)

        textStackView.spacing = 16
        textStackView.axis = .vertical

        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(bodyLabel)

        titleLabel.font = theme.fonts.title1
        titleLabel.numberOfLines = 0

        bodyLabel.numberOfLines = 0

        outerStackView.addArrangedSubview(graphStackView)
        graphStackView.axis = .vertical
        graphStackView.spacing = 37

        graphHeaderStackView.axis = .horizontal
        graphHeaderStackView.spacing = 4

        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        graphHeaderLabel.text = .dashboardPositiveTestResultsHeader
        graphHeaderLabel.numberOfLines = 0
        graphHeaderLabel.font = theme.fonts.body

        graphHeaderStackView.addArrangedSubview(iconView)
        graphHeaderStackView.addArrangedSubview(graphHeaderLabel)

        // TODO: Handle button
        let allDataButton = Button(title: .dashboardMoreInfoLink, theme: theme)
        allDataButton.style = .info
        allDataButton.contentHorizontalAlignment = .leading

        graphStackView.addArrangedSubview(graphHeaderStackView)
        graphStackView.addArrangedSubview(allDataButton)

        outerStackView.addArrangedSubview(moreDataStackView)
        moreDataStackView.spacing = 16
        moreDataStackView.axis = .vertical

        moreDataStackView.addArrangedSubview(moreDataLabel)

        moreDataLabel.text = .dashboardMoreInfoHeader
        moreDataLabel.font = theme.fonts.title3
        moreDataLabel.numberOfLines = 0

        moreDataStackView.addArrangedSubview(buttonStackView)

        buttonStackView.axis = .vertical
        buttonStackView.spacing = 8
    }

    override func setupConstraints() {
        super.setupConstraints()

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

    func configureForPositiveTests(with data: DashboardData.PositiveTestResults) {
        titleLabel.text = .dashboardPositiveTestResultsHeader

        let summary: String = .dashboardPositiveTestResultsSummary(
            amount: Self.numberFormatter.string(from: data.movingAverage.value as NSNumber)!,
            firstDate: Self.dateFormatter.string(from: data.movingAverage.start),
            secondDate: Self.dateFormatter.string(from: data.movingAverage.end),
            percentage: Self.percentageFormatter.string(from: (data.infectedPercentage / 100) as NSNumber)!)

        bodyLabel.attributedText = .makeFromHtml(text: summary, font: theme.fonts.body, textColor: theme.colors.textPrimary, textAlignment: .natural)

        iconView.image = .dashboardTestsIcon

        graphHeaderLabel.text = .dashboardPositiveTestResultsHeader

        graphStackView.insertArrangedSubview(
            GraphView(theme: theme,
                      title: .dashboardPositiveTestResultsHeader,
                      data: GraphData(values: data.values),
                      style: .normal),
            at: 1)
    }

    func configureForCoronaMelderUsers(with data: DashboardData.CoronaMelderUsers) {
        titleLabel.text = .dashboardCoronaMelderUsersHeader

        let daysAgo = currentDate().days(sinceDate: data.highlightedValue.date) ?? 0

        let dateText: String = .dashboardHighlightedDate(daysAgo: daysAgo,
                                                         date: Self.dateFormatter.string(from: data.highlightedValue.date))

        let summary: String = .dashboardCoronaMelderUsersSummary(
            amount: Self.numberFormatter.string(from: data.highlightedValue.value as NSNumber)!,
            date: dateText)

        bodyLabel.attributedText = .makeFromHtml(text: summary, font: theme.fonts.body, textColor: theme.colors.textPrimary, textAlignment: .natural)

        iconView.image = .dashboardUsersIcon

        graphHeaderLabel.text = .dashboardCoronaMelderUsersHeader

        graphStackView.insertArrangedSubview(
            GraphView(theme: theme,
                      title: .dashboardCoronaMelderUsersHeader,
                      data: GraphData(values: data.values),
                      style: .normal),
            at: 1)
    }

    func configureForHospitalAdmissions(with data: DashboardData.HospitalAdmissions) {
        titleLabel.text = .dashboardHospitalAdmissionsHeader

        let summary: String = .dashboardHospitalAdmissionsSummary(
            amount: Self.numberFormatter.string(from: data.movingAverage.value as NSNumber)!,
            firstDate: Self.dateFormatter.string(from: data.movingAverage.start),
            secondDate: Self.dateFormatter.string(from: data.movingAverage.end))

        bodyLabel.attributedText = .makeFromHtml(text: summary, font: theme.fonts.body, textColor: theme.colors.textPrimary, textAlignment: .natural)

        iconView.image = .dashboardHospitalIcon

        graphHeaderLabel.text = .dashboardHospitalAdmissionsHeader

        graphStackView.insertArrangedSubview(
            GraphView(theme: theme,
                      title: .dashboardHospitalAdmissionsHeader,
                      data: GraphData(values: data.values),
                      style: .normal),
            at: 1)
    }

    func configureForIcuAdmissions(with data: DashboardData.IcuAdmissions) {
        titleLabel.text = .dashboardIcuAdmissionsHeader

        let summary: String = .dashboardIcuAdmissionsSummary(
            amount: Self.numberFormatter.string(from: data.movingAverage.value as NSNumber)!,
            firstDate: Self.dateFormatter.string(from: data.movingAverage.start),
            secondDate: Self.dateFormatter.string(from: data.movingAverage.end))

        bodyLabel.attributedText = .makeFromHtml(text: summary, font: theme.fonts.body, textColor: theme.colors.textPrimary, textAlignment: .natural)

        iconView.image = .dashboardIcuIcon

        graphHeaderLabel.text = .dashboardIcuAdmissionsHeader

        graphStackView.insertArrangedSubview(
            GraphView(theme: theme,
                      title: .dashboardIcuAdmissionsHeader,
                      data: GraphData(values: data.values),
                      style: .normal),
            at: 1)
    }

    func configureForVaccinationCoverage(with data: DashboardData.VaccinationCoverage) {
        titleLabel.text = .dashboardVaccinationCoverageHeader
        let fullyVaccinated = (data.vaccinationCoverage18Plus / 100) as NSNumber
        let boostered = (data.boosterCoverage18Plus / 100) as NSNumber
        let summary: String = .dashboardVaccinationCoverageSummary(
            fullyVacinated: Self.percentageFormatter.string(from: fullyVaccinated)!,
            boostered: Self.percentageFormatter.string(from: boostered)!)

        bodyLabel.attributedText = .makeFromHtml(text: summary, font: theme.fonts.body, textColor: theme.colors.textPrimary, textAlignment: .natural)

        iconView.image = .dashboardIcuIcon

        graphHeaderLabel.text = .dashboardVaccinationCoverageHeader

        graphStackView.insertArrangedSubview(
            GraphView(theme: theme,
                      title: .dashboardVaccinationCoverageHeader,
                      data: GraphData(values: data.values ?? []),
                      style: .normal),
            at: 1)
    }

    func setButtons(_ buttons: [DashboardDetailButton]) {
        buttons.forEach(buttonStackView.addArrangedSubview(_:))
    }

    // MARK: - Private

    private var scrollView = UIScrollView()
    private var outerStackView = UIStackView()
    private var textStackView = UIStackView()
    private var graphHeaderStackView = UIStackView()
    private var graphHeaderLabel = UILabel()
    private var graphStackView = UIStackView()
    private var titleLabel = UILabel()
    private var bodyLabel = UILabel()
    private var moreDataStackView = UIStackView()
    private var moreDataLabel = UILabel()
    private var buttonStackView = UIStackView()
    private var iconView = UIImageView()
}

private final class DashboardDetailButton: UIControl, Themeable {

    override var isHighlighted: Bool {
        didSet {
            UIButton.animate(withDuration: 0.2, animations: {
                let scale: CGFloat = self.isHighlighted ? 0.98 : 1
                self.transform = CGAffineTransform(scaleX: scale, y: scale)
            })
        }
    }

    let theme: Theme
    let identifier: DashboardIdentifier
    var handler: ((DashboardIdentifier) -> ())?

    static let shadowMargin = UIEdgeInsets(top: 2, left: 3, bottom: 4, right: 3)

    init(identifier: DashboardIdentifier,
         title: String,
         amountPrefix: String?,
         amount: String?,
         icon: UIImage?,
         theme: Theme,
         handler: @escaping (DashboardIdentifier) -> ()) {
        self.theme = theme
        self.identifier = identifier
        self.handler = handler

        super.init(frame: .zero)

        titleLabel.text = title
        amountPrefixLabel.text = amountPrefix
        amountLabel.text = amount
        iconView.image = icon

        build()
        setupConstraints()

        isAccessibilityElement = true
        accessibilityTraits = .button
        isExclusiveTouch = true

        setContentHuggingPriority(.required, for: .horizontal)
    }

    @available(*, unavailable, message: "NSCoder and Interface Builder is not supported. Use Programmatic layout.")
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private let backgroundView = UIImageView(image: .dashboardDetailButtonBackground)
    private let contentLayoutGuide = UILayoutGuide()

    private var graphView: GraphView!
    private let outerStackView = UIStackView()
    private let titleStackView = UIStackView()
    private let amountStackView = UIStackView()
    private let visualView = UIImageView()
    private let amountLabel = UILabel()
    private let titleLabel = UILabel()
    private let amountPrefixLabel = UILabel()
    private let iconView = UIImageView()

    @objc private func didTap() {
        Haptic.light()
        handler?(identifier)
    }

    private func build() {
        addTarget(self, action: #selector(didTap), for: .touchUpInside)

        addSubview(backgroundView)
        addLayoutGuide(contentLayoutGuide)
        addSubview(outerStackView)

        outerStackView.isUserInteractionEnabled = false

        outerStackView.axis = .horizontal
        outerStackView.spacing = 16
        outerStackView.alignment = .center

        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        outerStackView.addArrangedSubview(iconView)
        outerStackView.addArrangedSubview(titleStackView)

        titleStackView.axis = .vertical
        titleStackView.spacing = 4
        titleStackView.alignment = .leading
        titleStackView.addArrangedSubview(titleLabel)

        titleLabel.numberOfLines = 0
        titleLabel.font = theme.fonts.body

        amountPrefixLabel.font = theme.fonts.caption1
        amountPrefixLabel.textColor = theme.colors.captionGray

        amountLabel.numberOfLines = 0
        amountLabel.font = theme.fonts.caption1

        amountStackView.axis = .horizontal
        amountStackView.spacing = 4
        amountStackView.addArrangedSubview(amountPrefixLabel)
        amountStackView.addArrangedSubview(amountLabel)

        titleStackView.addArrangedSubview(amountStackView)
    }

    private func setupConstraints() {
        contentLayoutGuide.snp.makeConstraints { maker in
            maker.left.equalToSuperview().offset(16)
            maker.right.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(Self.shadowMargin.top + 16)
            maker.bottom.equalToSuperview().offset(-Self.shadowMargin.bottom - 16)
        }

        outerStackView.snp.makeConstraints { maker in
            maker.edges.equalTo(contentLayoutGuide)
        }

        backgroundView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.left.equalToSuperview().offset(-Self.shadowMargin.left)
            maker.right.equalToSuperview().offset(Self.shadowMargin.right)
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 256, height: 72 + Self.shadowMargin.top + Self.shadowMargin.bottom)
    }
}
