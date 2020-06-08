/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol OnboardingListener: AnyObject {
    func didCompleteOnboarding()
}

/// @mockable
protocol OnboardingBuildable {
    func build(withListener listener: OnboardingListener) -> ViewControllable
}

///
/// - Tag: OnboardingDependencyProvider
private final class OnboardingDependencyProvider: DependencyProvider<EmptyDependency>, OnboardingStepDependency {
    
    // MARK: - OnboardingStepDependency
    
    lazy var onboardingManager: OnboardingManaging = OnboardingManager()
    
    // MARK: - Child Builders
    
    var stepBuilder: OnboardingStepBuildable {
        return OnboardingStepBuilder(dependency: self)
    }
}

final class OnboardingBuilder: Builder<EmptyDependency>, OnboardingBuildable {
    func build(withListener listener: OnboardingListener) -> ViewControllable {
        let dependencyProvider = OnboardingDependencyProvider(dependency: dependency)
        
        return OnboardingViewController(listener: listener,
                                        stepBuilder: dependencyProvider.stepBuilder)
    }
}
