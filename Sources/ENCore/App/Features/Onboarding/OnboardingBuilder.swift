/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol OnboardingListener: AnyObject {
    func didCompleteOnboarding()
}

/// @mockable
protocol OnboardingBuildable {
    func build(withListener listener: OnboardingListener) -> Routing
}

protocol OnboardingDependency {
    var theme: Theme { get }
    var exposureController: ExposureControlling { get }
    var exposureStateStream: ExposureStateStreaming { get }
}

///
/// - Tag: OnboardingDependencyProvider
private final class OnboardingDependencyProvider: DependencyProvider<OnboardingDependency>, OnboardingStepDependency, OnboardingConsentDependency, ShareSheetDependency, HelpDependency {

    // MARK: - OnboardingStepDependency

    lazy var onboardingManager: OnboardingManaging = {
        OnboardingManager(theme: self.theme)
    }()

    // MARK: - OnboardingConsentDependency

    lazy var onboardingConsentManager: OnboardingConsentManaging = {
        return OnboardingConsentManager(exposureStateStream: dependency.exposureStateStream,
                                        exposureController: dependency.exposureController,
                                        theme: self.theme)
    }()

    var exposureController: ExposureControlling {
        return dependency.exposureController
    }

    var theme: Theme {
        return dependency.theme
    }

    // MARK: - Child Builders

    var stepBuilder: OnboardingStepBuildable {
        return OnboardingStepBuilder(dependency: self)
    }

    var consentBuilder: OnboardingConsentBuildable {
        return OnboardingConsentBuilder(dependency: self)
    }

    var shareSheetBuilder: ShareSheetBuildable {
        return ShareSheetBuilder(dependency: self)
    }

    var helpBuilder: HelpBuildable {
        return HelpBuilder(dependency: self)
    }
}

final class OnboardingBuilder: Builder<OnboardingDependency>, OnboardingBuildable {
    func build(withListener listener: OnboardingListener) -> Routing {
        let dependencyProvider = OnboardingDependencyProvider(dependency: dependency)
        let viewController = OnboardingViewController(onboardingConsentManager: dependencyProvider.onboardingConsentManager,
                                                      listener: listener,
                                                      theme: dependencyProvider.dependency.theme)

        return OnboardingRouter(viewController: viewController,
                                stepBuilder: dependencyProvider.stepBuilder,
                                consentBuilder: dependencyProvider.consentBuilder,
                                shareSheetBuilder: dependencyProvider.shareSheetBuilder,
                                helpBuilder: dependencyProvider.helpBuilder)
    }
}
