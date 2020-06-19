/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension StorageControlling {
    func getManifest() -> Manifest? {
        return retrieveObject(identifiedBy: Manifest.key, ofType: Manifest.self)
    }

    func store(manifest: Manifest) {
        store(object: manifest, identifiedBy: Manifest.key, completion: { error in })
    }
}
