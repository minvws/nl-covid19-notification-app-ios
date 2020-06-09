/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol WebListener: AnyObject {
    func webRequestsDismissal(shouldHideViewController: Bool)
}

/// @mockable
protocol WebBuildable {
    /// Builds Web
    ///
    /// - Parameter listener: Listener of created WebViewController
    func build(withListener listener: WebListener, urlRequest: URLRequest) -> ViewControllable
}

final class WebBuilder: Builder<EmptyDependency>, WebBuildable {
    func build(withListener listener: WebListener, urlRequest: URLRequest) -> ViewControllable {
        return WebViewController(listener: listener, urlRequest: urlRequest)
    }
}
