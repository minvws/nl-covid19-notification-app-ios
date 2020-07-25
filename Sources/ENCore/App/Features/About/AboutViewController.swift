/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import SnapKit
import UIKit
import WebKit

/// @mockable
protocol AboutRouting: Routing {}

final class AboutViewController: ViewController, AboutViewControllable, UIAdaptivePresentationControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    weak var router: AboutRouting?

    init(listener: AboutListener, theme: Theme) {
        self.listener = listener
        super.init(theme: theme)
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.aboutRequestsDismissal(shouldHideViewController: false)
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
        listener?.aboutRequestsDismissal(shouldHideViewController: true)
    }

    // MARK: - TableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let cellIdentifier = "AboutCell"

        if let aCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
            cell = aCell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }

        cell.textLabel?.text = "An example cell"
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = theme.fonts.body
        cell.textLabel?.accessibilityTraits = .header

        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        return firstSectionHeader
    }

    // MARK: - Private

    private weak var listener: AboutListener?
    private lazy var internalView: AboutView = AboutView(theme: self.theme)

    private lazy var closeBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                          target: self,
                                                          action: #selector(didTapClose))

    private lazy var firstSectionHeader: SectionHeaderView = {
        let headerView = SectionHeaderView(theme: theme)
        headerView.sectionHeaderLabel.text = "First section Header"
        headerView.titleLabel.text = String.moreInformationAboutTitle

        let button = CardButton(title: "This is a test title", subtitle: "And a test subtile to check layout", image: UIImage.githubLogo, theme: theme)
        button.backgroundColor = theme.colors.inactive
        headerView.addSections([button])

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
