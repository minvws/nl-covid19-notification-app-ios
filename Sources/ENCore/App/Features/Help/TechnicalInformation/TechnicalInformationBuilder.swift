/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol TechnicalInformationListener: AnyObject {}

protocol TechnicalInformationBuildable {
    func build(withListener listener: TechnicalInformationListener) -> ViewControllable
}

protocol TechnicalInformationDependency {
    var theme: Theme { get }
}

private final class TechnicalInformationDependencyProvider: DependencyProvider<TechnicalInformationDependency> {}

final class TechnicalInformationBuilder: Builder<TechnicalInformationDependency>, TechnicalInformationBuildable {

    func build(withListener listener: TechnicalInformationListener) -> ViewControllable {
        let dependencyProvider = TechnicalInformationDependencyProvider(dependency: dependency)

        return TechnicalInformationViewController(listener: listener, theme: dependencyProvider.dependency.theme)
    }
}
