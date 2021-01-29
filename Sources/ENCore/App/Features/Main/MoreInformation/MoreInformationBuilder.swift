/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol MoreInformationViewControllable: ViewControllable {}

/// @mockable
protocol MoreInformationListener: AnyObject {
    func moreInformationRequestsAbout()
    func moreInformationRequestsSettings()
    func moreInformationRequestsSharing()
    func moreInformationRequestsReceivedNotification()
    func moreInformationRequestsInfected()
    func moreInformationRequestsRequestTest()
}

/// @mockable
protocol MoreInformationBuildable {
    /// Builds MoreInformation
    ///
    /// - Parameter listener: Listener of created MoreInformation component
    /// - Returns Routing instance which should be presented by parent
    func build(withListener listener: MoreInformationListener) -> MoreInformationViewControllable
}

protocol MoreInformationDependency {
    var theme: Theme { get }
    var exposureController: ExposureControlling { get }
}

private final class MoreInformationDependencyProvider: DependencyProvider<MoreInformationDependency> {

    fileprivate var bundleInfoDictionary: [String: Any]? {
        return Bundle.main.infoDictionary
    }
}

final class MoreInformationBuilder: Builder<MoreInformationDependency>, MoreInformationBuildable {
    func build(withListener listener: MoreInformationListener) -> MoreInformationViewControllable {
        let dependencyProvider = MoreInformationDependencyProvider(dependency: dependency)

        return MoreInformationViewController(listener: listener,
                                             theme: dependencyProvider.dependency.theme,
                                             bundleInfoDictionary: dependencyProvider.bundleInfoDictionary,
                                             exposureController: dependencyProvider.dependency.exposureController)
    }
}
