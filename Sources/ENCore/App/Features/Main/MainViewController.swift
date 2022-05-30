/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import RxSwift
import UIKit
import UserNotifications

/// @mockable
protocol MainRouting: Routing {
    func attachStatus(topAnchor: NSLayoutYAxisAnchor)
    func attachMoreInformation()

    func attachDashboardSummary()
    func detachDashboardSummary()

    func routeToDashboardDetail(with identifier: DashboardIdentifier)
    func detachDashboardDetail(shouldDismissViewController: Bool)

    func routeToAboutApp()
    func detachAboutApp(shouldHideViewController: Bool)

    func routeToSettings()
    func detachSettings(shouldDismissViewController: Bool)

    func routeToSharing()
    func detachSharing(shouldHideViewController: Bool)

    func routeToReceivedNotification()
    func detachReceivedNotification(shouldDismissViewController: Bool)

    func routeToRequestTest()
    func detachRequestTest(shouldDismissViewController: Bool)

    func routeToKeySharing()
    func detachKeySharing(shouldDismissViewController: Bool)

    func routeToMessage()
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
         storageController: StorageControlling,
         exposureStateStream: ExposureStateStreaming,
         userNotificationController: UserNotificationControlling,
         pauseController: PauseControlling,
         alertControllerBuilder: AlertControllerBuildable) {
        self.exposureController = exposureController
        self.storageController = storageController
        self.exposureStateStream = exposureStateStream
        self.pauseController = pauseController
        self.userNotificationController = userNotificationController
        self.alertControllerBuilder = alertControllerBuilder
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

        determineDashboardVisibility()

        if let shareLogs = Bundle.main.infoDictionary?["SHARE_LOGS_ENABLED"] as? Bool, shareLogs == true {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didQuadrupleTap(sender:)))
            gestureRecognizer.numberOfTapsRequired = 4

            view.addGestureRecognizer(gestureRecognizer)
        }
    }

    // MARK: - Internal

    func embed(stackedViewController: ViewControllable) {
        embed(stackedViewController: stackedViewController, at: mainView.stackView.arrangedSubviews.count)
    }

    func embed(stackedViewController: ViewControllable, at index: Int) {
        addChild(stackedViewController.uiviewController)

        let view: UIView = stackedViewController.uiviewController.view

        if index <= mainView.stackView.arrangedSubviews.count {
            mainView.stackView.insertArrangedSubview(view, at: index)
        } else {
            mainView.stackView.addArrangedSubview(view)
        }

        view.widthAnchor.constraint(equalTo: mainView.widthAnchor).isActive = true

        stackedViewController.uiviewController.didMove(toParent: self)
    }

    func remove(stackedViewController: ViewControllable) {
        let view: UIView = stackedViewController.uiviewController.view

        view.removeFromSuperview()

        stackedViewController.uiviewController.didMove(toParent: nil)
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

    func determineDashboardVisibility() {
        let dashboardEnabled = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.showCoronaDashboard) ?? true

        if dashboardEnabled {
            router?.attachDashboardSummary()
        } else {
            router?.detachDashboardSummary()
        }
    }

    // MARK: - MoreInformationListener

    func moreInformationRequestsAbout() {
        router?.routeToAboutApp()
    }

    func moreInformationRequestsSettings() {
        router?.routeToSettings()
    }

    func moreInformationRequestsSharing() {
        router?.routeToSharing()
    }

    func moreInformationRequestsReceivedNotification() {
        router?.routeToReceivedNotification()
    }

    func receivedNotificationRequestRedirect(to content: LinkedContent) {}

    func receivedNotificationActionButtonTapped() {}

    func moreInformationRequestsKeySharing() {
        router?.routeToKeySharing()
    }

    func moreInformationRequestsRequestTest() {
        router?.routeToRequestTest()
    }

    // MARK: - WebviewListener

    func webviewRequestsDismissal(shouldHideViewController: Bool) {
        router?.detachWebview(shouldDismissViewController: shouldHideViewController)
    }

    // MARK: - DashboardListener

    func dashboardRequestsDismissal(shouldDismissViewController: Bool) {
        router?.detachDashboardDetail(shouldDismissViewController: shouldDismissViewController)
    }

    // MARK: - AboutListener

    func aboutRequestsDismissal(shouldHideViewController: Bool) {
        router?.detachAboutApp(shouldHideViewController: shouldHideViewController)
    }

    // MARK: - SettingsListner

    func settingsWantsDismissal(shouldDismissViewController: Bool) {
        router?.detachSettings(shouldDismissViewController: shouldDismissViewController)
        determineDashboardVisibility()
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

    // MARK: - KeySharingListener

    func keySharingWantsDismissal(shouldDismissViewController: Bool) {
        router?.detachKeySharing(shouldDismissViewController: shouldDismissViewController)
    }

    // MARK: - MessageListener

    func messageWantsDismissal(shouldDismissViewController: Bool) {
        router?.detachMessage(shouldDismissViewController: shouldDismissViewController)
    }

    // MARK: - StatusListener

    func handleButtonAction(_ action: StatusViewButtonModel.Action) {
        switch action {
        case .explainRisk:
            router?.routeToMessage()
        case let .removeNotification(title):
            confirmNotificationRemoval(title: title)
        case .updateAppSettings:
            handleUpdateAppSettings()
        case .tryAgain:
            updateWhenRequired()
        case .unpause:
            pauseController.unpauseApp()
        case .enableInternet:
            router?.routeToEnableSetting(.connectToInternet)
        }
    }

    // MARK: - EnableSettingListener

    func enableSettingRequestsDismiss(shouldDismissViewController: Bool) {
        router?.detachEnableSetting(shouldDismissViewController: shouldDismissViewController)
    }

    func enableSettingDidTriggerAction() {
        router?.detachEnableSetting(shouldDismissViewController: true)
    }

    // MARK: - DashboardSummaryListener

    func dashboardSummaryRequestsRouteToDetail(with identifier: DashboardIdentifier) {
        router?.routeToDashboardDetail(with: identifier)
    }

    // MARK: - Private

    private lazy var mainView: MainView = MainView(theme: self.theme)
    private let exposureController: ExposureControlling
    private let storageController: StorageControlling
    private let exposureStateStream: ExposureStateStreaming
    private let pauseController: PauseControlling
    private let userNotificationController: UserNotificationControlling
    private let alertControllerBuilder: AlertControllerBuildable

    private var disposeBag = DisposeBag()

    @objc private func didQuadrupleTap(sender: UITapGestureRecognizer) {
        let activityViewController = UIActivityViewController(activityItems: LogHandler.logFiles(),
                                                              applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }

    private func confirmNotificationRemoval(title: String) {
        let message = .mainConfirmNotificationRemovalTitle + " " + .mainConfirmNotificationRemovalMessage
        let alertController = alertControllerBuilder.buildAlertController(withTitle: title, message: message, preferredStyle: .alert)
        alertController.addAction(alertControllerBuilder.buildAlertAction(title: .cancel, style: .default) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
            })
        alertController.addAction(alertControllerBuilder.buildAlertAction(title: .mainConfirmNotificationRemovalConfirm, style: .default) { [weak self] _ in
            self?.exposureController.confirmExposureNotification()
            })
        present(alertController, animated: true, completion: nil)
    }

    private func handleUpdateAppSettings() {
        let exposureState = exposureStateStream.currentExposureState

        switch exposureState.activeState {
        case .authorizationDenied, .restricted:
            router?.routeToEnableSetting(.enableExposureNotifications)
        case .notAuthorized:
            requestExposureNotificationPermission { [weak self] success in
                guard success else { return }

                // Double check that we also got push notification authorisation (or ask if we don't have it yet)
                self?.getPushNotificationAuthorization()
            }
        case let .inactive(reason) where reason == .bluetoothOff:
            router?.routeToEnableSetting(.enableBluetooth)
        case let .inactive(reason) where reason == .disabled:
            requestExposureNotificationPermission { result in
                if result == false {
                    self.router?.routeToEnableSetting(.enableExposureNotifications)
                }
            }
        case let .inactive(reason) where reason == .pushNotifications:
            getPushNotificationAuthorization()
        case let .inactive(reason) where reason == .noRecentNotificationUpdates:
            updateWhenRequired()
        case .inactive:
            logError("Unhandled case")
        case .active:
            logError("Active state = noting nothing to do")
        }
    }

    private func getPushNotificationAuthorization() {
        userNotificationController.getAuthorizationStatus { authorizationStatus in
            DispatchQueue.main.async {
                self.handlePushNotificationSettings(authorizationStatus: authorizationStatus)
            }
        }
    }

    private func handlePushNotificationSettings(authorizationStatus: NotificationAuthorizationStatus) {
        switch authorizationStatus {
        case .notDetermined:
            userNotificationController.requestNotificationPermission {}
        case .denied:
            router?.routeToEnableSetting(.enableLocalNotifications)
        default:
            self.logError("Unhandled case")
        }
    }

    private func updateWhenRequired() {
        exposureController
            .updateWhenRequired()
            .do(onError: { [weak self] error in
                self?.logDebug("Finished `updateWhenRequired` with error \(error)")
            }, onCompleted: { [weak self] in
                self?.logDebug("Finished `updateWhenRequired`")
            })
            .subscribe(onCompleted: {})
            .disposed(by: disposeBag)
    }

    private func requestExposureNotificationPermission(completion: ((Bool) -> ())? = nil) {
        exposureController.requestExposureNotificationPermission { error in
            guard let error = error else {
                completion?(true)
                return
            }
            self.logError("Error `requestExposureNotificationPermission`: \(error.localizedDescription)")
            completion?(false)
        }
    }
}

private final class MainView: View {
    fileprivate let scrollView = UIScrollView()
    fileprivate let stackView = UIStackView()
    fileprivate let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))

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
