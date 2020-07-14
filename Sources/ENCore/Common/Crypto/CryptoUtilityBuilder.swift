/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

protocol CryptoUtilityBuildable {
    func build() -> CryptoUtility
}

private final class CryptoUtilityDependencyProvider: DependencyProvider<EmptyDependency> {
    var signatureValidator: SignatureValidating {
        return SignatureValidator()
    }
}

final class CryptoUtilityBuilder: CryptoUtilityBuildable {
    func build() -> CryptoUtility {
        let dependencyProvider = CryptoUtilityDependencyProvider()

        return CryptoUtilityImpl(signatureValidator: dependencyProvider.signatureValidator)
    }
}
