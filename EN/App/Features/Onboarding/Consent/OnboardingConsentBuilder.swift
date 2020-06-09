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
}

protocol OnboardingConsentDependency {
    // TODO: Add any external dependency
}

private final class OnboardingConsentDependencyProvider: DependencyProvider<OnboardingConsentDependency> {
    // TODO: Create and return any dependency that should be limited
    //       to OnboardingConsent's scope or any child of OnboardingConsent
}

final class OnboardingConsentBuilder: Builder<OnboardingConsentDependency>, OnboardingConsentBuildable {    
    func build(withListener listener: OnboardingConsentListener) -> ViewControllable {
        // TODO: Add any other dynamic dependency as parameter
        
        let dependencyProvider = OnboardingConsentDependencyProvider(dependency: dependency)
        
        // TODO: Adjust the initialiser to use the correct parameters.
        //       Delete the `dependencyProvider` variable if not used.
        return OnboardingConsentViewController(listener: listener)
    }
}
