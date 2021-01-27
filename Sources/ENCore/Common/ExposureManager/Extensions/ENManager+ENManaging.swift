/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ExposureNotification

/// ENManaging interface to mock ENManager
/// @mockable
protocol ENManaging {
    func activate(completionHandler: @escaping ENErrorHandler)
    func invalidate()

    func detectExposures(configuration: ENExposureConfiguration,
                         diagnosisKeyURLs: [URL],
                         completionHandler: @escaping ENDetectExposuresHandler) -> Progress

    func getDiagnosisKeys(completionHandler: @escaping ENGetDiagnosisKeysHandler)
    func getTestDiagnosisKeys(completionHandler: @escaping ENGetDiagnosisKeysHandler)

    func setExposureNotificationEnabled(_ enabled: Bool,
                                        completionHandler: @escaping ENErrorHandler)
    var exposureNotificationEnabled: Bool { get }

    var exposureNotificationStatus: ENStatus { get }
    var invalidationHandler: (() -> ())? { get set }

    static var authorizationStatus: ENAuthorizationStatus { get }
}

extension ENManager: ENManaging {}

extension ENExposureDetectionSummary: ExposureDetectionSummary {}
extension ENExposureInfo: ExposureInformation {}

extension ExposureConfiguration {
    var asExposureConfiguration: ENExposureConfiguration {
        return DefaultExposureConfiguration(exposureConfiguration: self)
    }
}

private class DefaultExposureConfiguration: ENExposureConfiguration {
    init(exposureConfiguration: ExposureConfiguration) {
        self.exposureConfiguration = exposureConfiguration

        super.init()

        self.minimumRiskScore = exposureConfiguration.minimumRiskScope
        self.attenuationLevelValues = exposureConfiguration.attenuationLevelValues as [NSNumber]
        self.daysSinceLastExposureLevelValues = exposureConfiguration.daysSinceLastExposureLevelValues as [NSNumber]
        self.durationLevelValues = exposureConfiguration.durationLevelValues as [NSNumber]
        self.transmissionRiskLevelValues = exposureConfiguration.transmissionRiskLevelValues as [NSNumber]
        self.metadata = ["attenuationDurationThresholds": exposureConfiguration.attenuationDurationThresholds]

        // Needed since EN API v2 version
        self.reportTypeNoneMap = .confirmedTest
        self.infectiousnessForDaysSinceOnsetOfSymptoms = [
            -14: NSNumber(value: ENInfectiousness.high.rawValue),
            -13: NSNumber(value: ENInfectiousness.high.rawValue),
            -12: NSNumber(value: ENInfectiousness.high.rawValue),
            -11: NSNumber(value: ENInfectiousness.high.rawValue),
            -10: NSNumber(value: ENInfectiousness.high.rawValue),
            -9: NSNumber(value: ENInfectiousness.high.rawValue),
            -8: NSNumber(value: ENInfectiousness.high.rawValue),
            -7: NSNumber(value: ENInfectiousness.high.rawValue),
            -6: NSNumber(value: ENInfectiousness.high.rawValue),
            -5: NSNumber(value: ENInfectiousness.high.rawValue),
            -4: NSNumber(value: ENInfectiousness.high.rawValue),
            -3: NSNumber(value: ENInfectiousness.high.rawValue),
            -2: NSNumber(value: ENInfectiousness.high.rawValue),
            -1: NSNumber(value: ENInfectiousness.high.rawValue),
            0: NSNumber(value: ENInfectiousness.high.rawValue),
            1: NSNumber(value: ENInfectiousness.high.rawValue),
            2: NSNumber(value: ENInfectiousness.high.rawValue),
            3: NSNumber(value: ENInfectiousness.high.rawValue),
            4: NSNumber(value: ENInfectiousness.high.rawValue),
            5: NSNumber(value: ENInfectiousness.high.rawValue),
            6: NSNumber(value: ENInfectiousness.high.rawValue),
            7: NSNumber(value: ENInfectiousness.high.rawValue),
            8: NSNumber(value: ENInfectiousness.high.rawValue),
            9: NSNumber(value: ENInfectiousness.high.rawValue),
            10: NSNumber(value: ENInfectiousness.high.rawValue),
            11: NSNumber(value: ENInfectiousness.high.rawValue),
            12: NSNumber(value: ENInfectiousness.high.rawValue),
            13: NSNumber(value: ENInfectiousness.high.rawValue),
            14: NSNumber(value: ENInfectiousness.high.rawValue)
        ]
    }

    // MARK: - Private

    private let exposureConfiguration: ExposureConfiguration
}
