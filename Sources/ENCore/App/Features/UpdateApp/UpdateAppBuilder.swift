/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol UpdateAppBuildable {
    /// Builds UpdateApp
    ///
    /// - Parameter listener: Listener of created UpdateAppViewController
    func build(appStoreURL: String?, minimumVersionMessage: String?) -> ViewControllable
}

protocol UpdateAppDependency {
    var theme: Theme { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
}

private final class UpdateAppDependencyProvider: DependencyProvider<UpdateAppDependency> {
    var interfaceOrientationStream: InterfaceOrientationStreaming {
        dependency.interfaceOrientationStream
    }
}

final class UpdateAppBuilder: Builder<UpdateAppDependency>, UpdateAppBuildable {
    func build(appStoreURL: String?, minimumVersionMessage: String?) -> ViewControllable {
        let dependencyProvider = UpdateAppDependencyProvider(dependency: dependency)
        return UpdateAppViewController(theme: dependencyProvider.dependency.theme,
                                       appStoreURL: appStoreURL,
                                       minimumVersionMessage: minimumVersionMessage,
                                       interfaceOrientationStream: dependencyProvider.interfaceOrientationStream)
    }
}
