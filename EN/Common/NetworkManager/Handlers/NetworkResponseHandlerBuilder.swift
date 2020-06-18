/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// mockable
protocol NetworkResponseProviderHandling {
    func handleReturnData(url: URL?, response: URLResponse?, error: Error?) throws -> Data
    func handleReturnUrls(url: URL?, response: URLResponse?, error: Error?) throws -> [URL]
}

/// @mockable
protocol NetworkResponseProviderBuildable {
    /// Builds Network response provider
    ///
    func build() -> NetworkResponseProviderHandling
}

final class NetworkResponseProviderBuilder: Builder<EmptyDependency>, NetworkResponseProviderBuildable {
    func build() -> NetworkResponseProviderHandling {
        return NetworkResponseProvider()
    }
}
