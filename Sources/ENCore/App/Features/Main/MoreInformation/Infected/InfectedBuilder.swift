/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation

/// @mockable
protocol InfectedListener: AnyObject {
    func infectedWantsDismissal(shouldDismissViewController: Bool)
}

/// @mockable
protocol InfectedBuildable {
    /// Builds Infected
    ///
    /// - Parameter listener: Listener of created Infected component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: InfectedListener) -> Routing
}

protocol InfectedDependency {
    var theme: Theme { get }
    var exposureController: ExposureControlling { get }
    var exposureStateStream: ExposureStateStreaming { get }
    var bluetoothEnabledStream: AnyPublisher<Bool, Never> { get }
}

private final class InfectedDependencyProvider: DependencyProvider<InfectedDependency>, ThankYouDependency, CardDependency {

    var theme: Theme {
        dependency.theme
    }

    var thankYouBuilder: ThankYouBuildable {
        ThankYouBuilder(dependency: self)
    }

    var cardBuilder: CardBuildable {
        return CardBuilder(dependency: self)
    }

    var bluetoothEnabledStream: AnyPublisher<Bool, Never> {
        return dependency.bluetoothEnabledStream
    }
}

final class InfectedBuilder: Builder<InfectedDependency>, InfectedBuildable {
    func build(withListener listener: InfectedListener) -> Routing {
        let dependencyProvider = InfectedDependencyProvider(dependency: dependency)
        let viewController = InfectedViewController(theme: dependencyProvider.dependency.theme,
                                                    exposureController: dependencyProvider.dependency.exposureController,
                                                    exposureStateStream: dependencyProvider.dependency.exposureStateStream)

        return InfectedRouter(listener: listener,
                              viewController: viewController,
                              thankYouBuilder: dependencyProvider.thankYouBuilder,
                              cardBuilder: dependencyProvider.cardBuilder)
    }
}
