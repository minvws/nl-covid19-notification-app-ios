/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol ShareKeyViaWebsiteListener: AnyObject {
    func shareKeyViaWebsiteWantsDismissal(shouldDismissViewController: Bool)
}

/// @mockable(history:build=true)
protocol ShareKeyViaWebsiteBuildable {
    /// Builds ShareKeyViaWebsite
    ///
    /// - Parameter listener: Listener of created component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: ShareKeyViaWebsiteListener) -> Routing
}

protocol ShareKeyViaWebsiteDependency {
    var theme: Theme { get }
    var exposureController: ExposureControlling { get }
    var exposureStateStream: ExposureStateStreaming { get }
    var environmentController: EnvironmentControlling { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
    var storageController: StorageControlling { get }
    var dataController: ExposureDataControlling { get }
    var pauseController: PauseControlling { get }
}

private final class ShareKeyViaWebsiteDependencyProvider: DependencyProvider<ShareKeyViaWebsiteDependency>, ThankYouDependency, CardDependency, HelpDetailDependency {

    var theme: Theme {
        dependency.theme
    }

    var exposureController: ExposureControlling {
        dependency.exposureController
    }

    var thankYouBuilder: ThankYouBuildable {
        ThankYouBuilder(dependency: self)
    }

    var cardBuilder: CardBuildable {
        return CardBuilder(dependency: self)
    }

    var helpDetailBuilder: HelpDetailBuildable {
        return HelpDetailBuilder(dependency: self)
    }

    var exposureStateStream: ExposureStateStreaming {
        return dependency.exposureStateStream
    }

    var environmentController: EnvironmentControlling {
        return dependency.environmentController
    }

    var interfaceOrientationStream: InterfaceOrientationStreaming {
        return dependency.interfaceOrientationStream
    }

    var storageController: StorageControlling {
        return dependency.storageController
    }

    var dataController: ExposureDataControlling {
        dependency.dataController
    }

    var pauseController: PauseControlling {
        dependency.pauseController
    }
    
    var applicationController: ApplicationControlling {
        return ApplicationController()
    }
}

final class ShareKeyViaWebsiteBuilder: Builder<ShareKeyViaWebsiteDependency>, ShareKeyViaWebsiteBuildable {
    func build(withListener listener: ShareKeyViaWebsiteListener) -> Routing {
        
        let dependencyProvider = ShareKeyViaWebsiteDependencyProvider(dependency: dependency)
        
        let viewController = ShareKeyViaWebsiteViewController(theme: dependencyProvider.dependency.theme,
                                                            exposureController: dependencyProvider.dependency.exposureController,
                                                            exposureStateStream: dependencyProvider.dependency.exposureStateStream,
                                                            interfaceOrientationStream: dependencyProvider.dependency.interfaceOrientationStream,
                                                            applicationController: dependencyProvider.applicationController)
        
        return ShareKeyViaWebsiteRouter(listener: listener,
                                      viewController: viewController,
                                      thankYouBuilder: dependencyProvider.thankYouBuilder,
                                      cardBuilder: dependencyProvider.cardBuilder,
                                      helpDetailBuilder: dependencyProvider.helpDetailBuilder)
    }
}
