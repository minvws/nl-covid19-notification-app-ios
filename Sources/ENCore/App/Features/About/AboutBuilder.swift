/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol AboutListener: AnyObject {
    func aboutRequestsDismissal(shouldHideViewController: Bool)
}

/// @mockable
protocol AboutBuildable {
    func build(withListener listener: AboutListener) -> Routing
}

protocol AboutDependency {
    var theme: Theme { get }
}

private final class AboutDependencyProvider: DependencyProvider<AboutDependency>, AboutOverviewDependency, HelpDetailDependency {

    // MARK: - HelpOverviewDependency

    lazy var aboutManager: AboutManaging = AboutManager(theme: dependency.theme)

    // MARK: - Forwarding Dependencies

    var theme: Theme {
        return dependency.theme
    }

    // MARK: - Child Builders

    var overviewBuilder: AboutOverviewBuildable {
        return AboutOverviewBuilder(dependency: self)
    }

    var detailBuilder: HelpDetailBuildable {
        return HelpDetailBuilder(dependency: self)
    }
}

final class AboutBuilder: Builder<AboutDependency>, AboutBuildable {

    func build(withListener listener: AboutListener) -> Routing {
        let dependencyProvider = AboutDependencyProvider(dependency: dependency)
        let viewController = AboutViewController(listener: listener,
                                                 theme: dependencyProvider.dependency.theme)

        return AboutRouter(viewController: viewController,
                           aboutOverviewBuilder: dependencyProvider.overviewBuilder,
                           helpDetailBuilder: dependencyProvider.detailBuilder)
    }
}
