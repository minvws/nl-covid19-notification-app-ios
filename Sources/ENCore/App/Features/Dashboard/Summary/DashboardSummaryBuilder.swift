/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol DashboardSummaryListener: AnyObject {
    func dashboardSummaryRequestsRouteToDetail(with identifier: DashboardIdentifier)
}

/// @mockable
protocol DashboardSummaryBuildable {
    /// Builds Dashboard
    ///
    /// - Parameter listener: Listener of created Dashboard component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: DashboardSummaryListener) -> ViewControllable
}

protocol DashboardSummaryDependency {
    var theme: Theme { get }
    var dataController: ExposureDataControlling { get }
    var storageController: StorageControlling { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
    var exposureStateStream: ExposureStateStreaming { get }
}

private final class DashboardSummaryDependencyProvider: DependencyProvider<DashboardSummaryDependency> {
    // MARK: - Forwarding Dependencies

    var theme: Theme {
        return dependency.theme
    }

    var dataController: ExposureDataControlling {
        return dependency.dataController
    }

    var interfaceOrientationStream: InterfaceOrientationStreaming {
        return dependency.interfaceOrientationStream
    }

    var exposureStateStream: ExposureStateStreaming {
        return dependency.exposureStateStream
    }

    var applicationLifecycleStream: ApplicationLifecycleStreaming {
        return ApplicationLifecycleStream()
    }
}

final class DashboardSummaryBuilder: Builder<DashboardSummaryDependency>, DashboardSummaryBuildable {
    func build(withListener listener: DashboardSummaryListener) -> ViewControllable {

        let dependencyProvider = DashboardSummaryDependencyProvider(dependency: dependency)

        // let childBuilder = dependencyProvider.childBuilder
        let viewController = DashboardSummaryViewController(listener: listener,
                                                            theme: dependencyProvider.theme,
                                                            dataController: dependencyProvider.dataController,
                                                            interfaceOrientationStream: dependencyProvider.interfaceOrientationStream,
                                                            exposureStateStream: dependencyProvider.exposureStateStream,
                                                            applicationLifecycleStream: dependencyProvider.applicationLifecycleStream)
        return viewController
    }
}
