/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation


/// @mockable
protocol NetworkManaging {
}
    
/// @mockable
protocol NetworkManagerBuildable {
    /// Builds an ExposureManager instance.
    /// Returns nil if the OS does not support Exposure Notifications
    func build() -> NetworkManaging
}

final class NetworkManagerBuilder: Builder<EmptyDependency>, NetworkManagerBuildable {
    func build() -> NetworkManaging {
        return NetworkManager()
    }
    
    
}
