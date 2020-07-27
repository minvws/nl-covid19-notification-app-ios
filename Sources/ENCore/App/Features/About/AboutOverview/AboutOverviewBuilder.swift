/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol AboutOverviewListener: AnyObject {
    func aboutOverviewRequestsDismissal(shouldDismissViewController: Bool)
    func aboutOverviewRequestsRouteTo(question: HelpQuestion)
    func aboutOverviewRequestsRouteToAppInformation()
    func aboutOverviewRequestsRouteToTechnicalInformation()
}

protocol AboutOverviewBuildable {
    func build(withListener listener: AboutOverviewListener) -> ViewControllable
}

protocol AboutOverviewDependency {
    var theme: Theme { get }
    var aboutManager: AboutManaging { get }
}

final class AboutOverviewDependencyDependencyProvider: DependencyProvider<AboutOverviewDependency> {}

final class AboutOverviewBuilder: Builder<AboutOverviewDependency>, AboutOverviewBuildable {
    func build(withListener listener: AboutOverviewListener) -> ViewControllable {
        let dependencyProvider = AboutOverviewDependencyDependencyProvider(dependency: dependency)

        return AboutOverviewViewController(listener: listener,
                                           aboutManager: dependencyProvider.dependency.aboutManager,
                                           theme: dependencyProvider.dependency.theme)
    }
}
