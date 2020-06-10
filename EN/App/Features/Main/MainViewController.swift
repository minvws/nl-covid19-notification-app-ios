/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit

/// @mockable
protocol MainRouting: Routing {
    func attachStatus()
    func attachMoreInformation()
    
    func routeToAboutApp()
    func routeToReceivedNotification()
    func routeToInfected()
    func routeToRequestTest()
    func routeToShareApp()
    func routeToSettings()
}

final class MainViewController: ViewController, MainViewControllable, StatusListener, MoreInformationListener {
    
    // MARK: - MainViewControllable
    
    weak var router: MainRouting?
    
    func embed(stackedViewController: ViewControllable) {
        addChild(stackedViewController.uiviewController)
        
        let view: UIView = stackedViewController.uiviewController.view
        
        mainView.stackView.addArrangedSubview(view)
        view.widthAnchor.constraint(equalTo: mainView.widthAnchor).isActive = true
        
        stackedViewController.uiviewController.didMove(toParent: self)
    }
    
    // MARK: - MoreInformationListener
    
    func moreInformationRequestsAbout() {
        router?.routeToAboutApp()
    }
    
    func moreInformationRequestsReceivedNotification() {
        router?.routeToReceivedNotification()
    }
    
    func moreInformationRequestsInfected() {
        router?.routeToInfected()
    }
    
    func moreInformationRequestsRequestTest() {
        router?.routeToRequestTest()
    }
    
    func moreInformationRequestsShareApp() {
        router?.routeToShareApp()
    }
    
    func moreInformationRequestsSettings() {
        router?.routeToSettings()
    }
    
    // MARK: - View Lifecycle
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        router?.attachStatus()
        router?.attachMoreInformation()
    }
    
    // MARK: - Private
    
    private lazy var mainView: MainView = MainView()
}

private final class MainView: View {
    fileprivate let scrollView = UIScrollView()
    fileprivate let stackView = UIStackView()
    
    override func build() {
        super.build()
        
        addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        scrollView.alwaysBounceVertical = true
        
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            // scrollView
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // stackView
            stackView.widthAnchor.constraint(equalTo: widthAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
}
