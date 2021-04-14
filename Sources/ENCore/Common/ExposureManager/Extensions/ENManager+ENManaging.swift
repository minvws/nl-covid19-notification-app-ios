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

    func getExposureWindows(summary: ENExposureDetectionSummary, completionHandler: @escaping ENGetExposureWindowsHandler) -> Progress

    func getDiagnosisKeys(completionHandler: @escaping ENGetDiagnosisKeysHandler)
    func getTestDiagnosisKeys(completionHandler: @escaping ENGetDiagnosisKeysHandler)

    func setExposureNotificationEnabled(_ enabled: Bool,
                                        completionHandler: @escaping ENErrorHandler)

    func setLaunchActivityHandler(activityHandler: @escaping ENActivityHandler)

    var exposureNotificationEnabled: Bool { get }

    var exposureNotificationStatus: ENStatus { get }
    var invalidationHandler: (() -> ())? { get set }

    static var authorizationStatus: ENAuthorizationStatus { get }
}

extension ENManager: ENManaging {}

extension ENExposureDetectionSummary: ExposureDetectionSummary {}
extension ENExposureInfo: ExposureInformation {}
extension ENScanInstance: ScanInstance {}
extension ENExposureWindow: ExposureWindow {
    var scans: [ScanInstance] { scanInstances }
}

extension ExposureConfiguration {
    var asExposureConfiguration: ENExposureConfiguration {
        return DefaultExposureConfiguration(exposureConfiguration: self)
    }
}

private class DefaultExposureConfiguration: ENExposureConfiguration {
    init(exposureConfiguration: ExposureConfiguration) {
        self.exposureConfiguration = exposureConfiguration

        super.init()

        minimumRiskScoreFullRange = exposureConfiguration.minimumRiskScore

        immediateDurationWeight = exposureConfiguration.attenuationBucketWeights[0]
        nearDurationWeight = exposureConfiguration.attenuationBucketWeights[1]
        mediumDurationWeight = exposureConfiguration.attenuationBucketWeights[2]
        otherDurationWeight = exposureConfiguration.attenuationBucketWeights[3]

        var infectiousnessMap = [NSNumber: NSNumber]()

        exposureConfiguration.daysSinceOnsetToInfectiousness.forEach { item in
            infectiousnessMap[NSNumber(integerLiteral: item.daysSinceOnsetOfSymptoms)] = NSNumber(integerLiteral: item.infectiousness)
        }

        if #available(iOS 14.0, *) {
            infectiousnessMap[NSNumber(value: ENDaysSinceOnsetOfSymptomsUnknown)] = NSNumber(value: exposureConfiguration.infectiousnessWhenDaysSinceOnsetMissing)
        } else {
            // ENDaysSinceOnsetOfSymptomsUnknown is not available
            // in earlier versions of iOS; use an equivalent value
            infectiousnessMap[NSNumber(value: NSIntegerMax)] = NSNumber(value: exposureConfiguration.infectiousnessWhenDaysSinceOnsetMissing)
        }

        infectiousnessForDaysSinceOnsetOfSymptoms = infectiousnessMap

        infectiousnessStandardWeight = exposureConfiguration.infectiousnessWeights[1]
        infectiousnessHighWeight = exposureConfiguration.infectiousnessWeights[2]

        reportTypeConfirmedTestWeight = exposureConfiguration.reportTypeWeights[1]
        reportTypeConfirmedClinicalDiagnosisWeight = exposureConfiguration.reportTypeWeights[2]
        reportTypeSelfReportedWeight = exposureConfiguration.reportTypeWeights[3]
        reportTypeRecursiveWeight = exposureConfiguration.reportTypeWeights[4]
        reportTypeNoneMap = ENDiagnosisReportType(rawValue: exposureConfiguration.reportTypeWhenMissing) ?? .unknown

        attenuationDurationThresholds = exposureConfiguration.attenuationBucketThresholdDb.compactMap {
            let dbInt = Int($0)
            return NSNumber(integerLiteral: dbInt)
        }

        daysSinceLastExposureThreshold = Int(exposureConfiguration.daysSinceExposureThreshold)
    }

    // MARK: - Private

    private let exposureConfiguration: ExposureConfiguration
}
