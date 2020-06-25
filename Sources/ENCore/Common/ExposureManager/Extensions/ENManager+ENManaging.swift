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

    func getExposureInfo(summary: ENExposureDetectionSummary,
                         userExplanation: String,
                         completionHandler: @escaping ENGetExposureInfoHandler) -> Progress
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
    // only available on Xcode 11.5+
//    override var attenuationDurationThresholds: [NSNumber] {
//        return exposureConfiguration.attenuationDurationThresholds.map { NSNumber(value: $0) }
//    }

    init(exposureConfiguration: ExposureConfiguration) {
        self.exposureConfiguration = exposureConfiguration

        super.init()

        self.minimumRiskScore = exposureConfiguration.minimumRiskScope
        self.attenuationLevelValues = exposureConfiguration.attenuationLevelValues.map { NSNumber(value: $0) }
        self.daysSinceLastExposureLevelValues = exposureConfiguration.daysSinceLastExposureLevelValues.map { NSNumber(value: $0) }
        self.durationLevelValues = exposureConfiguration.durationLevelValues.map { NSNumber(value: $0) }
        self.transmissionRiskLevelValues = exposureConfiguration.transmissionRiskLevelValues.map { NSNumber(value: $0) }
    }

    // MARK: - Private

    private let exposureConfiguration: ExposureConfiguration
}
