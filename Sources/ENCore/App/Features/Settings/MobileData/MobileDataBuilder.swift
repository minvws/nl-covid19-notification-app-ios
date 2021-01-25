/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol MobileDataListener: AnyObject {
    func mobileDataWantsDismissal(shouldDismissViewController: Bool)
}

/// @mockable
protocol MobileDataBuildable {
    func build(withListener listener: MobileDataListener) -> ViewControllable
}

protocol MobileDataDependency {
    var theme: Theme { get }
}

final class MobileDataDependencyDependencyProvider: DependencyProvider<MobileDataDependency> {}

final class MobileDataBuilder: Builder<MobileDataDependency>, MobileDataBuildable {
    func build(withListener listener: MobileDataListener) -> ViewControllable {
        let dependencyProvider = MobileDataDependencyDependencyProvider(dependency: dependency)

        return MobileDataViewController(listener: listener,
                                        theme: dependencyProvider.dependency.theme)
    }
}
