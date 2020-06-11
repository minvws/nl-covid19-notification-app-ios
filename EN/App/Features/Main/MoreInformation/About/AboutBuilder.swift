/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol AboutListener: AnyObject {
    func aboutRequestsDismissal(shouldHideViewController: Bool)
}

/// @mockable
protocol AboutBuildable {
    /// Builds About
    ///
    /// - Parameter listener: Listener of created AboutViewController
    func build(withListener listener: AboutListener) -> ViewControllable
}

final class AboutDependencyProvider: DependencyProvider<EmptyDependency> {
    var webBuilder: WebBuildable {
        return WebBuilder()
    }
}

final class AboutBuilder: Builder<EmptyDependency>, AboutBuildable {
    func build(withListener listener: AboutListener) -> ViewControllable {
        let dependencyProvider = AboutDependencyProvider()
        
        return AboutViewController(listener: listener,
                                   webBuilder: dependencyProvider.webBuilder)
    }
}
