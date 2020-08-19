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
        return helpManager.questions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: UITableViewCell
        let cellIdentifier = "helpCell"

        if let aCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
            cell = aCell
        } else {
            cell = HelpTableViewCell(theme: theme, reuseIdentifier: cellIdentifier)
        }

        let question = helpManager.questions[indexPath.row]

        cell.textLabel?.text = question.question
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
        guard (0 ..< helpManager.questions.count).contains(indexPath.row) else {
            return
        }

        let question = helpManager.questions[indexPath.row]
        listener?.helpOverviewRequestsRouteTo(question: question)

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
    private lazy var headerView: SectionHeaderView = SectionHeaderView(theme: self.theme)
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

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.showsVerticalScrollIndicator = true
        tableView.showsHorizontalScrollIndicator = false
        tableView.isScrollEnabled = true

        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension

        tableView.estimatedSectionHeaderHeight = 50
        tableView.sectionHeaderHeight = UITableView.automaticDimension

        tableView.allowsMultipleSelection = false
        tableView.tableFooterView = UIView()

        return tableView
    }()

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

private class HelpTableViewCell: UITableViewCell {

    init(theme: Theme, reuseIdentifier: String) {
        self.theme = theme
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        build()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func build() {
        separatorView.backgroundColor = theme.colors.tertiary
        addSubview(separatorView)
    }

    func setupConstraints() {
        separatorView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(14)
            maker.trailing.bottom.equalToSuperview()
            maker.height.equalTo(1)
        }

        textLabel?.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(16)
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.bottom.top.equalToSuperview().inset(12)
        }
    }

    // MARK: - Private

    private let separatorView = UIView()
    private let theme: Theme
}

private final class SectionHeaderView: View {

    lazy var label: Label = {
        let label = Label()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = theme.fonts.subheadBold
        label.textColor = self.theme.colors.primary
        label.accessibilityTraits = .header
        return label
    }()

    override func build() {
        super.build()

        addSubview(label)
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        label.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(16)
        }
    }
}
