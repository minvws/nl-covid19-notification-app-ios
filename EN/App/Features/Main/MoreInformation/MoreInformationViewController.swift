/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

final class MoreInformationViewController: ViewController, MoreInformationViewControllable, MoreInformationTableListener {
    private enum MoreInformationCellIdentifier: CaseIterable {
        case aboutApp
        case receivedNotification
        case requestTest
        case infected
    }

    init(listener: MoreInformationListener,
         theme: Theme,
         tableController: MoreInformationTableControlling) {
        self.tableController = tableController
        self.listener = listener

        super.init(theme: theme)
    }

    // MARK: - View Lifecycle

    override func loadView() {
        self.view = moreInformationView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
    }

    // MARK: - MoreInformationTableListener

    func didSelect(cell: MoreInformationCell, at index: Int) {
        guard (0 ..< cells.keys.count).contains(index) else { return }

        switch MoreInformationCellIdentifier.allCases[index] {
        case .aboutApp:
            listener?.moreInformationRequestsAbout()
        case .infected:
            listener?.moreInformationRequestsInfected()
        case .receivedNotification:
            listener?.moreInformationRequestsReceivedNotification()
        case .requestTest:
            listener?.moreInformationRequestsRequestTest()
        }
    }

    // MARK: - Private

    private func setupTableView() {
        moreInformationView.tableView.delegate = tableController.delegate
        moreInformationView.tableView.dataSource = tableController.dataSource

        tableController.listener = self

        let cells = MoreInformationCellIdentifier.allCases.compactMap { identifier in
            return self.cells[identifier]
        }
        tableController.set(cells: cells)

        moreInformationView.tableView.reloadData()
        moreInformationView.updateHeightConstraint()
    }

    @objc
    func didTapRequestTestButton() {
        listener?.moreInformationRequestsRequestTest()
    }

    private var cells: [MoreInformationCellIdentifier: MoreInformationCell] {
        // dummy data
        let aboutAppModel = MoreInformationCellViewModel(icon: UIImage(),
                                                         title: "Over de app",
                                                         description: "Hoe de app werkt en wat dit voor je privacy betekent.")

        let receivedNotificationModel = MoreInformationCellViewModel(icon: UIImage(),
                                                                     title: "Een melding ontvangen?",
                                                                     description: "Wat je kunt doen nadat iemand anders het virus blijkt te hebben.")

        let requestTestModel = MoreInformationCellViewModel(icon: UIImage(),
                                                            title: "Coronatest aanvragen",
                                                            description: "Waarschuw anderen anoniem meteen nadat je hoort dat je besmet bent.")

        let infectedModel = MoreInformationCellViewModel(icon: UIImage(),
                                                         title: "Ik ben besmet",
                                                         description: "Zo laat je anderen weten dat je positief getest bent")

        return [
            .aboutApp: aboutAppModel,
            .receivedNotification: receivedNotificationModel,
            .requestTest: requestTestModel,
            .infected: infectedModel
        ]
    }

    private lazy var moreInformationView: MoreInformationView = MoreInformationView(theme: self.theme)

    private weak var listener: MoreInformationListener?
    private let tableController: MoreInformationTableControlling
}

private final class MoreInformationView: View {
    fileprivate let tableView = UITableView()
    private var heightConstraint: NSLayoutConstraint?

    override func build() {
        super.build()

        addSubview(tableView)

        tableView.isScrollEnabled = false
        tableView.estimatedRowHeight = 100
    }

    override func setupConstraints() {
        super.setupConstraints()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.setContentCompressionResistancePriority(.required, for: .vertical)

        let constraints = [
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        heightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate(constraints)
    }

    fileprivate func updateHeightConstraint() {
        heightConstraint = tableView.heightAnchor.constraint(equalToConstant: tableView.contentSize.height)
        heightConstraint?.isActive = true
    }
}
