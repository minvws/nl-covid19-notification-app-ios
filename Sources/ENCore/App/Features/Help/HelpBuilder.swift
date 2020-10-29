/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol HelpListener: AnyObject {
    func helpRequestsEnableApp()
    func helpRequestsDismissal(shouldHideViewController: Bool)
}

/// @mockable
protocol HelpBuildable {
    /// Builds Help
    ///
    /// - Parameter listener: Listener of created HelpViewController
    func build(withListener listener: HelpListener,
               shouldShowEnableAppButton: Bool) -> Routing
}

protocol HelpDependency {
    var theme: Theme { get }
    var exposureController: ExposureControlling { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
}

private final class HelpDependencyProvider: DependencyProvider<HelpDependency>, HelpOverviewDependency, HelpDetailDependency, ReceivedNotificationDependency {

    // MARK: - HelpOverviewDependency

    lazy var helpManager: HelpManaging = HelpManager()

    // MARK: - Forwarding Dependencies

    var theme: Theme {
        return dependency.theme
    }

    var interfaceOrientationStream: InterfaceOrientationStreaming {
        dependency.interfaceOrientationStream
    }

    // MARK: - Child Builders

    var overviewBuilder: HelpOverviewBuildable {
        return HelpOverviewBuilder(dependency: self)
    }

    var detailBuilder: HelpDetailBuildable {
        return HelpDetailBuilder(dependency: self)
    }

    var receivedNotificationBuilder: ReceivedNotificationBuildable {
        return ReceivedNotificationBuilder(dependency: self)
    }
}

final class HelpBuilder: Builder<HelpDependency>, HelpBuildable {

    // MARK: - OnboardingConsentHelpDependency

    func build(withListener listener: HelpListener,
               shouldShowEnableAppButton: Bool) -> Routing {
        let dependencyProvider = HelpDependencyProvider(dependency: dependency)
        let viewController = HelpViewController(listener: listener,
                                                shouldShowEnableAppButton: shouldShowEnableAppButton,
                                                exposureController: dependencyProvider.dependency.exposureController,
                                                theme: dependencyProvider.dependency.theme)

        return HelpRouter(viewController: viewController,
                          helpOverviewBuilder: dependencyProvider.overviewBuilder,
                          helpDetailBuilder: dependencyProvider.detailBuilder,
                          receivedNotificationBuilder: dependencyProvider.receivedNotificationBuilder)
    }
}
