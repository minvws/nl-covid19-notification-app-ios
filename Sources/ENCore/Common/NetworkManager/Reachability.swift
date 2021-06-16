/*
 * Copyright (c) 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import ENFoundation
import Reachability

///@mockable
protocol ReachabilityProviding {
    func getReachability() -> ReachabilityProtocol?
}

final class ReachabilityProvider: ReachabilityProviding, Logging {
    func getReachability() -> ReachabilityProtocol? {
        var reachability: ReachabilityProtocol?
        
        do {
            reachability = try Reachability()
        } catch {
            logError("Unable to instantiate Reachability")
        }
        
        return reachability
    }
}


///@mockable
protocol ReachabilityProtocol {
    func setNetworkAvailabilityChangeHandler(handler: @escaping (_ networkAvailable: Bool) -> Void)
    func startNotifier() throws
    func stopNotifier()
}

extension Reachability: ReachabilityProtocol {
    func setNetworkAvailabilityChangeHandler(handler: @escaping (_ networkAvailable: Bool) -> Void) {
        whenReachable = { status in
            handler(status.connection != .unavailable)
        }
        whenUnreachable = { status in
            handler(!(status.connection == .unavailable))
        }
    }
}
