/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol AppInformationListener: AnyObject {
    func appInformationRequestsToTechnicalInformation()
    func appInformationRequestRedirect(to content: LinkedContent)
}

/// @mockable
protocol AppInformationBuildable {
    func build(withListener listener: AppInformationListener) -> ViewControllable
}

protocol AppInformationDependency {
    var theme: Theme { get }
    var aboutManager: AboutManaging { get }
}

private final class AppInformationDependencyProvider: DependencyProvider<AppInformationDependency> {}

final class AppInformationBuilder: Builder<AppInformationDependency>, AppInformationBuildable {

    func build(withListener listener: AppInformationListener) -> ViewControllable {
        let dependencyProvider = AppInformationDependencyProvider(dependency: dependency)

        return AppInformationViewController(listener: listener,
                                            linkedContent: dependencyProvider.dependency.aboutManager.appInformationEntry.linkedEntries,
                                            theme: dependencyProvider.dependency.theme)
    }
}
