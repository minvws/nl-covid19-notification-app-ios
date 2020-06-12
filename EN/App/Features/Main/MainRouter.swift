/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol MainViewControllable: ViewControllable, StatusListener, MoreInformationListener, AboutListener {
    var router: MainRouting? { get set }
    
    func embed(stackedViewController: ViewControllable)
    func present(viewController: ViewControllable, animated: Bool)
    func dismiss(viewController: ViewControllable, animated: Bool)
}

final class MainRouter: Router<MainViewControllable>, MainRouting {
    
    init(viewController: MainViewControllable,
         statusBuilder: StatusBuildable,
         moreInformationBuilder: MoreInformationBuildable,
         aboutBuilder: AboutBuildable) {
        self.statusBuilder = statusBuilder
        self.moreInformationBuilder = moreInformationBuilder
        self.aboutBuilder = aboutBuilder
        
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

    func updateStatus(with viewModel: StatusViewModel) {
        statusRouter?.update(with: viewModel)
    }
    
    func routeToAboutApp() {
        guard aboutViewController == nil else { return }
        
        let aboutViewController = aboutBuilder.build(withListener: viewController)
        self.aboutViewController = aboutViewController
        
        viewController.present(viewController: aboutViewController, animated: true)
    }
    
    func detachAboutApp(shouldHideViewController: Bool) {
        guard let aboutViewController = aboutViewController else { return }
        self.aboutViewController = nil
        
        if shouldHideViewController {
            viewController.dismiss(viewController: aboutViewController, animated: true)
        }
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
    private var statusRouter: StatusRouting?
    
    private let moreInformationBuilder: MoreInformationBuildable
    private var moreInformationViewController: ViewControllable?
    
    private let aboutBuilder: AboutBuildable
    private var aboutViewController: ViewControllable?
}
