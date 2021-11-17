/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

#if canImport(BackgroundTasks)
    import BackgroundTasks
#endif

import ENFoundation
import UIKit

/// The App's entry point.
///
/// @mockable(history:handle=true)
public protocol AppEntryPoint {
    /// The `UIViewController` instance that should be used as `keyWindow` property
    var uiviewController: UIViewController { get }

    /// The Stream to publish received PushNotifications to for the Root Router to handle
    var mutablePushNotificationStream: MutablePushNotificationStreaming { get }

    /// Starts the application. Start should be called once
    /// the `SceneDelegate`'s `sceneDidBecomeActive` method is called.
    func start()

    /// Should be called when the app becomes active
    func didBecomeActive()

    /// Should be called when the app did enter the foreground
    func didEnterForeground()

    /// Should be called when the app did enter the background
    func didEnterBackground()

    // Should handle the background task
    @available(iOS 13, *)
    func handle(backgroundTask: BackgroundTask)
}

/// Provides all dependencies to build the RootRouter
private final class RootDependencyProvider: DependencyProvider<EmptyDependency>, MainDependency, ExposureControllerDependency, OnboardingDependency, DeveloperMenuDependency, NetworkControllerDependency, MessageDependency, CallGGDDependency, BackgroundDependency, UpdateAppDependency, EndOfLifeDependency, WebviewDependency, ExposureDataControllerDependency, LaunchScreenDependency, UpdateOperatingSystemDependency, EnableSettingDependency, ShareSheetDependency {

    // MARK: - Child Builders

    fileprivate var launchScreenBuilder: LaunchScreenBuildable {
        return LaunchScreenBuilder(dependency: self)
    }

    fileprivate var onboardingBuilder: OnboardingBuildable {
        return OnboardingBuilder(dependency: self)
    }

    fileprivate var mainBuilder: MainBuildable {
        return MainBuilder(dependency: self)
    }

    fileprivate var endOfLifeBuilder: EndOfLifeBuildable {
        return EndOfLifeBuilder(dependency: self)
    }

    fileprivate var messageBuilder: MessageBuildable {
        return MessageBuilder(dependency: self)
    }

    fileprivate var callGGDBuilder: CallGGDBuildable {
        return CallGGDBuilder(dependency: self)
    }

    fileprivate var developerMenuBuilder: DeveloperMenuBuildable {
        return DeveloperMenuBuilder(dependency: self)
    }

    fileprivate var updateAppBuilder: UpdateAppBuildable {
        return UpdateAppBuilder(dependency: self)
    }

    fileprivate var updateOperatingSystemBuilder: UpdateOperatingSystemBuildable {
        return UpdateOperatingSystemBuilder(dependency: self)
    }

    fileprivate var enableSettingBuilder: EnableSettingBuildable {
        return EnableSettingBuilder(dependency: self)
    }

    fileprivate var webviewBuilder: WebviewBuildable {
        return WebviewBuilder(dependency: self)
    }

    var shareBuilder: ShareSheetBuildable {
        return ShareSheetBuilder(dependency: self)
    }

    // MARK: - Exposure Related

    /// Exposure controller, to control the exposure data flows
    lazy var exposureController: ExposureControlling = {
        let builder = ExposureControllerBuilder(dependency: self)
        return builder.build()
    }()

    lazy var exposureManager: ExposureManaging = {
        let builder = ExposureManagerBuilder()
        return builder.build()
    }()

    var environmentController: EnvironmentControlling = {
        return EnvironmentController()
    }()

    lazy var mutableNetworkConfigurationStream: MutableNetworkConfigurationStreaming = {
        let networkConfiguration: NetworkConfiguration

        let configurations: [String: NetworkConfiguration] = [
            NetworkConfiguration.development.name: NetworkConfiguration.development,
            NetworkConfiguration.test.name: NetworkConfiguration.test,
            NetworkConfiguration.acceptance.name: NetworkConfiguration.acceptance,
            NetworkConfiguration.production.name: NetworkConfiguration.production
        ]

        let fallbackConfiguration = NetworkConfiguration.test

        if let networkConfigurationValue = Bundle.main.infoDictionary?["NETWORK_CONFIGURATION"] as? String {
            networkConfiguration = configurations[networkConfigurationValue] ?? fallbackConfiguration
        } else {
            networkConfiguration = fallbackConfiguration
        }

        return NetworkConfigurationStream(configuration: networkConfiguration)
    }()

    var networkConfigurationProvider: NetworkConfigurationProvider {
        return DynamicNetworkConfigurationProvider(configurationStream: mutableNetworkConfigurationStream)
    }

    lazy var networkController: NetworkControlling = {
        return NetworkControllerBuilder(dependency: self).build()
    }()

