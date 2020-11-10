/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol RequestTestListener: AnyObject {
    func requestTestWantsDismissal(shouldDismissViewController: Bool)
}

/// @mockable
protocol RequestTestBuildable {
    /// Builds RequestTest
    ///
    /// - Parameter listener: Listener of created RequestTest component
    func build(withListener listener: RequestTestListener) -> ViewControllable
}

protocol RequestTestDependency {
    var theme: Theme { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
}

private final class RequestTestDependencyProvider: DependencyProvider<RequestTestDependency> {}

final class RequestTestBuilder: Builder<RequestTestDependency>, RequestTestBuildable {
    func build(withListener listener: RequestTestListener) -> ViewControllable {
        let dependencyProvider = RequestTestDependencyProvider(dependency: dependency)
        return RequestTestViewController(listener: listener,
                                         theme: dependencyProvider.dependency.theme,
                                         interfaceOrientationStream: dependencyProvider.dependency.interfaceOrientationStream)
    }
}
