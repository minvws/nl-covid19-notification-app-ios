/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

/// @mockable
protocol StatusListener: AnyObject {
    func handleButtonAction(_ action: StatusViewButtonModel.Action)
}

/// @mockable
protocol StatusBuildable {
    /// Builds Status
    ///
    /// - Parameter listener: Listener of created Status component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: StatusListener, topAnchor: NSLayoutYAxisAnchor?) -> ViewControllable
}

protocol StatusDependency {
    var theme: Theme { get }
    var exposureStateStream: ExposureStateStreaming { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
    var environmentController: EnvironmentControlling { get }
    var dataController: ExposureDataControlling { get }
    var pauseController: PauseControlling { get }
    var pushNotificationStream: PushNotificationStreaming { get }
    var exposureController: ExposureControlling { get }
}

private final class StatusDependencyProvider: DependencyProvider<StatusDependency>, CardDependency {
    var exposureStateStream: ExposureStateStreaming {
        return dependency.exposureStateStream
    }

    var cardBuilder: CardBuildable {
        return CardBuilder(dependency: self)
    }

    var theme: Theme {
        return dependency.theme
    }

    var environmentController: EnvironmentControlling {
        return dependency.environmentController
    }

    var interfaceOrientationStream: InterfaceOrientationStreaming {
        return dependency.interfaceOrientationStream
    }

    var dataController: ExposureDataControlling {
        return dependency.dataController
    }

    var pauseController: PauseControlling {
        dependency.pauseController
    }

    var exposureController: ExposureControlling {
        dependency.exposureController
    }

    var applicationController: ApplicationControlling {
        return ApplicationController()
    }
}

final class StatusBuilder: Builder<StatusDependency>, StatusBuildable {
    func build(withListener listener: StatusListener, topAnchor: NSLayoutYAxisAnchor?) -> ViewControllable {
        let dependencyProvider = StatusDependencyProvider(dependency: dependency)

        let viewController = StatusViewController(
            exposureStateStream: dependencyProvider.exposureStateStream,
            interfaceOrientationStream: dependencyProvider.interfaceOrientationStream,
            cardBuilder: dependencyProvider.cardBuilder,
            listener: listener,
            theme: dependencyProvider.dependency.theme,
            topAnchor: topAnchor,
            dataController: dependencyProvider.dataController,
            pushNotificationStream: dependencyProvider.dependency.pushNotificationStream,
            applicationController: dependencyProvider.applicationController
        )

        return viewController
    }
}
