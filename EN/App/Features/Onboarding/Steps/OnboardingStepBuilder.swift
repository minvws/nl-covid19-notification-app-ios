/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol OnboardingStepBuildable {
    func build() -> ViewControllable
    func build(initialIndex: Int) -> ViewControllable
}

protocol OnboardingStepDependency {
    var onboardingManager: OnboardingManaging { get }
}

final class OnboardingStepDependencyProvider: DependencyProvider<OnboardingStepDependency> {
    
}

final class OnboardingStepBuilder: Builder<OnboardingStepDependency>, OnboardingStepBuildable {
    func build() -> ViewControllable {
        return build(initialIndex: 0)
    }
    
    func build(initialIndex: Int = 0) -> ViewControllable {
        let dependencyProvider = OnboardingStepDependencyProvider(dependency: dependency)
        let onboardingManager = dependencyProvider.dependency.onboardingManager
        
        return OnboardingStepViewController(onboardingManager: onboardingManager,
                                            onboardingStepBuilder: self,
                                            index: initialIndex)
    }
}
