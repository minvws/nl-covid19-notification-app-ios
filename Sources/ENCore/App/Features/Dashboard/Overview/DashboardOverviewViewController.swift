/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import SnapKit
import UIKit

/// @mockable
protocol DashboardOverviewRouting: Routing {
    // TODO: Add any routing functions that are called from the ViewController
    // func routeToChild()
}

final class DashboardOverviewViewController: ViewController, DashboardOverviewViewControllable {

    init(listener: DashboardOverviewListener, theme: Theme) {
        self.listener = listener
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

        internalView.addButton(title: "Tests") { [weak self] in
            self?.listener?.dashboardOverviewRequestsRouteToDetail(with: .tests)
        }

        internalView.addButton(title: "Users") { [weak self] in
            self?.listener?.dashboardOverviewRequestsRouteToDetail(with: .users)
        }

        internalView.addButton(title: "Hospital") { [weak self] in
            self?.listener?.dashboardOverviewRequestsRouteToDetail(with: .hospitalAdmissions)
        }

        internalView.addButton(title: "Vaccinations") { [weak self] in
            self?.listener?.dashboardOverviewRequestsRouteToDetail(with: .vaccinations)
        }
    }

    // MARK: - DashboardOverviewViewControllable

    weak var router: DashboardOverviewRouting?

    // TODO: Validate whether you need the below functions and remove or replace
    //       them as desired.

    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        present(viewController.uiviewController,
                animated: animated,
                completion: completion)
    }

    func dismiss(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        viewController.uiviewController.dismiss(animated: animated, completion: completion)
    }

    // MARK: - Private

    private weak var listener: DashboardOverviewListener?
    private lazy var internalView = OverviewView(theme: self.theme)
}

private final class OverviewView: View {
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
