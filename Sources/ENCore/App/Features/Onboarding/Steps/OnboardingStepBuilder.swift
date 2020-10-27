/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol OnboardingStepBuildable {
    func build(withListener listener: OnboardingStepListener) -> ViewControllable
    func build(withListener listener: OnboardingStepListener, initialIndex: Int) -> ViewControllable
}

protocol OnboardingStepDependency {
    var theme: Theme { get }
    var onboardingManager: OnboardingManaging { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
}

/// @mockable
protocol OnboardingStepListener: AnyObject {
    func onboardingStepsDidComplete()
    func nextStepAtIndex(_ index: Int)
}

final class OnboardingStepDependencyProvider: DependencyProvider<OnboardingStepDependency> {}

final class OnboardingStepBuilder: Builder<OnboardingStepDependency>, OnboardingStepBuildable {
    func build(withListener listener: OnboardingStepListener) -> ViewControllable {
        return build(withListener: listener, initialIndex: 0)
    }

    func build(withListener listener: OnboardingStepListener, initialIndex: Int = 0) -> ViewControllable {
        let dependencyProvider = OnboardingStepDependencyProvider(dependency: dependency)
        let onboardingManager = dependencyProvider.dependency.onboardingManager

        return OnboardingStepViewController(onboardingManager: onboardingManager,
                                            onboardingStepBuilder: self,
                                            listener: listener,
                                            theme: dependencyProvider.dependency.theme,
                                            index: initialIndex,
                                            interfaceOrientationStream: dependencyProvider.dependency.interfaceOrientationStream)
    }
}
