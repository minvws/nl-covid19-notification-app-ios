/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

enum NetworkResponseHandleError: Error {
    case cannotUnzip
    case invalidSignature
    case cannotDeserialize
}

enum HTTPHeaderKey: String {
    case contentType = "Content-Type"
    case acceptedContentType = "Accept"
}

enum HTTPContentType: String {
    case all = "*/*"
    case zip = "application/zip"
    case json = "application/json"
}

final class NetworkResponseHandlerProviderImpl: NetworkResponseHandlerProvider {

    init(cryptoUtility: CryptoUtility) {
        self.cryptoUtility = cryptoUtility
    }

    // MARK: - NetworkResponseHandlerProvider

    var readFromDiskResponseHandler: ReadFromDiskResponseHandler {
        return ReadFromDiskResponseHandler()
    }

    var unzipNetworkResponseHandler: UnzipNetworkResponseHandler {
        return UnzipNetworkResponseHandler()
    }

    var verifySignatureResponseHandler: VerifySignatureResponseHandler {
        return VerifySignatureResponseHandler(cryptoUtility: cryptoUtility)
    }

    // MARK: - Private

    private let cryptoUtility: CryptoUtility
}
