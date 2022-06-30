/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import RxSwift
import UIKit

/// @mockable
protocol DashboardRouting: Routing {
    func routeToOverview(with data: DashboardData)
    func routeToDetail(with identifier: DashboardIdentifier, data: DashboardData, animated: Bool)
    func routeToExternalURL(_ url: URL)
}

final class DashboardViewController: NavigationController, DashboardViewControllable, UIAdaptivePresentationControllerDelegate {

    weak var router: DashboardRouting?

    init(listener: DashboardListener,
         theme: Theme,
         identifier: DashboardIdentifier,
         dataController: ExposureDataControlling) {
        self.listener = listener
        self.startIdentifer = identifier
        self.dataController = dataController
        super.init(theme: theme)

        navigationItem.rightBarButtonItem = closeBarButtonItem
        presentationController?.delegate = self
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.dashboardRequestsDismissal(shouldDismissViewController: false)
    }

    @objc func didTapClose() {
        listener?.dashboardRequestsDismissal(shouldDismissViewController: true)
    }

    // MARK: - DashboardViewControllable

    func push(viewController: ViewControllable, animated: Bool) {
        pushViewController(viewController.uiviewController, animated: animated)
    }

    func replaceSameOrPush(viewController: ViewControllable, animated: Bool) {
        guard
            let topViewController = viewControllers.last,
            type(of: topViewController) == type(of: viewController.uiviewController) else {
            return push(viewController: viewController, animated: animated)
        }

        let currentViewControllers = viewControllers.dropLast()

        setViewControllers(currentViewControllers + [viewController.uiviewController], animated: animated)
    }

    // MARK: - ViewController Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard viewControllers.isEmpty else { return }

        dataController
            .getDashboardData()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in
                guard let self = self else { return }
                self.dashboardData = $0
                self.performInitialRoute(with: $0)
            }, onFailure: { [weak self] error in
                guard let self = self else { return }
                // Close on error
                self.didTapClose()
            }).disposed(by: disposeBag)
    }

    // MARK: - DashboardOverviewListener

    func dashboardOverviewRequestsRouteToDetail(with identifier: DashboardIdentifier) {
        guard let data = dashboardData else { return }
        router?.routeToDetail(with: identifier, data: data, animated: true)
    }

    // MARK: - DashboardDetailListener

    func dashboardDetailRequestsRouteToDetail(with identifier: DashboardIdentifier) {
        guard let data = dashboardData else { return }
        router?.routeToDetail(with: identifier, data: data, animated: true)
    }

    func dashboardDetailRequestsRouteToURL(_ url: URL) {
        router?.routeToExternalURL(url)
    }

    // MARK: - Private

    func performInitialRoute(with data: DashboardData) {
        switch startIdentifer {
        case .overview:
            router?.routeToOverview(with: data)
        default:
            router?.routeToDetail(with: startIdentifer, data: data, animated: false)
        }
    }

    private var dashboardData: DashboardData?
    private var disposeBag = DisposeBag()
    private let dataController: ExposureDataControlling
    private let startIdentifer: DashboardIdentifier
    private weak var listener: DashboardListener?
    private lazy var closeBarButtonItem = UIBarButtonItem.closeButton(target: self, action: #selector(didTapClose))
}
