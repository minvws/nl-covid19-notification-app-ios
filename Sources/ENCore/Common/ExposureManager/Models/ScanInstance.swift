/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol ScanInstance {
    var minimumAttenuation: UInt8 { get }
    var typicalAttenuation: UInt8 { get }
    var secondsSinceLastScan: Int { get }
}
