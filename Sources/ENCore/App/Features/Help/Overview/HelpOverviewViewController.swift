/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import UIKit

final class HelpOverviewViewController: ViewController, UITableViewDelegate, UITableViewDataSource {

    init(listener: HelpOverviewListener,
         shouldShowEnableAppButton: Bool,
         helpManager: HelpManaging,
         theme: Theme) {

        self.listener = listener
        self.shouldShowEnableAppButton = shouldShowEnableAppButton
        self.helpManager = helpManager

        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        internalView.titleLabel.text = .helpTitle
        headerView.label.text = .helpSubtitle

        internalView.acceptButton.addTarget(self, action: #selector(acceptButtonPressed), for: .touchUpInside)

        internalView.acceptButton.isHidden = !shouldShowEnableAppButton

        internalView.tableView.delegate = self
        internalView.tableView.dataSource = self

        navigationItem.rightBarButtonItem = navigationController?.navigationItem.rightBarButtonItem
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return helpManager.entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: UITableViewCell
        let cellIdentifier = "helpCell"

        if let aCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
            cell = aCell
        } else {
            cell = HelpTableViewCell(theme: theme, reuseIdentifier: cellIdentifier)
        }

        let entry = helpManager.entries[indexPath.row]

        cell.textLabel?.text = entry.title
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = theme.fonts.body
        cell.textLabel?.accessibilityTraits = .header

        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard (0 ..< helpManager.entries.count).contains(indexPath.row) else {
            return
        }

        let entry = helpManager.entries[indexPath.row]
        listener?.helpOverviewRequestsRouteTo(entry: entry)

        tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc func acceptButtonPressed() {
        listener?.helpOverviewDidTapEnableAppButton()
    }

    // MARK: - Private

    private weak var listener: HelpOverviewListener?
    private let shouldShowEnableAppButton: Bool
    private let helpManager: HelpManaging
    private lazy var internalView: HelpView = HelpView(theme: self.theme)
    private lazy var headerView: HelpTableViewSectionHeaderView = HelpTableViewSectionHeaderView(theme: self.theme)
}

private final class HelpView: View {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = theme.fonts.largeTitle
        label.accessibilityTraits = .header
        return label
    }()

    lazy var tableView = HelpTableView()

    lazy var acceptButton: Button = {
        let button = Button(theme: self.theme)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.style = .primary
        button.title = .helpAcceptButtonTitle
        return button
    }()

    private lazy var viewsInDisplayOrder = [titleLabel, tableView, acceptButton]

    override func build() {
        super.build()

        viewsInDisplayOrder.forEach { addSubview($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        var constraints = [[NSLayoutConstraint]()]

        constraints.append([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 25)
        ])

        constraints.append([
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: acceptButton.topAnchor, constant: 0)
        ])

        constraints.append([
            acceptButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            acceptButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            acceptButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            acceptButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        for constraint in constraints { NSLayoutConstraint.activate(constraint) }
    }
}
