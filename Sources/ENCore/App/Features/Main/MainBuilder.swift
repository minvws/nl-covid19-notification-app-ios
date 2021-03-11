/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UserNotifications

/// @mockable
protocol MainBuildable {
    func build() -> Routing
}

protocol MainDependency {
    var theme: Theme { get }
    var exposureStateStream: ExposureStateStreaming { get }
    var exposureController: ExposureControlling { get }
    var storageController: StorageControlling { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
    var dataController: ExposureDataControlling { get }
    var exposureManager: ExposureManaging { get }
    var backgroundController: BackgroundControlling { get }
    var pauseController: PauseControlling { get }
    var pushNotificationStream: PushNotificationStreaming { get }
}

final class MainDependencyProvider: DependencyProvider<MainDependency>, StatusDependency, MoreInformationDependency, AboutDependency, ShareSheetDependency, ReceivedNotificationDependency, RequestTestDependency, InfectedDependency, HelpDependency, MessageDependency, EnableSettingDependency, WebviewDependency, SettingsDependency {

    var theme: Theme {
        return dependency.theme
    }

    var exposureStateStream: ExposureStateStreaming {
        return dependency.exposureStateStream
    }

    var storageController: StorageControlling {
        return dependency.storageController
    }

    var interfaceOrientationStream: InterfaceOrientationStreaming {
        return dependency.interfaceOrientationStream
    }

    var statusBuilder: StatusBuildable {
        return StatusBuilder(dependency: self)
    }

    var moreInformationBuilder: MoreInformationBuildable {
        return MoreInformationBuilder(dependency: self)
    }

    var aboutBuilder: AboutBuildable {
        return AboutBuilder(dependency: self)
    }

    var settingsBuilder: SettingsBuildable {
        return SettingsBuilder(dependency: self)
    }

    var shareBuilder: ShareSheetBuildable {
        return ShareSheetBuilder(dependency: self)
    }

    var receivedNotificationBuilder: ReceivedNotificationBuildable {
        return ReceivedNotificationBuilder(dependency: self)
    }

    var requestTestBuilder: RequestTestBuildable {
        return RequestTestBuilder(dependency: self)
    }

    var infectedBuilder: InfectedBuildable {
        return InfectedBuilder(dependency: self)
    }

    var exposureController: ExposureControlling {
        return dependency.exposureController
    }

    var messageBuilder: MessageBuildable {
        return MessageBuilder(dependency: self)
    }

    var enableSettingBuilder: EnableSettingBuildable {
        return EnableSettingBuilder(dependency: self)
    }

    var webviewBuilder: WebviewBuildable {
        return WebviewBuilder(dependency: self)
    }

    var environmentController: EnvironmentControlling {
        return EnvironmentController()
    }

    var messageManager: MessageManaging {
        return MessageManager(storageController: storageController, theme: dependency.theme)
    }

    var dataController: ExposureDataControlling {
        dependency.dataController
    }

    var userNotificationCenter: UserNotificationCenter {
        UNUserNotificationCenter.current()
    }

    var pauseController: PauseControlling {
        dependency.pauseController
    }

    var pushNotificationStream: PushNotificationStreaming {
        dependency.pushNotificationStream
    }
    
    var alertControllerBuilder: AlertControllerBuildable {
        AlertControllerBuilder()
    }
}

final class MainBuilder: Builder<MainDependency>, MainBuildable {
    func build() -> Routing {
        let dependencyProvider = MainDependencyProvider(dependency: dependency)
        let viewController = MainViewController(theme: dependencyProvider.dependency.theme,
                                                exposureController: dependencyProvider.exposureController,
                                                exposureStateStream: dependencyProvider.exposureStateStream,
                                                userNotificationCenter: dependencyProvider.userNotificationCenter,
                                                pauseController: dependencyProvider.pauseController,
                                                alertControllerBuilder: dependencyProvider.alertControllerBuilder)

        return MainRouter(viewController: viewController,
                          statusBuilder: dependencyProvider.statusBuilder,
                          moreInformationBuilder: dependencyProvider.moreInformationBuilder,
                          aboutBuilder: dependencyProvider.aboutBuilder,
                          shareBuilder: dependencyProvider.shareBuilder,
                          receivedNotificationBuilder: dependencyProvider.receivedNotificationBuilder,
                          requestTestBuilder: dependencyProvider.requestTestBuilder,
                          infectedBuilder: dependencyProvider.infectedBuilder,
                          messageBuilder: dependencyProvider.messageBuilder,
                          enableSettingBuilder: dependencyProvider.enableSettingBuilder,
                          webviewBuilder: dependencyProvider.webviewBuilder,
                          settingsBuilder: dependencyProvider.settingsBuilder)
    }
}
