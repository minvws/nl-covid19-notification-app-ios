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

        if identifier != .tests {
            internalView.addButton(title: "Tests") { [weak self] in
                self?.listener?.dashboardDetailRequestsRouteToDetail(with: .tests)
            }
        }

        if identifier != .users {
            internalView.addButton(title: "Users") { [weak self] in
                self?.listener?.dashboardDetailRequestsRouteToDetail(with: .users)
            }
        }

        if identifier != .hospitalAdmissions {
            internalView.addButton(title: "Hospital") { [weak self] in
                self?.listener?.dashboardDetailRequestsRouteToDetail(with: .hospitalAdmissions)
            }
        }

        if identifier != .vaccinations {
            internalView.addButton(title: "Vaccinations") { [weak self] in
                self?.listener?.dashboardDetailRequestsRouteToDetail(with: .vaccinations)
            }
        }
    }

    // MARK: - DashboardDetailViewControllable

    weak var router: DashboardDetailRouting?

    // MARK: - Private

    private weak var listener: DashboardDetailListener?
    private let identifier: DashboardIdentifier
    private lazy var internalView = DetailView(theme: self.theme)
}

private final class DetailView: View {
    private lazy var stackView = UIStackView()
    private var buttonHandlers = [() -> ()]()

    override func build() {
        super.build()

        addSubview(stackView)
        stackView.axis = .vertical
        stackView.spacing = 16
    }

    func addButton(title: String, handler: @escaping () -> ()) {
        let button = Button(title: title, theme: theme)
        button.addTarget(self, action: #selector(handleButton), for: .touchUpInside)
        button.tag = buttonHandlers.count

        stackView.addArrangedSubview(button)
        buttonHandlers.append(handler)
    }

    @objc private func handleButton(_ sender: Button) {
        buttonHandlers[sender.tag]()
    }

    override func setupConstraints() {
        super.setupConstraints()

        stackView.snp.makeConstraints { maker in
            maker.top.equalTo(safeAreaLayoutGuide)
            maker.left.equalTo(safeAreaLayoutGuide).offset(16)
            maker.right.equalTo(safeAreaLayoutGuide).offset(-16)
        }
    }
}
