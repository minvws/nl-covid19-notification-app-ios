/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol OnboardingConsentListener: AnyObject {
    // TODO: Add any functions to communicate to the parent
    //       object, which should set itself as listener
}

/// @mockable
protocol OnboardingConsentBuildable {
    /// Builds OnboardingConsent
    ///
    /// - Parameter listener: Listener of created OnboardingConsentViewController
    func build(withListener listener: OnboardingConsentListener) -> ViewControllable
    func build(withListener listener: OnboardingConsentListener, initialIndex: Int) -> ViewControllable
}

protocol OnboardingConsentDependency {
    var onboardingConcentManager: OnboardingConsentManaging { get }
}

private final class OnboardingConsentDependencyProvider: DependencyProvider<OnboardingConsentDependency> {

}

final class OnboardingConsentBuilder: Builder<OnboardingConsentDependency>, OnboardingConsentBuildable {
    func build(withListener listener: OnboardingConsentListener) -> ViewControllable {
        return build(withListener: listener, initialIndex: 0)
    }

    func build(withListener listener: OnboardingConsentListener, initialIndex: Int = 0) -> ViewControllable {
        let dependencyProvider = OnboardingConsentDependencyProvider(dependency: dependency)
        let onboardingConcentManager = dependencyProvider.dependency.onboardingConcentManager

        return OnboardingConsentStepViewController(
            onboardingConsentManager: onboardingConcentManager,
            onboardingConcentStepBuilder: self,
            listener: listener,
            index: 0)
    }
}
