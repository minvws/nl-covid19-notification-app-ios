/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol UpdateOperatingSystemBuildable {
    func build() -> ViewControllable
}

protocol UpdateOperatingSystemDependency {
    var theme: Theme { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
    var enableSettingBuilder: EnableSettingBuildable { get }
}

private final class UpdateOperatingSystemDependencyProvider: DependencyProvider<UpdateOperatingSystemDependency> {

    // MARK: - Forwarding Dependencies

    var theme: Theme {
        return dependency.theme
    }

    var interfaceOrientationStream: InterfaceOrientationStreaming {
        return dependency.interfaceOrientationStream
    }

    var enableSettingBuilder: EnableSettingBuildable {
        return dependency.enableSettingBuilder
    }
}

final class UpdateOperatingSystemBuilder: Builder<UpdateOperatingSystemDependency>, UpdateOperatingSystemBuildable {

    func build() -> ViewControllable {
        let dependencyProvider = UpdateOperatingSystemDependencyProvider(dependency: dependency)
        let viewController = UpdateOperatingSystemViewController(theme: dependencyProvider.theme,
                                                                 interfaceOrientationStream: dependencyProvider.interfaceOrientationStream,
                                                                 enableSettingBuilder: dependencyProvider.enableSettingBuilder)

        return viewController
    }
}
