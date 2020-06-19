/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

final class HelpOverviewViewController: ViewController, UITableViewDelegate, UITableViewDataSource {
    init(listener: HelpOverviewListener,
         helpManager: HelpManaging,
         theme: Theme) {

        self.listener = listener
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

        internalView.titleLabel.text = Localized("helpTitle")
        internalView.subtitleLabel.text = Localized("helpSubtitle")

        internalView.closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        internalView.acceptButton.addTarget(self, action: #selector(acceptButtonPressed), for: .touchUpInside)
        internalView.tableView.delegate = self
        internalView.tableView.dataSource = self
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return helpManager.questions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: UITableViewCell
        let cellIdentifier = "helpCell"

        if let aCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
            cell = aCell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }

        let question = helpManager.questions[indexPath.row]

        cell.textLabel?.text = question.question
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = .systemFont(ofSize: 17)

        cell.accessoryType = .disclosureIndicator

        cell.indentationLevel = 1
        cell.indentationWidth = 5

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard (0 ..< helpManager.questions.count).contains(indexPath.row) else {
            return
        }

        let question = helpManager.questions[indexPath.row]
        listener?.helpOverviewRequestsRouteTo(question: question)

        tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc func closeButtonPressed() {
        listener?.helpOverviewRequestsDismissal(shouldDismissViewController: true)
    }

    @objc func acceptButtonPressed() {
        listener?.helpOverviewDidTapEnableAppButton()
    }

    // MARK: - Private

    private weak var listener: HelpOverviewListener?
    private let helpManager: HelpManaging
    private lazy var internalView: HelpView = HelpView(theme: self.theme)
}

private final class HelpView: View {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 28, weight: .bold)
        return label
    }()

    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = self.theme.colors.primary
        return label
    }()

    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "CloseButton"), for: .normal)
        return button
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.showsVerticalScrollIndicator = true
        tableView.showsHorizontalScrollIndicator = false
        tableView.isScrollEnabled = true

        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension

        tableView.allowsMultipleSelection = false

        return tableView
    }()

    lazy var acceptButton: Button = {
        let button = Button(theme: self.theme)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.style = .primary
        button.title = Localized("helpAcceptButtonTitle")
        return button
    }()

    private lazy var viewsInDisplayOrder = [closeButton, titleLabel, subtitleLabel, tableView, acceptButton]

    override func build() {
        super.build()

        viewsInDisplayOrder.forEach { addSubview($0) }
    }

    override func setupConstraints() {
        super.setupConstraints()

        var constraints = [[NSLayoutConstraint]()]

        constraints.append([
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            closeButton.heightAnchor.constraint(equalToConstant: 50),
            closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor)
        ])

        constraints.append([
            titleLabel.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 0),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 25)
        ])

        constraints.append([
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 25),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            subtitleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 25)
        ])

        constraints.append([
            tableView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 15),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: acceptButton.topAnchor, constant: 0)
        ])

        constraints.append([
            acceptButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50),
            acceptButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            acceptButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            acceptButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        for constraint in constraints { NSLayoutConstraint.activate(constraint) }
    }
}
