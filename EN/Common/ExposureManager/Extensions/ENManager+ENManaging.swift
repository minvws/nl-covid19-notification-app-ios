/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

#if canImport(ExposureNotification)
    import ExposureNotification

    /// ENManaging interface to mock ENManager
    /// @mockable
    @available(iOS 13.5, *)
    protocol ENManaging {
        func activate(completionHandler: @escaping ENErrorHandler)
        func invalidate()

        func detectExposures(configuration: ENExposureConfiguration,
                             diagnosisKeyURLs: [URL],
                             completionHandler: @escaping ENDetectExposuresHandler) -> Progress

        func getDiagnosisKeys(completionHandler: @escaping ENGetDiagnosisKeysHandler)

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

    @available(iOS 13.5, *)
    extension ENManager: ENManaging {}

#endif