    lazy var backgroundController: BackgroundControlling = {
        let builder = BackgroundControllerBuilder(dependency: self)
        return builder.build()
    }()

    lazy var dataController: ExposureDataControlling = {
        return ExposureDataControllerBuilder(dependency: self).build()
    }()

    /// Local Storage
    lazy var storageController: StorageControlling = StorageControllerBuilder().build()

    var cryptoUtility: CryptoUtility {
        return CryptoUtilityBuilder().build()
    }

    lazy var applicationSignatureController: ApplicationSignatureControlling = {
        return ApplicationSignatureController(storageController: storageController,
                                              cryptoUtility: cryptoUtility)
    }()

    /// Exposure state stream, informs about the current exposure states
    var exposureStateStream: ExposureStateStreaming {
        return mutableExposureStateStream
    }

    var networkStatusStream: NetworkStatusStreaming {
        return mutableNetworkStatusStream
    }

    var interfaceOrientationStream: InterfaceOrientationStreaming {
        return InterfaceOrientationStream()
    }

    var pauseController: PauseControlling {
        PauseController(exposureDataController: dataController,
                        exposureController: exposureController,
                        userNotificationController: userNotificationController,
                        backgroundController: backgroundController)
    }

    let theme: Theme = ENTheme()

    /// Mutable counterpart of exposureStateStream - Used as dependency for exposureController
    lazy var mutableExposureStateStream: MutableExposureStateStreaming = ExposureStateStream()

    /// Mutable stream for publishing PushNotifcaiton objects to
    lazy var mutablePushNotificationStream: MutablePushNotificationStreaming = PushNotificationStream()

    /// Mutable stream for publishing the NetworkStatus reachability to
    lazy var mutableNetworkStatusStream: MutableNetworkStatusStreaming = NetworkStatusStream(reachabilityProvider: reachabilityProvider)

    private lazy var reachabilityProvider: ReachabilityProviding = ReachabilityProvider()

    var messageManager: MessageManaging {
        return MessageManager(storageController: storageController, exposureDataController: dataController, theme: theme)
    }

    fileprivate var userNotificationController: UserNotificationControlling {
        UserNotificationController()
    }

    var randomNumberGenerator: RandomNumberGenerating {
        RandomNumberGenerator()
    }

    var pushNotificationStream: PushNotificationStreaming {
        mutablePushNotificationStream
    }
}

/// Interface describing the builder that builds
/// the App's entry point
///
/// @mockable
public protocol RootBuildable {
    /// Builds application's entry point
    ///
    /// - Returns: Application's entry point
    func build() -> AppEntryPoint
}

/// Builds the Root feature which should be used via the `AppEntryPoint`
/// interface.
///
/// - Tag: RootBuilder
final class RootBuilder: Builder<EmptyDependency>, RootBuildable, Logging {

    // MARK: - RootBuildable

    func build() -> AppEntryPoint {
        let dependencyProvider = RootDependencyProvider()
        let viewController = RootViewController(theme: dependencyProvider.theme)

        let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

        guard let unwrappedCurrentAppVersion = currentAppVersion else {
            let error = "Bundle version could not be retrieved from infodictionary, app is in an incorrect state"
            self.logError(error)
            fatalError(error)
        }

        return RootRouter(viewController: viewController,
                          launchScreenBuilder: dependencyProvider.launchScreenBuilder,
                          onboardingBuilder: dependencyProvider.onboardingBuilder,
                          mainBuilder: dependencyProvider.mainBuilder,
                          endOfLifeBuilder: dependencyProvider.endOfLifeBuilder,
                          messageBuilder: dependencyProvider.messageBuilder,
                          callGGDBuilder: dependencyProvider.callGGDBuilder,
                          exposureController: dependencyProvider.exposureController,
                          exposureStateStream: dependencyProvider.exposureStateStream,
                          mutableNetworkStatusStream: dependencyProvider.mutableNetworkStatusStream,
                          developerMenuBuilder: dependencyProvider.developerMenuBuilder,
                          mutablePushNotificationStream: dependencyProvider.mutablePushNotificationStream,
                          networkController: dependencyProvider.networkController,
                          backgroundController: dependencyProvider.backgroundController,
                          updateAppBuilder: dependencyProvider.updateAppBuilder,
                          updateOperatingSystemBuilder: dependencyProvider.updateOperatingSystemBuilder,
                          webviewBuilder: dependencyProvider.webviewBuilder,
                          userNotificationController: dependencyProvider.userNotificationController,
                          currentAppVersion: unwrappedCurrentAppVersion,
                          environmentController: dependencyProvider.environmentController,
                          pauseController: dependencyProvider.pauseController,
                          shareBuilder: dependencyProvider.shareBuilder)
    }
}
