/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

extension LabInformation {
    var asLabConfirmationKey: LabConfirmationKey? {
        guard
            let bucketIdentifier = Data(base64Encoded: bucketId),
            let confirmationKey = Data(base64Encoded: confirmationKey) else {
            return nil
        }

        return LabConfirmationKey(identifier: labConfirmationId,
                                  bucketIdentifier: bucketIdentifier,
                                  confirmationKey: confirmationKey,
                                  validUntil: Date(timeIntervalSinceNow: TimeInterval(validity)))
    }
}

extension DiagnosisKey {
    var asTemporaryKey: TemporaryKey {
        return TemporaryKey(keyData: keyData.base64EncodedString(),
                            rollingStartNumber: Int(rollingStartNumber),
                            rollingPeriod: Int(rollingPeriod))
    }
}

extension Manifest {
    var asApplicationManifest: ApplicationManifest {
        return ApplicationManifest(exposureKeySetsIdentifiers: exposureKeySets,
                                   resourceBundleIdentifier: resourceBundle,
                                   riskCalculationParametersIdentifier: riskCalculationParameters,
                                   appConfigurationIdentifier: appConfig,
                                   creationDate: Date())
    }
}

extension AppConfig {
    func asApplicationConfiguration(identifier: String) -> ApplicationConfiguration {
        return ApplicationConfiguration(version: version,
                                        manifestRefreshFrequency: manifestFrequency,
                                        decoyProbability: decoyProbability,
                                        creationDate: Date(),
                                        identifier: identifier)
    }
}

extension RiskCalculationParameters {
    func asExposureRiskConfiguration(identifier: String) -> ExposureRiskConfiguration {
        return ExposureRiskConfiguration(identifier: identifier,
                                         minimumRiskScope: minimumRiskScore,
                                         attenuationLevelValues: attenuationScores,
                                         daysSinceLastExposureLevelValues: daysSinceLastExposureScores,
                                         durationLevelValues: durationScores,
                                         transmissionRiskLevelValues: transmissionRiskScores,
                                         attenuationDurationThresholds: durationAtAttenuationThresholds)
    }
}
