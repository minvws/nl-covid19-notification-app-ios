/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import UIKit
import UserNotifications

/// @mockable
protocol MainRouting: Routing {
    func attachStatus(topAnchor: NSLayoutYAxisAnchor)
    func attachMoreInformation()

    func routeToAboutApp()
    func detachAboutApp(shouldHideViewController: Bool)

    func routeToSharing()
    func detachSharing(shouldHideViewController: Bool)

    func routeToReceivedNotification()
    func detachReceivedNotification(shouldDismissViewController: Bool)

    func routeToRequestTest()
    func detachRequestTest(shouldDismissViewController: Bool)

    func routeToInfected()
    func detachInfected(shouldDismissViewController: Bool)

    func routeToMessage(exposureDate: Date)
    func detachMessage(shouldDismissViewController: Bool)

    func routeToEnableSetting(_ setting: EnableSetting)
    func detachEnableSetting(shouldDismissViewController: Bool)

    func routeToWebview(url: URL)
    func detachWebview(shouldDismissViewController: Bool)
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

        if let shareLogs = Bundle.main.infoDictionary?["SHARE_LOGS_ENABLED"] as? Bool, shareLogs == true {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didQuadrupleTap(sender:)))
            gestureRecognizer.numberOfTapsRequired = 4

            view.addGestureRecognizer(gestureRecognizer)
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
        present(viewController: viewController, animated: animated, inNavigationController: true)
    }

    func present(viewController: ViewControllable, animated: Bool, inNavigationController: Bool) {
        guard inNavigationController else {
            present(viewController.uiviewController, animated: true, completion: nil)
            return
        }

        let navigationController: NavigationController

        if let navController = viewController as? NavigationController {
            navigationController = navController
        } else {
            navigationController = NavigationController(rootViewController: viewController.uiviewController, theme: theme)
        }

        if let presentationDelegate = viewController.uiviewController as? UIAdaptivePresentationControllerDelegate {
            navigationController.presentationController?.delegate = presentationDelegate
        }

        if let presentedViewController = presentedViewController {
            presentedViewController.present(navigationController, animated: true, completion: nil)
        } else {
            present(navigationController, animated: animated, completion: nil)
        }
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

    func moreInformationRequestsSharing() {
        router?.routeToSharing()
    }

    func moreInformationRequestsReceivedNotification() {
        router?.routeToReceivedNotification()
    }

    func receivedNotificationRequestRedirect(to content: LinkedContent) {}

    func receivedNotificationActionButtonTapped() {}

    func moreInformationRequestsInfected() {
        router?.routeToInfected()
    }

    func moreInformationRequestsRequestTest() {
        router?.routeToRequestTest()
    }

    func moreInformationRequestsRedirect(to url: URL) {
        router?.routeToWebview(url: url)
    }

    // MARK: - WebviewListener

    func webviewRequestsDismissal(shouldHideViewController: Bool) {
        router?.detachWebview(shouldDismissViewController: shouldHideViewController)
    }

    // MARK: - AboutListener

    func aboutRequestsDismissal(shouldHideViewController: Bool) {
        router?.detachAboutApp(shouldHideViewController: shouldHideViewController)
    }

    // MARK: - HelpListener

    func helpRequestsEnableApp() {}

    func helpRequestsDismissal(shouldHideViewController: Bool) {}

    // MARK: - ShareSheetListener

    func shareSheetDidComplete(shouldHideViewController: Bool) {
        router?.detachSharing(shouldHideViewController: shouldHideViewController)
    }

    func displayShareSheet(usingViewController viewcontroller: ViewController, completion: @escaping ((Bool) -> ())) {
        if let storeLink = URL(string: .shareAppUrl) {
            let activityVC = UIActivityViewController(activityItems: [.shareAppTitle as String, storeLink], applicationActivities: nil)
            activityVC.completionWithItemsHandler = { _, completed, _, _ in
                completion(completed)
            }
            viewcontroller.present(activityVC, animated: true)
        } else {
            self.logError("Couldn't retreive a valid url")
        }
    }

    // MARK: - ReceivedNotificationListner

    func receivedNotificationWantsDismissal(shouldDismissViewController: Bool) {
        router?.detachReceivedNotification(shouldDismissViewController: shouldDismissViewController)
    }

    // MARK: - RequestTestListener

    func requestTestWantsDismissal(shouldDismissViewController: Bool) {
        router?.detachRequestTest(shouldDismissViewController: shouldDismissViewController)
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
            router?.routeToMessage(exposureDate: date)
        case let .removeNotification(title):
            confirmNotificationRemoval(title: title)
        case .updateAppSettings:
            handleUpdateAppSettings()
        case .tryAgain:
            updateWhenRequired()
        }
    }

    // MARK: - EnableSettingListener

    func enableSettingRequestsDismiss(shouldDismissViewController: Bool) {
        router?.detachEnableSetting(shouldDismissViewController: shouldDismissViewController)
    }

    func enableSettingDidTriggerAction() {
        router?.detachEnableSetting(shouldDismissViewController: true)
    }

    // MARK: - Private

    private lazy var mainView: MainView = MainView(theme: self.theme)
    private let exposureController: ExposureControlling
    private let exposureStateStream: ExposureStateStreaming

    private var disposeBag = Set<AnyCancellable>()

    @objc private func didQuadrupleTap(sender: UITapGestureRecognizer) {
        let activityViewController = UIActivityViewController(activityItems: LogHandler.logFiles(),
                                                              applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }

    private func confirmNotificationRemoval(title: String) {
        let message = .mainConfirmNotificationRemovalTitle + " " + .mainConfirmNotificationRemovalMessage
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: .cancel, style: .default) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
            })
        alertController.addAction(UIAlertAction(title: .mainConfirmNotificationRemovalConfirm, style: .default) { [weak self] _ in
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
            router?.routeToEnableSetting(.enableExposureNotifications)
        case .notAuthorized:
            requestExposureNotificationPermission()
        case let .inactive(reason) where reason == .bluetoothOff:
            router?.routeToEnableSetting(.enableBluetooth)
        case let .inactive(reason) where reason == .disabled:
            router?.routeToEnableSetting(.enableExposureNotifications)
        case let .inactive(reason) where reason == .pushNotifications:
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    self.handlePushNotificationSettings(authorizationStatus: settings.authorizationStatus)
                }
            }
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

    private func handlePushNotificationSettings(authorizationStatus: UNAuthorizationStatus) {
        switch authorizationStatus {
        case .notDetermined:
            self.exposureController.requestPushNotificationPermission {}
        case .denied:
            router?.routeToEnableSetting(.enableLocalNotifications)
        default:
            self.logError("Unhandled case")
        }
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

    private func requestExposureNotificationPermission() {
        exposureController.requestExposureNotificationPermission { error in
            guard let error = error else {
                return
            }
            self.logError("Error `requestExposureNotificationPermission`: \(error.localizedDescription)")
        }
    }
}

private final class MainView: View {
    fileprivate let scrollView = UIScrollView()
    fileprivate let stackView = UIStackView()
    fileprivate let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))

    override func build() {
        super.build()

        addSubview(scrollView)
        scrollView.addSubview(stackView)
        addSubview(blurView)

        scrollView.contentInsetAdjustmentBehavior = .automatic
        scrollView.alwaysBounceVertical = true

        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollView.snp.makeConstraints { maker in
            maker.leading.trailing.top.bottom.equalToSuperview()
        }

        stackView.snp.makeConstraints { maker in
            maker.width.leading.trailing.equalToSuperview()
            maker.top.equalTo(scrollView.snp.top)
            maker.bottom.equalTo(scrollView.snp.bottom)
        }
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()

        blurView.snp.remakeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(safeAreaInsets.top)
        }
    }
}
