/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

typealias AppStartResult = () -> ()

/// The App's entry point.
///
/// @mockable
protocol AppEntryPoint {
    /// The `UIViewController` instance that should be used as `keyWindow` property
    var uiviewController: UIViewController { get }

    /// The Stream to publish received PushNotifications to for the Root Router to handle
    var mutablePushNotificationStream: MutablePushNotificationStreaming { get }

    /// Starts the application. Start should be called once
    /// the `SceneDelegate`'s `sceneDidBecomeActive` method is called.
    func start()
}

/// Provides all dependencies to build the RootRouter
private final class RootDependencyProvider: DependencyProvider<EmptyDependency>, MainDependency, ExposureControllerDependency, OnboardingDependency, DeveloperMenuDependency, NetworkControllerDependency, MessageDependency {

    // MARK: - Child Builders

    /// Builds onboarding flow
    var onboardingBuilder: OnboardingBuildable {
        return OnboardingBuilder(dependency: self)
    }

    /// Builds main flow
    var mainBuilder: MainBuildable {
        return MainBuilder(dependency: self)
    }

    var messageBuilder: MessageBuildable {
        return MessageBuilder(dependency: self)
    }

    var developerMenuBuilder: DeveloperMenuBuildable {
        return DeveloperMenuBuilder(dependency: self)
    }

    // MARK: - Exposure Related

    /// Exposure controller, to control the exposure data flows
    lazy var exposureController: ExposureControlling = {
        let builder = ExposureControllerBuilder(dependency: self)
        return builder.build()
    }()

    lazy var mutableNetworkConfigurationStream: MutableNetworkConfigurationStreaming = {
        return NetworkConfigurationStream(configuration: .production)
    }()

    var networkConfigurationProvider: NetworkConfigurationProvider {
        // TODO: Replace this with static configuration when releasing
        return DynamicNetworkConfigurationProvider(configurationStream: mutableNetworkConfigurationStream)
    }

    lazy var networkController: NetworkControlling = {
        return NetworkControllerBuilder(dependency: self).build()
    }()

    lazy var backgroundController: BackgroundControlling = {
        return BackgroundControllerBuilder().build()
    }()

    /// Local Storage
    lazy var storageController: StorageControlling = StorageControllerBuilder().build()

    /// Exposure state stream, informs about the current exposure states
    var exposureStateStream: ExposureStateStreaming {
        return mutableExposureStateStream
    }

    let theme: Theme = ENTheme()

    /// Mutable counterpart of exposureStateStream - Used as dependency for exposureController
    lazy var mutableExposureStateStream: MutableExposureStateStreaming = ExposureStateStream()

    /// Mutable stream for publishing PushNotifcaiton objects to
    lazy var mutablePushNotificationStream: MutablePushNotificationStreaming = PushNotificaionStream()
}

/// Interface describing the builder that builds
/// the App's entry point
///
/// @mockable
protocol RootBuildable {
    /// Builds application's entry point
    ///
    /// - Returns: Application's entry point
    func build() -> AppEntryPoint
}

/// Builds the Root feature which should be used via the `AppEntryPoint`
/// interface.
///
/// - Tag: RootBuilder
final class RootBuilder: Builder<EmptyDependency>, RootBuildable {

    // MARK: - RootBuildable

    func build() -> AppEntryPoint {
        let dependencyProvider = RootDependencyProvider()
        let viewController = RootViewController(theme: dependencyProvider.theme)

        return RootRouter(viewController: viewController,
                          onboardingBuilder: dependencyProvider.onboardingBuilder,
                          mainBuilder: dependencyProvider.mainBuilder,
                          messageBuilder: dependencyProvider.messageBuilder,
                          exposureController: dependencyProvider.exposureController,
                          exposureStateStream: dependencyProvider.exposureStateStream,
                          developerMenuBuilder: dependencyProvider.developerMenuBuilder,
                          mutablePushNotificationStream: dependencyProvider.mutablePushNotificationStream)
    }
}
