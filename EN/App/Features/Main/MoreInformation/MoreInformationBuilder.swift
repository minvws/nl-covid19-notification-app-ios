/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol MoreInformationViewControllable: ViewControllable {
    
}

/// @mockable
protocol MoreInformationListener: AnyObject {
    func moreInformationRequestsAbout()
    func moreInformationRequestsReceivedNotification()
    func moreInformationRequestsInfected()
    func moreInformationRequestsRequestTest()
    func moreInformationRequestsShareApp()
    func moreInformationRequestsSettings()
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
    // TODO: Add any external dependency
}

private final class MoreInformationDependencyProvider: DependencyProvider<MoreInformationDependency> /*, ChildDependency */ {
    var tableController: MoreInformationTableControlling {
        return MoreInformationTableController()
    }
}

final class MoreInformationBuilder: Builder<MoreInformationDependency>, MoreInformationBuildable {
    func build(withListener listener: MoreInformationListener) -> MoreInformationViewControllable {
        let dependencyProvider = MoreInformationDependencyProvider(dependency: dependency)
        
        let tableController = dependencyProvider.tableController
        return MoreInformationViewController(listener: listener,
                                             tableController: tableController)
    }
}
