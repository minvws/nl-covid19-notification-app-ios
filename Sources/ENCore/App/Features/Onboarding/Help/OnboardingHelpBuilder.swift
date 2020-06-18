/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol OnboardingHelpListener: AnyObject {
    func displayHelp()
    func displayHelpDetail(withOnboardingConsentHelp onboardingConsentHelp: OnboardingConsentHelp)
}

protocol OnboardingHelpDependency {
    var theme: Theme { get }
}

/// @mockable
protocol OnboardingHelpBuildable {
    /// Builds OnboardingHelp
    ///
    /// - Parameter listener: Listener of created OnboardingHelpViewController
    func build(withListener listener: OnboardingHelpListener) -> Routing
    func buildOverview(withListener listener: OnboardingHelpListener) -> ViewControllable
    func buildDetail(withListener listener: OnboardingHelpListener, onboardingConsentHelp: OnboardingConsentHelp) -> ViewControllable
}

private final class OnboardingHelpDependencyProvider: DependencyProvider<OnboardingHelpDependency> { }

final class OnboardingHelpBuilder: Builder<OnboardingHelpDependency>, OnboardingHelpBuildable {

    lazy var onboardingConsentHelpManager: OnboardingConsentHelpManaging = {
        OnboardingConsentHelpManager(theme: self.theme)
    }()

    // MARK: - OnboardingConsentHelpDependency

    var theme: Theme {
        return dependency.theme
    }

    func build(withListener listener: OnboardingHelpListener) -> Routing {
        let dependencyProvider = OnboardingHelpDependencyProvider(dependency: dependency)
        let viewController = OnboardingHelpViewController(listener: listener,
            theme: dependencyProvider.dependency.theme)

        return OnboardingHelpRouter(viewController: viewController, helpBuilder: self)
    }

    func buildOverview(withListener listener: OnboardingHelpListener) -> ViewControllable {
        let dependencyProvider = OnboardingHelpDependencyProvider(dependency: dependency)

        return OnboardingHelpOverviewViewController(onboardingConsentHelpManager: self.onboardingConsentHelpManager, listener: listener,
            theme: dependencyProvider.dependency.theme)
    }

    func buildDetail(withListener listener: OnboardingHelpListener, onboardingConsentHelp: OnboardingConsentHelp) -> ViewControllable {
        let dependencyProvidr = OnboardingHelpDependencyProvider(dependency: dependency)

        return OnboardingHelpDetailViewController(listener: listener,
            onboardingConsentHelp: onboardingConsentHelp,
            theme: dependencyProvidr.dependency.theme)
    }
}
