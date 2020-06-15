/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import UIKit

/// @mockable
protocol StatusListener: AnyObject {
    func handleButtonAction(_ action: StatusViewButtonModel.Action)
}

/// @mockable
protocol StatusBuildable {
    /// Builds Status
    ///
    /// - Parameter listener: Listener of created Status component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: StatusListener, topAnchor: NSLayoutYAxisAnchor?) -> Routing
}

protocol StatusDependency {
    var exposureStateStream: ExposureStateStreaming { get }
}

private final class StatusDependencyProvider: DependencyProvider<StatusDependency> {
    var exposureStateStream: ExposureStateStreaming {
        return dependency.exposureStateStream
    }
}

final class StatusBuilder: Builder<StatusDependency>, StatusBuildable {
    func build(withListener listener: StatusListener, topAnchor: NSLayoutYAxisAnchor?) -> Routing {
        let dependencyProvider = StatusDependencyProvider(dependency: dependency)
        
        let viewController = StatusViewController(
            exposureStateStream: dependencyProvider.exposureStateStream,
            listener: listener,
            topAnchor: topAnchor
        )
        
        return StatusRouter(listener: listener,
                            viewController: viewController)
    }
}
