/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

/// @mockable(history: present = true)
protocol MainViewControllable: ViewControllable, StatusListener, MoreInformationListener, AboutListener, ShareSheetListener, ReceivedNotificationListener, RequestTestListener, InfectedListener, HelpListener, MessageListener, EnableSettingListener, WebviewListener, SettingsListener, KeySharingFlowChoiceListener {

    var router: MainRouting? { get set }

    func embed(stackedViewController: ViewControllable)
    func present(viewController: ViewControllable, animated: Bool)
    func present(viewController: ViewControllable, animated: Bool, inNavigationController: Bool)
    func dismiss(viewController: ViewControllable, animated: Bool)
}

final class MainRouter: Router<MainViewControllable>, MainRouting {

    init(viewController: MainViewControllable,
         statusBuilder: StatusBuildable,
         moreInformationBuilder: MoreInformationBuildable,
         aboutBuilder: AboutBuildable,
         shareBuilder: ShareSheetBuildable,
         receivedNotificationBuilder: ReceivedNotificationBuildable,
         requestTestBuilder: RequestTestBuildable,
         keySharingFlowChoiceBuilder: KeySharingFlowChoiceBuildable,
         infectedBuilder: InfectedBuildable,
         messageBuilder: MessageBuildable,
         enableSettingBuilder: EnableSettingBuildable,
         webviewBuilder: WebviewBuildable,
         settingsBuilder: SettingsBuildable,
         featureFlagController: FeatureFlagControlling) {
        self.statusBuilder = statusBuilder
        self.moreInformationBuilder = moreInformationBuilder
        self.aboutBuilder = aboutBuilder
        self.shareBuilder = shareBuilder
        self.receivedNotificationBuilder = receivedNotificationBuilder
        self.requestTestBuilder = requestTestBuilder
        self.keySharingFlowChoiceBuilder = keySharingFlowChoiceBuilder
        self.infectedBuilder = infectedBuilder
        self.messageBuilder = messageBuilder
        self.enableSettingBuilder = enableSettingBuilder
        self.webviewBuilder = webviewBuilder
        self.settingsBuilder = settingsBuilder
        self.featureFlagController = featureFlagController

        super.init(viewController: viewController)

        viewController.router = self
    }

    // MARK: - MainRouting

    func attachStatus(topAnchor: NSLayoutYAxisAnchor) {
        guard statusViewController == nil else { return }

        let statusViewController = statusBuilder.build(withListener: viewController, topAnchor: topAnchor)
        self.statusViewController = statusViewController

        viewController.embed(stackedViewController: statusViewController)
    }

    func attachMoreInformation() {
        guard moreInformationViewController == nil else { return }

        let moreInformationViewController = moreInformationBuilder.build(withListener: viewController)
        self.moreInformationViewController = moreInformationViewController

        viewController.embed(stackedViewController: moreInformationViewController)
    }

    func routeToAboutApp() {
        guard aboutRouter == nil else {
            return
        }

        let aboutRouter = aboutBuilder.build(withListener: viewController)
        self.aboutRouter = aboutRouter

        viewController.present(viewController: aboutRouter.viewControllable,
                               animated: true)
    }

    func detachAboutApp(shouldHideViewController: Bool) {
        guard let aboutRouter = aboutRouter else { return }
        self.aboutRouter = nil

        if shouldHideViewController {
            viewController.dismiss(viewController: aboutRouter.viewControllable, animated: true)
        }
    }

    func routeToSettings() {
        guard settingsRouter == nil else {
            return
        }

        let settingsRouter = settingsBuilder.build(withListener: viewController)
        self.settingsRouter = settingsRouter

        viewController.present(viewController: settingsRouter.viewControllable, animated: true)
    }

