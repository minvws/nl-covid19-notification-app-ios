/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

/// @mockable
protocol DashboardDetailRouting: Routing {
    // TODO: Add any routing functions that are called from the ViewController
    // func routeToChild()
}

final class DashboardDetailViewController: ViewController, DashboardDetailViewControllable {

    init(listener: DashboardDetailListener, identifier: DashboardIdentifier, theme: Theme) {
        self.listener = listener
        self.identifier = identifier
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
    }

    // MARK: - DashboardDetailViewControllable

    weak var router: DashboardDetailRouting?

    // MARK: - Private

    private weak var listener: DashboardDetailListener?
    private let identifier: DashboardIdentifier
    private lazy var internalView = DetailView(theme: self.theme)
}

private final class DetailView: View {

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

        titleLabel.text = .dashboardPositiveTestResultsHeader
        titleLabel.font = theme.fonts.title1
        titleLabel.numberOfLines = 0

        let summary: String = .dashboardPositiveTestResultsSummary(amount: "79.520", firstDate: "27 januari", secondDate: "3 februari", percentage: "59,3%")
        bodyLabel.attributedText = .makeFromHtml(text: summary, font: theme.fonts.body, textColor: theme.colors.textPrimary, textAlignment: .natural)
        bodyLabel.numberOfLines = 0

        outerStackView.addArrangedSubview(graphStackView)
        graphStackView.axis = .vertical
        graphStackView.spacing = 37

        graphHeaderStackView.axis = .horizontal
        graphHeaderStackView.spacing = 4

        let iconView = UIImageView(image: .dashboardTestsIcon)
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        graphHeaderLabel.text = .dashboardPositiveTestResultsHeader
        graphHeaderLabel.numberOfLines = 0
        graphHeaderLabel.font = theme.fonts.body

        graphHeaderStackView.addArrangedSubview(iconView)
        graphHeaderStackView.addArrangedSubview(graphHeaderLabel)

        let allDataButton = Button(title: .dashboardMoreInfoLink, theme: theme)
        allDataButton.style = .info
        allDataButton.contentHorizontalAlignment = .leading

        graphStackView.addArrangedSubview(graphHeaderStackView)
        graphStackView.addArrangedSubview(GraphView(theme: theme, data: GraphData(values: (0 ..< 20).map { _ in UInt.random(in: 100 ... 250) }), style: .normal))
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

        let now = currentDate()
        let date = Date(timeIntervalSinceNow: -3600 * 2)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        let dateString = dateFormatter.string(from: date)
        let daysAgo = now.days(sinceDate: date) ?? 0

        let dateText: String = .dashboardHighlightedDate(daysAgo: daysAgo, date: dateString)

        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = .decimal

        let percentageFormatter = NumberFormatter()
        percentageFormatter.locale = Locale.current
        percentageFormatter.numberStyle = .percent
        percentageFormatter.maximumFractionDigits = 1

        buttonStackView.addArrangedSubview(DashboardDetailButton(title: .dashboardPositiveTestResultsHeader, amountPrefix: dateText, amount: numberFormatter.string(from: 54225), icon: .dashboardTestsIcon, theme: theme) { _ in
            // TODO: forward tap
        })

        buttonStackView.addArrangedSubview(DashboardDetailButton(title: .dashboardCoronaMelderUsersHeader, amountPrefix: dateText, amount: numberFormatter.string(from: 2680672), icon: .dashboardUsersIcon, theme: theme) { _ in
            // TODO: forward tap
        })

        buttonStackView.addArrangedSubview(DashboardDetailButton(title: .dashboardHospitalAdmissionsHeader, amountPrefix: dateText, amount: numberFormatter.string(from: 898), icon: .dashboardHospitalIcon, theme: theme) { _ in
            // TODO: forward tap
        })

        buttonStackView.addArrangedSubview(DashboardDetailButton(title: .dashboardVaccinationCoverageHeader, amountPrefix: .dashboardVaccinationCoverageBoosterLabel, amount: percentageFormatter.string(from: 0.533), icon: .dashboardVaccinationsIcon, theme: theme) { _ in
            // TODO: forward tap
        })
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
    var handler: ((DashboardDetailButton) -> ())?

    static let shadowMargin = UIEdgeInsets(top: 2, left: 3, bottom: 4, right: 3)

    init(title: String, amountPrefix: String?, amount: String?, icon: UIImage?, theme: Theme, handler: ((DashboardDetailButton) -> ())? = nil) {
        self.theme = theme
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
        handler?(self)
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
