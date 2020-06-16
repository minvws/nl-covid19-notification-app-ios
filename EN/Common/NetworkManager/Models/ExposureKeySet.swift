/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation
import ZIPFoundation

enum ExposureKeySetError: Error {
    case cannotOpenFile
    case noSignatureFile
    case noKeyFile
    case incorrectData
}

struct ExposureKeySet {
    
    static let EXPORT_BINARY = "export.bin"
    static let EXPORT_SIGNATURE = "export.sig"
    
    var keys:Data
    var signature:Data
    
    init(url:URL) throws {
        
        guard let archive = Archive(url: url, accessMode: .read) else  {
            throw ExposureKeySetError.cannotOpenFile
        }
        
        guard let signature = archive[ExposureKeySet.EXPORT_SIGNATURE] else {
            throw ExposureKeySetError.noSignatureFile
        }
        
        guard let keys = archive[ExposureKeySet.EXPORT_BINARY] else {
            throw ExposureKeySetError.noKeyFile
        }
        
        var localKeys:Data?
        let _ = try? archive.extract(signature, consumer: { data in
            localKeys = data
        })
        
        var localSignature:Data?
        let _ = try? archive.extract(keys, consumer: { data in
            localSignature = data
        })
        
        guard let sigData = localSignature, let keyData = localKeys else {
            throw ExposureKeySetError.incorrectData
        }
        
        self.keys = keyData
        self.signature = sigData
        
    }
}
