/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import CryptoKit
import Foundation
import Security

protocol CryptoUtility {
    func validate(data: Data, signature: Data) -> Bool
    func signature(for data: Data) -> Data
}

/// Crypto Utility for validating and generating signatures
/// This is all work in progress as there are currently no
/// test samples available to validate the implementation
///
// TODO: Validate and adjust implementation once examples are available
///
final class CryptoUtilityImpl: CryptoUtility {

    init(signingKey: Key, validationKey: Key) {
        self.signingKey = signingKey
        self.validationKey = validationKey
    }

    // MARK: - CryptoUtility

    func validate(data: Data, signature: Data) -> Bool {
        guard let key = validationKey.secKey else {
            return false
        }

        return SecKeyVerifySignature(key,
                                     SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256,
                                     data as CFData,
                                     signature as CFData,
                                     nil)
    }

    func signature(for data: Data) -> Data {
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: signingKey.symmetricKey)

        return Data(signature)
    }

    // MARK: - Private

    private let signingKey: Key
    private let validationKey: Key
}
