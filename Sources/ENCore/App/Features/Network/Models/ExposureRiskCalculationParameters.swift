/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

#if canImport(ExposureNotification)
    import ExposureNotification
#endif

import Foundation

protocol ExposureRiskCalculationParameters {
    @available(iOS 13.5, *)
    var asExposureConfiguration: ENExposureConfiguration { get }
}
