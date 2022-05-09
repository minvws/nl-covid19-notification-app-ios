/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol EndOfLifeListener: AnyObject {
    func endOfLifeRequestsRedirect(to url: URL)
}

/// @mockable
protocol EndOfLifeBuildable {
    /// Builds EndOfLife
    ///
    /// - Parameter listener: Listener of created EndOfLifeViewController
    func build(withListener listener: EndOfLifeListener) -> ViewControllable
}

protocol EndOfLifeDependency {
    var theme: Theme { get }
    var storageController: StorageControlling { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
}

private final class EndOfLifeDependencyProvider: DependencyProvider<EndOfLifeDependency> {}

final class EndOfLifeBuilder: Builder<EndOfLifeDependency>, EndOfLifeBuildable {
    func build(withListener listener: EndOfLifeListener) -> ViewControllable {
        let dependencyProvider = EndOfLifeDependencyProvider(dependency: dependency)
        return EndOfLifeViewController(listener: listener,
                                       theme: dependencyProvider.dependency.theme,
                                       storageController: dependencyProvider.dependency.storageController,
                                       interfaceOrientationStream: dependencyProvider.dependency.interfaceOrientationStream)
    }
}
