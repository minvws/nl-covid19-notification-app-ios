/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol OnboardingViewControllable: ViewControllable {
    
}

final class OnboardingViewController: NavigationController, OnboardingViewControllable {
    
    init(listener: OnboardingListener,
         stepBuilder: OnboardingStepBuildable) {
        self.listener = listener
        self.stepBuilder = stepBuilder
        
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let stepViewController = stepBuilder.build()
        pushViewController(stepViewController.uiviewController, animated: false)
        
        self.stepViewController = stepViewController
    }
    
    // MARK: - Private
    
    private weak var listener: OnboardingListener?
    
    private let stepBuilder: OnboardingStepBuildable
    private var stepViewController: ViewControllable?
}
