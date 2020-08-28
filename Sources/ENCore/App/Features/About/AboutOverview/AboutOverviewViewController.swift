/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import SnapKit
import UIKit

final class AboutOverviewViewController: ViewController, Logging, UITableViewDelegate, UITableViewDataSource {

    init(listener: AboutOverviewListener, aboutManager: AboutManaging, theme: Theme) {
        self.listener = listener
        self.aboutManager = aboutManager
        super.init(theme: theme)
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

        aboutManager.didUpdate = {
            self.internalView.tableView.reloadData()
        }

        navigationItem.rightBarButtonItem = self.navigationController?.navigationItem.rightBarButtonItem
    }

    // MARK: - TableView

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == questionsSectionIndex {
            return aboutManager.questionsSection.entries.count
        } else {
            return aboutManager.aboutSection.entries.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let cellIdentifier = "AboutCell"
        let questions = indexPath.section == questionsSectionIndex ? aboutManager.questionsSection.entries : aboutManager.aboutSection.entries

        if let aCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
            cell = aCell
        } else {
            cell = HelpTableViewCell(theme: theme, reuseIdentifier: cellIdentifier)
        }

        cell.textLabel?.text = questions[indexPath.row].title
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = theme.fonts.body
        cell.textLabel?.textColor = theme.colors.gray
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
        let entries = indexPath.section == questionsSectionIndex ? aboutManager.questionsSection.entries : aboutManager.aboutSection.entries

        guard (0 ..< entries.count).contains(indexPath.row) else {
            return
        }

        tableView.deselectRow(at: indexPath, animated: true)

        listener?.aboutOverviewRequestsRouteTo(entry: entries[indexPath.row])
    }

    // MARK: - Private

    private let questionsSectionIndex = 0
    private let aboutSectionIndex = 1
    private let aboutManager: AboutManaging
    private weak var listener: AboutOverviewListener?
    private lazy var internalView: AboutView = AboutView(theme: self.theme)

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

        let helpdeskButton = CardButton(title: .aboutHelpdeskTitle, subtitle: .aboutHelpdeskSubtitle, image: UIImage.aboutHelpdesk, theme: theme)
        helpdeskButton.backgroundColor = theme.colors.headerBackgroundBlue
        helpdeskButton.action = { [weak self] in
            if let url = URL(string: .helpDeskPhoneNumber), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                self?.logError("Unable to open \(String.helpDeskPhoneNumber)")
            }
        }

        headerView.addSections([helpdeskButton])

        return headerView
    }()
}

private final class AboutView: View {

    lazy var tableView = HelpTableView()

    override func build() {
        super.build()

        addSubview(tableView)
    }

    override func setupConstraints() {
        super.setupConstraints()
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
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
            maker.top.equalTo(stackView.snp.bottom).offset(40)
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
