/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import WebKit

/// @mockable
protocol WebListener: AnyObject {
}

/// @mockable
protocol WebBuildable {
    /// Builds Web
    ///
    /// - Parameter listener: Listener of created WebViewController
    func build(withListener listener: WebListener, urlRequest: URLRequest) -> ViewControllable
}

extension WKWebView: WebViewing {
    var uiview: UIView { return self }
    
    func load(request: URLRequest) {
        load(request)
    }
}

private final class WebDependencyProvider: DependencyProvider<EmptyDependency> {
    var webView: WebViewing {
        return WKWebView()
    }
}

final class WebBuilder: Builder<EmptyDependency>, WebBuildable {
    func build(withListener listener: WebListener, urlRequest: URLRequest) -> ViewControllable {
        let dependencyProvider = WebDependencyProvider()
        
        return WebViewController(listener: listener,
                                 webView: dependencyProvider.webView,
                                 urlRequest: urlRequest)
    }
}
