/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import RxSwift

/// @mockable
protocol NetworkResponseHandlerProvider {
    var readFromDiskResponseHandler: ReadFromDiskResponseHandlerProtocol { get }
    var unzipNetworkResponseHandler: UnzipNetworkResponseHandlerProtocol { get }
    var verifySignatureResponseHandler: VerifySignatureResponseHandlerProtocol { get }
}

/// @mockable
protocol NetworkResponseHandlerProviderBuildable {
    /// Builds Network response provider
    ///
    func build() -> NetworkResponseHandlerProvider
}

private final class NetworkResponseProviderDependencyProvider: DependencyProvider<EmptyDependency> {
    var cryptoUtility: CryptoUtility {
        return CryptoUtilityBuilder().build()
    }
}

final class NetworkResponseHandlerProviderBuilder: Builder<EmptyDependency>, NetworkResponseHandlerProviderBuildable {
    func build() -> NetworkResponseHandlerProvider {
        let dependencyProvider = NetworkResponseProviderDependencyProvider()

        return NetworkResponseHandlerProviderImpl(cryptoUtility: dependencyProvider.cryptoUtility)
    }
}
