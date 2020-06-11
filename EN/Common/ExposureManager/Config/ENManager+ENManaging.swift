/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import ExposureNotification

/// @mockable
@available(iOS 13.5, *)
protocol ENManaging {
    var dispatchQueue: DispatchQueue { get set }
    var exposureNotificationStatus: ENStatus { get }
    var invalidationHandler: (() -> Void)? { get set }
    func activate(completionHandler: @escaping ENErrorHandler)
    func invalidate()
    static var authorizationStatus: ENAuthorizationStatus { get }
    var exposureNotificationEnabled: Bool { get }
    func setExposureNotificationEnabled(_ enabled: Bool, completionHandler: @escaping ENErrorHandler)
    func detectExposures(configuration: ENExposureConfiguration, diagnosisKeyURLs: [URL], completionHandler: @escaping ENDetectExposuresHandler) -> Progress
    func getExposureInfo(summary: ENExposureDetectionSummary, userExplanation: String, completionHandler: @escaping ENGetExposureInfoHandler) -> Progress
    func getDiagnosisKeys(completionHandler: @escaping ENGetDiagnosisKeysHandler)
    func getTestDiagnosisKeys(completionHandler: @escaping ENGetDiagnosisKeysHandler)
}

@available(iOS 13.5, *)
extension ENManager : ENManaging {}
