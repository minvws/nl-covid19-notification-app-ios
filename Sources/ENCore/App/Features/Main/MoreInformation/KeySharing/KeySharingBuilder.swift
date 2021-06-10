/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable(history:keySharingWantsDismissal=true)
protocol KeySharingListener: AnyObject {
    func keySharingWantsDismissal(shouldDismissViewController: Bool)
}

/// @mockable(history:build=true)
protocol KeySharingBuildable {
    /// Builds KeySharing
    ///
    /// - Parameter listener: Listener of created KeySharing component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: KeySharingListener) -> Routing
}

/// @mockable
protocol KeySharingDependency {
    var theme: Theme { get }
    var exposureController: ExposureControlling { get }
    var exposureStateStream: ExposureStateStreaming { get }
    var environmentController: EnvironmentControlling { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
    var storageController: StorageControlling { get }
    var dataController: ExposureDataControlling { get }
    var pauseController: PauseControlling { get }
}

private final class KeySharingDependencyProvider: DependencyProvider<KeySharingDependency>, ShareKeyViaPhoneDependency {
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
    
    var shareKeyViaPhoneBuilder: ShareKeyViaPhoneBuildable {
        return ShareKeyViaPhoneBuilder(dependency: self)
    }
    
    var featureFlagController: FeatureFlagControlling {
        FeatureFlagController(userDefaults: UserDefaults.standard,
                              exposureController: exposureController,
                              environmentController: environmentController)
    }
}

final class KeySharingBuilder: Builder<KeySharingDependency>, KeySharingBuildable {
    func build(withListener listener: KeySharingListener) -> Routing {
        
        let dependencyProvider = KeySharingDependencyProvider(dependency: dependency)
        
        let viewController = KeySharingViewController(theme: dependencyProvider.dependency.theme)
        
        return KeySharingRouter(listener: listener,
                                          viewController: viewController,
                                          shareKeyViaPhoneBuilder: dependencyProvider.shareKeyViaPhoneBuilder,
                                          featureFlagController: dependencyProvider.featureFlagController
        )
    }
}
