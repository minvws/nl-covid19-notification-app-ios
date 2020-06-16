/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import CryptoKit
import Foundation
import Security

struct Key {
    let symmetricKey: SymmetricKey

    static var random: Key {
        let symmetricKey = SymmetricKey(size: .bits256)
        return Key(symmetricKey: symmetricKey)
    }
}

extension Key {
    var secKey: SecKey? {
        let bitCount = symmetricKey.bitCount

        return symmetricKey.withUnsafeBytes { (ptr) -> SecKey? in
            let data = Data(ptr)

            let attributes: [String: AnyObject] = [
                kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom as AnyObject,
                kSecAttrKeyClass as String: kSecAttrKeyClassSymmetric as AnyObject,
                kSecAttrKeySizeInBits as String: bitCount as AnyObject
            ]

            return SecKeyCreateWithData(data as CFData,
                                        attributes as CFDictionary,
                                        nil)
        }
    }
}