    func detachSettings(shouldDismissViewController: Bool) {
        guard let settingsRouter = settingsRouter else {
            return
        }
        self.settingsRouter = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: settingsRouter.viewControllable, animated: true)
        }
    }

    func routeToSharing() {
        guard shareViewController == nil else {
            return
        }

        let shareViewController = shareBuilder.build(withListener: viewController, items: [])
        self.shareViewController = shareViewController

        viewController.present(viewController: shareViewController, animated: true)
    }

    func detachSharing(shouldHideViewController: Bool) {
        guard let shareViewController = shareViewController else {
            return
        }
        self.shareViewController = nil

        if shouldHideViewController {
            viewController.dismiss(viewController: shareViewController, animated: true)
        }
    }

    func routeToReceivedNotification() {
        guard receivedNotificationViewController == nil else {
            return
        }

        let receivedNotificationViewController = receivedNotificationBuilder.build(withListener: viewController, linkedContent: [], actionButtonTitle: nil)
        self.receivedNotificationViewController = receivedNotificationViewController

        viewController.present(viewController: receivedNotificationViewController, animated: true)
    }

    func detachReceivedNotification(shouldDismissViewController: Bool) {
        guard let receivedNotificationViewController = receivedNotificationViewController else {
            return
        }
        self.receivedNotificationViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: receivedNotificationViewController, animated: true)
        }
    }

    func routeToInfected() {
        guard infectedRouter == nil else {
            return
        }

        let infectedRouter: Routing
        
        if featureFlagController.isFeatureFlagEnabled(feature: .independentKeySharing) {
            infectedRouter = keySharingFlowChoiceBuilder.build(withListener: viewController)
        } else {
            infectedRouter = infectedBuilder.build(withListener: viewController)
        }
        
        self.infectedRouter = infectedRouter
        viewController.present(viewController: infectedRouter.viewControllable, animated: true)
    }

    func detachInfected(shouldDismissViewController: Bool) {
        guard let infectedRouter = infectedRouter else {
            return
        }
        self.infectedRouter = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: infectedRouter.viewControllable, animated: true)
        }
    }

    func routeToRequestTest() {
        guard requestTestViewController == nil else {
            return
        }

        let requestTestViewController = requestTestBuilder.build(withListener: viewController)
        self.requestTestViewController = requestTestViewController

        viewController.present(viewController: requestTestViewController, animated: true)
    }

    func detachRequestTest(shouldDismissViewController: Bool) {
        guard let requestTestViewController = requestTestViewController else {
            return
        }
        self.requestTestViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: requestTestViewController, animated: true)
        }
    }

    func routeToMessage() {
        guard messageViewController == nil else {
            return
        }
        let messageViewController = messageBuilder.build(withListener: viewController)
        self.messageViewController = messageViewController

        viewController.present(viewController: messageViewController, animated: true)
    }

    func detachMessage(shouldDismissViewController: Bool) {
        guard let messageViewController = messageViewController else {
            return
        }
        self.messageViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: messageViewController, animated: true)
        }
    }

    func routeToEnableSetting(_ setting: EnableSetting) {
        guard enableSettingViewController == nil else {
            return
        }

        let enableSettingViewController = enableSettingBuilder.build(withListener: viewController, setting: setting)
        self.enableSettingViewController = enableSettingViewController

        viewController.present(viewController: enableSettingViewController,
                               animated: true,
                               inNavigationController: false)
    }

    func detachEnableSetting(shouldDismissViewController: Bool) {
        guard let enableSettingViewController = enableSettingViewController else {
            return
        }

        self.enableSettingViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: enableSettingViewController,
                                   animated: true)
        }
    }

    func routeToWebview(url: URL) {
        guard webviewViewController == nil else { return }
        let webviewViewController = webviewBuilder.build(withListener: viewController, url: url)
        self.webviewViewController = webviewViewController

        viewController.present(viewController: webviewViewController, animated: true, inNavigationController: true)
    }

    func detachWebview(shouldDismissViewController: Bool) {
        guard let webviewViewController = webviewViewController else {
            return
        }
        self.webviewViewController = nil

        if shouldDismissViewController {
            viewController.dismiss(viewController: webviewViewController, animated: true)
        }
    }

    // MARK: - Private

    private let statusBuilder: StatusBuildable
    private var statusViewController: ViewControllable?

    private let moreInformationBuilder: MoreInformationBuildable
    private var moreInformationViewController: ViewControllable?

    private let aboutBuilder: AboutBuildable
    private var aboutRouter: Routing?

    private let settingsBuilder: SettingsBuildable
    private var settingsRouter: Routing?

    private let shareBuilder: ShareSheetBuildable
    private var shareViewController: ViewControllable?

    private let receivedNotificationBuilder: ReceivedNotificationBuildable
    private var receivedNotificationViewController: ViewControllable?

    private let requestTestBuilder: RequestTestBuildable
    private var requestTestViewController: ViewControllable?

    private let keySharingFlowChoiceBuilder: KeySharingFlowChoiceBuildable
    private let infectedBuilder: InfectedBuildable
    private var infectedRouter: Routing?

    private let messageBuilder: MessageBuildable
    private var messageViewController: ViewControllable?

    private let enableSettingBuilder: EnableSettingBuildable
    private var enableSettingViewController: ViewControllable?

    private let webviewBuilder: WebviewBuildable
    private var webviewViewController: ViewControllable?
    
    private let featureFlagController: FeatureFlagControlling
}
