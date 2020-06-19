/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

struct AnyCodingKey : CodingKey {
    
    var stringValue: String
    var intValue: Int?
    
    init(_ base: CodingKey) {
        self.init(stringValue: base.stringValue, intValue: base.intValue)
    }
    
    init(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
    
    init(stringValue: String, intValue: Int?) {
        self.stringValue = stringValue
        self.intValue = intValue
    }
}


extension JSONDecoder.KeyDecodingStrategy {
    
    static var convertFromUpperCamelCase: JSONDecoder.KeyDecodingStrategy {
        return .custom { codingKeys in
            
            var key = AnyCodingKey(codingKeys.last!)
            
            if let firstChar = key.stringValue.first {
                let i = key.stringValue.startIndex
                key.stringValue.replaceSubrange(
                    i ... i, with: String(firstChar).lowercased()
                )
            }
            return key
        }
    }
}
