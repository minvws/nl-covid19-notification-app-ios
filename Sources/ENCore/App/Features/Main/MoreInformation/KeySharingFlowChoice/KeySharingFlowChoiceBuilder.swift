/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol KeySharingFlowChoiceListener: AnyObject {
    func KeySharingFlowChoiceWantsDismissal(shouldDismissViewController: Bool)
}

/// @mockable
protocol KeySharingFlowChoiceBuildable {
    /// Builds KeySharingFlowChoice
    ///
    /// - Parameter listener: Listener of created KeySharingFlowChoice component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: KeySharingFlowChoiceListener) -> Routing
}

protocol KeySharingFlowChoiceDependency {
    var theme: Theme { get }
    var exposureController: ExposureControlling { get }
    var exposureStateStream: ExposureStateStreaming { get }
    var environmentController: EnvironmentControlling { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
    var storageController: StorageControlling { get }
    var dataController: ExposureDataControlling { get }
    var pauseController: PauseControlling { get }
}

private final class KeySharingFlowChoiceDependencyProvider: DependencyProvider<KeySharingFlowChoiceDependency>, InfectedDependency {
    var theme: Theme {
        dependency.theme
    }
    
    var exposureController: ExposureControlling {
        dependency.exposureController
    }
    
    var exposureStateStream: ExposureStateStreaming{
        dependency.exposureStateStream
    }
    
    var environmentController: EnvironmentControlling {
        dependency.environmentController
    }
    
    var interfaceOrientationStream: InterfaceOrientationStreaming {
        dependency.interfaceOrientationStream
    }
    
    var storageController: StorageControlling {
        dependency.storageController
    }
    
    var dataController: ExposureDataControlling {
        dependency.dataController
    }
    
    var pauseController: PauseControlling {
        dependency.pauseController
    }
    
    var infectedBuilder: InfectedBuildable {
        return InfectedBuilder(dependency: self)
    }
}

final class KeySharingFlowChoiceBuilder: Builder<KeySharingFlowChoiceDependency>, KeySharingFlowChoiceBuildable {
    func build(withListener listener: KeySharingFlowChoiceListener) -> Routing {
        
        let dependencyProvider = KeySharingFlowChoiceDependencyProvider(dependency: dependency)
        
        let viewController = KeySharingFlowChoiceViewController(theme: dependencyProvider.dependency.theme)
        
        return KeySharingFlowChoiceRouter(listener: listener,
                                          viewController: viewController,
                                          infectedBuilder: dependencyProvider.infectedBuilder
        )
    }
}
