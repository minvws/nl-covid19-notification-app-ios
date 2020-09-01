/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol TechnicalInformationListener: AnyObject {
    func technicalInformationRequestsToAppInformation()
    func technicalInformationRequestRedirect(to content: LinkedContent)
}

/// @mockable
protocol TechnicalInformationBuildable {
    func build(withListener listener: TechnicalInformationListener) -> Routing
}

protocol TechnicalInformationDependency {
    var theme: Theme { get }
    var aboutManager: AboutManaging { get }
}

private final class TechnicalInformationDependencyProvider: DependencyProvider<TechnicalInformationDependency> {}

final class TechnicalInformationBuilder: Builder<TechnicalInformationDependency>, TechnicalInformationBuildable {

    func build(withListener listener: TechnicalInformationListener) -> Routing {
        let dependencyProvider = TechnicalInformationDependencyProvider(dependency: dependency)
        let viewController = TechnicalInformationViewController(listener: listener,
                                                                linkedContent: dependencyProvider.dependency.aboutManager.technicalInformationEntry.linkedEntries,
                                                                theme: dependencyProvider.dependency.theme)
        return TechnicalInformationRouter(viewController: viewController)
    }
}
