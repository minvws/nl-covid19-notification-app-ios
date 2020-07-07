/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import CoreBluetooth
import UIKit

/// @mockable
protocol MainRouting: Routing {
    func attachStatus(topAnchor: NSLayoutYAxisAnchor)
    func attachMoreInformation()

    func routeToAboutApp()
    func detachAboutApp(shouldHideViewController: Bool)

    func routeToReceivedNotification()
    func detachReceivedNotification(shouldDismissViewController: Bool)

    func routeToRequestTest()
    func detachRequestTest(shouldDismissViewController: Bool)

    func routeToInfected()
    func detachInfected(shouldDismissViewController: Bool)

    func routeToMessage(title: String, body: String)
    func detachMessage(shouldDismissViewController: Bool)
}

final class MainViewController: ViewController, MainViewControllable, StatusListener, Logging {

    weak var router: MainRouting?

    // MARK: - Init

    init(theme: Theme,
         exposureController: ExposureControlling,
         exposureStateStream: ExposureStateStreaming) {
        self.exposureController = exposureController
        self.exposureStateStream = exposureStateStream
        super.init(theme: theme)
    }

    // MARK: - View Lifecycle

    override func loadView() {
        self.view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        router?.attachStatus(topAnchor: view.topAnchor)
        router?.attachMoreInformation()

        if let activeState = exposureStateStream.currentExposureState?.activeState, activeState == .inactive(.disabled) {
            exposureController.requestExposureNotificationPermission()
        }
    }

    // MARK: - Internal

    func embed(stackedViewController: ViewControllable) {
        addChild(stackedViewController.uiviewController)

        let view: UIView = stackedViewController.uiviewController.view

        mainView.stackView.addArrangedSubview(view)
        view.widthAnchor.constraint(equalTo: mainView.widthAnchor).isActive = true

        stackedViewController.uiviewController.didMove(toParent: self)
    }

    func present(viewController: ViewControllable, animated: Bool) {

        let navigationController: NavigationController

        if let navController = viewController as? NavigationController {
            navigationController = navController
        } else {
            navigationController = NavigationController(rootViewController: viewController.uiviewController, theme: theme)
        }

        if let presentationDelegate = viewController.uiviewController as? UIAdaptivePresentationControllerDelegate {
            navigationController.presentationController?.delegate = presentationDelegate
        }

        present(navigationController, animated: animated, completion: nil)
    }

    func dismiss(viewController: ViewControllable, animated: Bool) {
        guard let presentedViewController = presentedViewController else {
            return
        }

        var viewControllerToDismiss: UIViewController?

        if let navigationController = presentedViewController as? NavigationController,
            navigationController.visibleViewController === viewController.uiviewController {
            viewControllerToDismiss = navigationController
        } else if presentedViewController === viewController.uiviewController {
            viewControllerToDismiss = presentedViewController
        }

        if let viewController = viewControllerToDismiss {
            viewController.dismiss(animated: animated, completion: nil)
        }
    }

    // MARK: - MoreInformationListener

    func moreInformationRequestsAbout() {
        router?.routeToAboutApp()
    }

    func moreInformationRequestsReceivedNotification() {
        router?.routeToReceivedNotification()
    }

    func moreInformationRequestsInfected() {
        router?.routeToInfected()
    }

    func moreInformationRequestsRequestTest() {
        router?.routeToRequestTest()
    }

    // MARK: - AboutListener

    func aboutRequestsDismissal(shouldHideViewController: Bool) {
        router?.detachAboutApp(shouldHideViewController: shouldHideViewController)
    }

    // MARK: - ReceivedNotificationListner

    func receivedNotificationWantsDismissal(shouldDismissViewController: Bool) {
        router?.detachReceivedNotification(shouldDismissViewController: shouldDismissViewController)
    }

    // MARK: - RequestTestListener

    func requestTestWantsDismissal(shouldDismissViewController: Bool) {
        router?.detachRequestTest(shouldDismissViewController: shouldDismissViewController)
    }

    func helpRequestsEnableApp() {}

    func helpRequestsDismissal(shouldHideViewController: Bool) {
        router?.detachAboutApp(shouldHideViewController: shouldHideViewController)
    }

    // MARK: - InfectedListener

    func infectedWantsDismissal(shouldDismissViewController: Bool) {
        router?.detachInfected(shouldDismissViewController: shouldDismissViewController)
    }

    // MARK: - MessageListener

    func messageWantsDismissal(shouldDismissViewController: Bool) {
        router?.detachMessage(shouldDismissViewController: shouldDismissViewController)
    }

    // MARK: - StatusListener

    func handleButtonAction(_ action: StatusViewButtonModel.Action) {
        switch action {
        case let .explainRisk(date):
            router?.routeToMessage(title: Localization.string(for: "message.default.title"),
                                   body: Localization.string(for: "message.default.body", [StatusViewModel.timeAgo(from: date)]))
        case .removeNotification:
            confirmNotificationRemoval()
        case .updateAppSettings:
            handleUpdateAppSettings()
        }
    }

    // MARK: - Private

    private lazy var mainView: MainView = MainView(theme: self.theme)
    private let exposureController: ExposureControlling
    private let exposureStateStream: ExposureStateStreaming
    private var disposeBag = Set<AnyCancellable>()

    private func confirmNotificationRemoval() {
        let alertController = UIAlertController(title: Localization.string(for: "main.confirmNotificationRemoval.title"),
                                                message: Localization.string(for: "main.confirmNotificationRemoval.title"),
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Localization.string(for: "cancel"), style: .default) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        })
        alertController.addAction(UIAlertAction(title: Localization.string(for: "main.confirmNotificationRemoval.confirm"), style: .default) { [weak self] _ in
            self?.exposureController.confirmExposureNotification()
        })
        present(alertController, animated: true, completion: nil)
    }

    private func handleUpdateAppSettings() {
        guard let exposureState = exposureStateStream.currentExposureState else {
            return logError("Exposure State is `nil`")
        }
        switch exposureState.activeState {
        case .authorizationDenied:
            openAppSettings()
        case .notAuthorized:
            exposureController.requestExposureNotificationPermission()
        case let .inactive(reason) where reason == .bluetoothOff:
            openBluetooth()
        case let .inactive(reason) where reason == .disabled:
            exposureController.requestExposureNotificationPermission()
        case let .inactive(reason) where reason == .noRecentNotificationUpdates:
            updateWhenRequired()
        case .inactive:
            logError("Unhandled case")
        case .active:
            logError("Active state = noting nothing to do")
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return logError("Settings URL string problem")
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func openBluetooth() {
        // We need to navigate to the Bluetooth settings page, using `App-Perfs:root=Bluetooth`
        // is a private api and risks getting the app rejected during review.
        _ = CBCentralManager(delegate: nil, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }

    private func updateWhenRequired() {
        exposureController
            .updateWhenRequired()
            .sink(receiveCompletion: { [weak self] _ in
                self?.logDebug("Finished `updateWhenRequired`")
            }, receiveValue: { _ in
                // Do nothing
            }).store(in: &disposeBag)
    }
}

private final class MainView: View {
    fileprivate let scrollView = UIScrollView()
    fileprivate let stackView = UIStackView()

    override func build() {
        super.build()

        addSubview(scrollView)
        scrollView.addSubview(stackView)

        scrollView.contentInsetAdjustmentBehavior = .automatic
        scrollView.alwaysBounceVertical = true

        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let constraints = [
            // scrollView
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // stackView
            stackView.widthAnchor.constraint(equalTo: widthAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
