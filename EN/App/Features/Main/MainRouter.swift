/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol MainViewControllable: ViewControllable, StatusListener, MoreInformationListener {
    var router: MainRouting? { get set }
    
    func embed(stackedViewController: ViewControllable)
}

final class MainRouter: Router<MainViewControllable>, MainRouting {
    
    init(viewController: MainViewControllable,
         statusBuilder: StatusBuildable,
         moreInformationBuilder: MoreInformationBuildable) {
        self.statusBuilder = statusBuilder
        self.moreInformationBuilder = moreInformationBuilder
        
        super.init(viewController: viewController)
        
        viewController.router = self
    }
    
    // MARK: - MainRouting
    
    func attachStatus() {
        guard statusRouter == nil else { return }
        
        let statusRouter = statusBuilder.build(withListener: viewController)
        self.statusRouter = statusRouter
        
        viewController.embed(stackedViewController: statusRouter.viewControllable)
    }
    
    func attachMoreInformation() {
        guard moreInformationViewController == nil else { return }
        
        let moreInformationViewController = moreInformationBuilder.build(withListener: viewController)
        self.moreInformationViewController = moreInformationViewController
        
        viewController.embed(stackedViewController: moreInformationViewController)
    }
    
    func routeToAboutApp() {
        
    }
    
    func routeToReceivedNotification() {
        
    }
    
    func routeToInfected() {
        
    }
    
    func routeToRequestTest() {
        
    }
    
    func routeToShareApp() {
        
    }
    
    func routeToSettings() {
        
    }
    
    // MARK: - Private
    
    private let statusBuilder: StatusBuildable
    private var statusRouter: Routing?
    
    private let moreInformationBuilder: MoreInformationBuildable
    private var moreInformationViewController: ViewControllable?
}
