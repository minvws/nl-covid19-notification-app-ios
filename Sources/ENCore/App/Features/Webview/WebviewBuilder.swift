/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol WebviewListener: AnyObject {
    func webviewRequestsDismissal(shouldHideViewController: Bool)
}

/// @mockable
protocol WebviewBuildable {
    func build(withListener listener: WebviewListener, url: URL) -> ViewControllable
}

protocol WebviewDependency {
    var theme: Theme { get }
}

private final class WebviewDependencyProvider: DependencyProvider<WebviewDependency> {}

final class WebviewBuilder: Builder<WebviewDependency>, WebviewBuildable {
    func build(withListener listener: WebviewListener, url: URL) -> ViewControllable {
        let dependencyProvider = WebviewDependencyProvider(dependency: dependency)

        return WebviewViewController(listener: listener, url: url, theme: dependencyProvider.dependency.theme)
    }
}
