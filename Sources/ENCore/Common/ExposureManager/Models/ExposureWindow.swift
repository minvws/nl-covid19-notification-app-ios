/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ExposureNotification
import Foundation

/// @mockable
protocol ExposureWindow {

    /// Transmitting device's calibration confidence.
    var calibrationConfidence: ENCalibrationConfidence { get }

    /// Day the exposure occurred.
    var date: Date { get }

    /// How positive diagnosis was reported for this the TEK observed for this window.
    var diagnosisReportType: ENDiagnosisReportType { get }

    /// How infectious based on days since onset of symptoms.
    var infectiousness: ENInfectiousness { get }

    /// Each scan instance corresponds to a scan (of a few seconds) when a beacon with a TEK causing this exposure was observed.
    var scanInstances: [ENScanInstance] { get }
}
