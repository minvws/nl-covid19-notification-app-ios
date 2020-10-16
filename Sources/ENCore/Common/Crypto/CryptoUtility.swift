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
    func validate(data: Data, signature: Data, completion: @escaping (Bool) -> ())
    func signature(forData data: Data, key: Data) -> Data
}

/// Crypto Utility for validating and generating signatures
/// This is all work in progress as there are currently no
/// test samples available to validate the implementation
///
final class CryptoUtilityImpl: CryptoUtility {

    init(signatureValidator: SignatureValidating) {
        self.signatureValidator = signatureValidator
    }

    // MARK: - CryptoUtility

    func validate(data: Data, signature: Data, completion: @escaping (Bool) -> ()) {
        DispatchQueue.global().async {
            let result = self.signatureValidator.validate(signature: signature, content: data, validateRootCertificate: true)

            DispatchQueue.main.async {
                completion(result == SignatureValidationResult.SIGNATUREVALIDATIONRESULT_SUCCESS)
            }
        }
    }

    func signature(forData data: Data, key: Data) -> Data {
        let key = SymmetricKey(data: key)

        let signature = HMAC<SHA256>.authenticationCode(for: data, using: key)

        return Data(signature)
    }

    // MARK: - Private

    private let signatureValidator: SignatureValidating
}
