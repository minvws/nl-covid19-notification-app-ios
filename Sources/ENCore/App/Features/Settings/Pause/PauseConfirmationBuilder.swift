/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol PauseConfirmationListener: AnyObject {
    func pauseConfirmationWantsDismissal(shouldDismissViewController: Bool)
    func pauseConfirmationWantsPauseOptions()
}

/// @mockable
protocol PauseConfirmationBuildable {
    /// Builds PauseConfirmation
    ///
    /// - Parameter listener: Listener of created PauseConfirmation component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: PauseConfirmationListener) -> Routing
}

protocol PauseConfirmationDependency {
    var theme: Theme { get }
    var pauseController: PauseControlling { get }
}

private final class PauseConfirmationDependencyProvider: DependencyProvider<PauseConfirmationDependency> {}

final class PauseConfirmationBuilder: Builder<PauseConfirmationDependency>, PauseConfirmationBuildable {
    func build(withListener listener: PauseConfirmationListener) -> Routing {

        let dependencyProvider = PauseConfirmationDependencyProvider(dependency: dependency)
        let viewController = PauseConfirmationViewController(theme: dependencyProvider.dependency.theme,
                                                             listener: listener,
                                                             pauseController: dependencyProvider.dependency.pauseController)
        return PauseConfirmationRouter(listener: listener,
                                       viewController: viewController)
    }
}
