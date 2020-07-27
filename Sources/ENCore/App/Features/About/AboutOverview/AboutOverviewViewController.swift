/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import SnapKit
import UIKit

final class AboutOverviewViewController: ViewController, UIAdaptivePresentationControllerDelegate, UITableViewDelegate, UITableViewDataSource {

    init(listener: AboutOverviewListener, aboutManager: AboutManaging, theme: Theme) {
        self.listener = listener
        self.aboutManager = aboutManager
        super.init(theme: theme)
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.aboutOverviewRequestsDismissal(shouldDismissViewController: false)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .popover

        internalView.tableView.dataSource = self
        internalView.tableView.delegate = self

        navigationItem.rightBarButtonItem = closeBarButtonItem
    }

    @objc func didTapClose() {
        listener?.aboutOverviewRequestsDismissal(shouldDismissViewController: true)
    }

    // MARK: - TableView

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == questionsSectionIndex {
            return aboutManager.questionsSection.questions.count
        } else {
            return aboutManager.aboutSection.questions.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let cellIdentifier = "AboutCell"
        let questions = indexPath.section == questionsSectionIndex ? aboutManager.questionsSection.questions : aboutManager.aboutSection.questions

        if let aCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
            cell = aCell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }

        cell.textLabel?.attributedText = questions[indexPath.row].attributedTitle
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = theme.fonts.body
        cell.textLabel?.accessibilityTraits = .header

        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == questionsSectionIndex {
            return questionsSectionHeader
        } else {
            return aboutSectionHeader
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let questions = indexPath.section == questionsSectionIndex ? aboutManager.questionsSection.questions : aboutManager.aboutSection.questions

        guard (0 ..< questions.count).contains(indexPath.row) else {
            return
        }

        let question = questions[indexPath.row]
        listener?.aboutOverviewRequestsRouteTo(question: question)

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Private

    private let questionsSectionIndex = 0
    private let aboutSectionIndex = 1
    private let aboutManager: AboutManaging
    private weak var listener: AboutOverviewListener?
    private lazy var internalView: AboutView = AboutView(theme: self.theme)

    private lazy var closeBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                          target: self,
                                                          action: #selector(didTapClose))

    private lazy var questionsSectionHeader: SectionHeaderView = {
        let headerView = SectionHeaderView(theme: theme)
        headerView.sectionHeaderLabel.text = aboutManager.questionsSection.title
        headerView.titleLabel.text = String.moreInformationAboutTitle

        let appInfoButton = CardButton(title: .aboutAppInformationTitle, subtitle: .aboutAppInformationDescription, image: UIImage.aboutAppInformation, type: .long, theme: theme)
        appInfoButton.backgroundColor = theme.colors.headerBackgroundBlue
        appInfoButton.action = { [weak self] in
            self?.listener?.aboutOverviewRequestsRouteToAppInformation()
        }

        let technicalInfoButton = CardButton(title: .aboutTechnicalInformationTitle, subtitle: .aboutTechnicalInformationDescription, image: UIImage.aboutTechnicalInformation, theme: theme)
        technicalInfoButton.backgroundColor = theme.colors.lightOrange
        technicalInfoButton.action = { [weak self] in
            self?.listener?.aboutOverviewRequestsRouteToTechnicalInformation()
        }

        headerView.addSections([appInfoButton, technicalInfoButton])

        return headerView
    }()

    private lazy var aboutSectionHeader: SectionHeaderView = {
        let headerView = SectionHeaderView(theme: theme)
        headerView.sectionHeaderLabel.text = aboutManager.aboutSection.title

        // TODO: add call callcenter button when strings are available

        return headerView
    }()
}

private final class AboutView: View {

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .clear

        tableView.showsVerticalScrollIndicator = true
        tableView.showsHorizontalScrollIndicator = false
        tableView.isScrollEnabled = true

        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension

        tableView.estimatedSectionHeaderHeight = 300
        tableView.sectionHeaderHeight = UITableView.automaticDimension

        tableView.allowsMultipleSelection = false
        tableView.tableFooterView = UIView()

        return tableView
    }()

    override func build() {
        super.build()

        addSubview(tableView)
    }

    override func setupConstraints() {
        super.setupConstraints()
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.top.bottom.equalToSuperview()
        }
    }
}

private final class SectionHeaderView: View {

    let titleLabel = Label(frame: .zero)
    let sectionHeaderLabel = Label(frame: .zero)

    override func build() {
        super.build()

        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits = .header
        titleLabel.font = theme.fonts.largeTitle
        titleLabel.accessibilityTraits = .header

        sectionHeaderLabel.numberOfLines = 0
        sectionHeaderLabel.accessibilityTraits = .header
        sectionHeaderLabel.font = theme.fonts.subheadBold
        sectionHeaderLabel.textColor = theme.colors.primary

        addSubview(titleLabel)
        addSubview(stackView)
        addSubview(sectionHeaderLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.top.equalToSuperview().inset(16)
        }

        stackView.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
            maker.leading.trailing.equalToSuperview().inset(16)
        }

        sectionHeaderLabel.snp.makeConstraints { maker in
            maker.top.equalTo(stackView.snp.bottom).offset(16)
            maker.leading.trailing.bottom.equalToSuperview().inset(16)
        }
    }

    func addSections(_ views: [UIView]) {
        for view in views {
            stackView.addArrangedSubview(view)
        }
    }

    // MARK: - Private

    private let stackView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 16
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
}
