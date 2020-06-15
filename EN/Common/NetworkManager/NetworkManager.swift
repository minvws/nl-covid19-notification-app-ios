/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

final class NetworkManager: NetworkManaging {
    
    let session:URLSession
    
    init(urlSession: URLSession = URLSession.shared) {
        self.session = urlSession
    }

}
