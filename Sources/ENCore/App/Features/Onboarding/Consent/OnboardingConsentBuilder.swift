/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol OnboardingConsentBuildable {
    /// Builds OnboardingConsent
    ///
    /// - Parameter listener: Listener of created OnboardingConsentViewController
    func build(withListener listener: OnboardingConsentListener) -> ViewControllable
    func build(withListener listener: OnboardingConsentListener, initialIndex: Int) -> ViewControllable
}

/// @mockable
protocol OnboardingConsentListener: AnyObject {
    func consentClose()
    func consentRequest(step: OnboardingConsentStep.Index)
    func displayHelp()
    func displayBluetoothSettings()
    func displayShareApp(completion: (() -> ())?)
}

protocol OnboardingConsentDependency {
    var theme: Theme { get }
    var onboardingConsentManager: OnboardingConsentManaging { get }
    var interfaceOrientationStream: InterfaceOrientationStreaming { get }
}

private final class OnboardingConsentDependencyProvider: DependencyProvider<OnboardingConsentDependency> {}

final class OnboardingConsentBuilder: Builder<OnboardingConsentDependency>, OnboardingConsentBuildable {
    func build(withListener listener: OnboardingConsentListener) -> ViewControllable {
        return build(withListener: listener, initialIndex: 0)
    }

    func build(withListener listener: OnboardingConsentListener, initialIndex index: Int = 0) -> ViewControllable {
        let dependencyProvider = OnboardingConsentDependencyProvider(dependency: dependency)
        let onboardingConsentManager = dependencyProvider.dependency.onboardingConsentManager

        return OnboardingConsentStepViewController(
            onboardingConsentManager: onboardingConsentManager,
            listener: listener,
            theme: dependencyProvider.dependency.theme,
            index: index,
            interfaceOrientationStream: dependencyProvider.dependency.interfaceOrientationStream)
    }
}
