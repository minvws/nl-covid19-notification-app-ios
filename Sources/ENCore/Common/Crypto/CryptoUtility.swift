/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import CommonCrypto
import CryptoKit
import Foundation
import Security

/// @mockable
protocol CryptoUtility {
    func validate(data: Data, signature: Data) -> Bool
    func signature(forData data: Data, key: Data) -> Data
}

/// Crypto Utility for validating and generating signatures
/// This is all work in progress as there are currently no
/// test samples available to validate the implementation
///
// TODO: Validate and adjust implementation once examples are available
///
final class CryptoUtilityImpl: CryptoUtility {

    init(validationKey: Key) {
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

    func signature(forData data: Data, key: Data) -> Data {
        let key = SymmetricKey(data: key)

        let signature = HMAC<SHA256>.authenticationCode(for: data, using: key)

        return Data(signature)
    }

    // MARK: - Private

    private let validationKey: Key
}
