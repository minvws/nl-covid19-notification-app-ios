/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

/// @mockable
protocol PrivacyAgreementListener: AnyObject {
    func privacyAgreementDidComplete()
    func privacyAgreementRequestsRedirect(to url: URL)
}

/// @mockable
protocol PrivacyAgreementBuildable {
    func build(withListener listener: PrivacyAgreementListener) -> ViewControllable
}

protocol PrivacyAgreementDependency {
    var theme: Theme { get }
}

final class PrivacyAgreementDependencyDependencyProvider: DependencyProvider<PrivacyAgreementDependency> {}

final class PrivacyAgreementBuilder: Builder<PrivacyAgreementDependency>, PrivacyAgreementBuildable {
    func build(withListener listener: PrivacyAgreementListener) -> ViewControllable {
        let dependencyProvider = PrivacyAgreementDependencyDependencyProvider(dependency: dependency)

        return PrivacyAgreementViewController(listener: listener, theme: dependencyProvider.dependency.theme)
    }
}
