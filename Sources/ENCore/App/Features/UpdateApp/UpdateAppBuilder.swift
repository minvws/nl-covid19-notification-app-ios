/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol UpdateAppListener: AnyObject {}

/// @mockable
protocol UpdateAppBuildable {
    /// Builds UpdateApp
    ///
    /// - Parameter listener: Listener of created UpdateAppViewController
    func build(withListener listener: UpdateAppListener, iOSAppStoreURL: String?, iOSMinimumVersionMessage: String?) -> ViewControllable
}

protocol UpdateAppDependency {
    var theme: Theme { get }
}

private final class UpdateAppDependencyProvider: DependencyProvider<UpdateAppDependency> {}

final class UpdateAppBuilder: Builder<UpdateAppDependency>, UpdateAppBuildable {
    func build(withListener listener: UpdateAppListener, iOSAppStoreURL: String?, iOSMinimumVersionMessage: String?) -> ViewControllable {
        let dependencyProvider = UpdateAppDependencyProvider(dependency: dependency)
        return UpdateAppViewController(listener: listener,
                                       theme: dependencyProvider.dependency.theme,
                                       iOSAppStoreURL: iOSAppStoreURL,
                                       iOSMinimumVersionMessage: iOSMinimumVersionMessage)
    }
}
