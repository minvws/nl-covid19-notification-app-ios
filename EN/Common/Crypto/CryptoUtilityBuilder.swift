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
    var validationKey: Key {
        Key.random
    }

    var signingKey: Key {
        Key.random
    }
}

final class CryptoUtilityBuilder: CryptoUtilityBuildable {
    func build() -> CryptoUtility {
        let dependencyProvider = CryptoUtilityDependencyProvider()

        return CryptoUtilityImpl(signingKey: dependencyProvider.signingKey,
                                 validationKey: dependencyProvider.validationKey)
    }
}
