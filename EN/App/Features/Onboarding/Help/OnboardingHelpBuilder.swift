/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol OnboardingHelpListener: AnyObject {
    func helpRequestsFAQ()
    func helpRequestsPermission()
    func helpRequestsClose()
}

protocol OnboardingHelpDependency {
    var theme: Theme { get }
}

/// @mockable
protocol OnboardingHelpBuildable {
    /// Builds OnboardingHelp
    ///
    /// - Parameter listener: Listener of created OnboardingHelpViewController
    func build(withListener listener: OnboardingHelpListener) -> ViewControllable
}

private final class OnboardingHelpDependencyProvider: DependencyProvider<OnboardingHelpDependency> {
}

final class OnboardingHelpBuilder: Builder<OnboardingHelpDependency>, OnboardingHelpBuildable {
    func build(withListener listener: OnboardingHelpListener) -> ViewControllable {
        let dependencyProvidr = OnboardingHelpDependencyProvider(dependency: dependency)
        
        return OnboardingHelpViewController(listener: listener,
                                            theme: dependencyProvidr.dependency.theme)
    }
}
