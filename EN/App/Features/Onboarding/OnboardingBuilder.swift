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
    func build(withListener listener: OnboardingListener) -> Routing
}

///
/// - Tag: OnboardingDependencyProvider
private final class OnboardingDependencyProvider: DependencyProvider<EmptyDependency>, OnboardingStepDependency, OnboardingConsentDependency {
    
    // MARK: - OnboardingStepDependency

    lazy var onboardingManager: OnboardingManaging = OnboardingManager()
    
    // MARK: - OnboardingConsentDependency
    
    lazy var onboardingConcentManager: OnboardingConsentManaging = OnboardingConsentManager()

    // MARK: - Child Builders

    var stepBuilder: OnboardingStepBuildable {
        return OnboardingStepBuilder(dependency: self)
    }

    var consentBuilder: OnboardingConsentBuildable {
        return OnboardingConsentBuilder(dependency: self)
    }

    var webBuilder: WebBuildable {
        return WebBuilder()
    }

    var helpBuilder: OnboardingHelpBuildable {
        return OnboardingHelpBuilder()
    }

    var shareSheetBuilder: ShareSheetBuildable {
        return ShareSheetBuilder()
    }
}

final class OnboardingBuilder: Builder<EmptyDependency>, OnboardingBuildable {
    func build(withListener listener: OnboardingListener) -> Routing {
        let dependencyProvider = OnboardingDependencyProvider(dependency: dependency)
        let viewController = OnboardingViewController(listener: listener)

        return OnboardingRouter(viewController: viewController,
                                stepBuilder: dependencyProvider.stepBuilder,
                                consentBuilder: dependencyProvider.consentBuilder,
                                helpBuilder: dependencyProvider.helpBuilder,
                                webBuilder: dependencyProvider.webBuilder,
                                shareSheetBuilder: dependencyProvider.shareSheetBuilder)
    }
}
