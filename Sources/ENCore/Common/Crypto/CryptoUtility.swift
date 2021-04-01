/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import CommonCrypto
import Foundation
import Security

/// @mockable
protocol CryptoUtility {
    func validate(data: Data, signature: Data, completion: @escaping (Bool) -> ())
    func signature(forData data: Data, key: Data) -> Data
    func sha256(data: Data) -> String?
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

        var digest = [CUnsignedChar](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        key.withUnsafeBytes { keyPtr in
            data.withUnsafeBytes { dataPtr in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyPtr.baseAddress, key.count, dataPtr.baseAddress, data.count, &digest)
            }
        }

        return Data(digest)
    }

    func sha256(data: Data) -> String? {
        let digest = data.sha256
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return "SHA256 digest: \(hexBytes.joined())"
    }

    // MARK: - Private

    private let signatureValidator: SignatureValidating
}

extension Data {
    var sha256: Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(self.count), &digest)
        }
        return Data(digest)
    }
    
    var sha256String: String {
        let digest = self.sha256
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return "\(hexBytes.joined())"
    }
}
