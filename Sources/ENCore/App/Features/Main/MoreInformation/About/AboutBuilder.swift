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

protocol AboutDependency {
    var theme: Theme { get }
}

/// @mockable
protocol AboutBuildable {
    /// Builds About
    ///
    /// - Parameter listener: Listener of created AboutViewController
    func build(withListener listener: AboutListener) -> ViewControllable
}

final class AboutDependencyProvider: DependencyProvider<AboutDependency>, WebDependency {
    var theme: Theme {
        return dependency.theme
    }

    var webBuilder: WebBuildable {
        return WebBuilder(dependency: self)
    }
}

final class AboutBuilder: Builder<AboutDependency>, AboutBuildable {
    func build(withListener listener: AboutListener) -> ViewControllable {
        let dependencyProvider = AboutDependencyProvider(dependency: dependency)

        return AboutViewController(listener: listener,
                                   theme: dependencyProvider.dependency.theme,
                                   webBuilder: dependencyProvider.webBuilder)
    }
}
