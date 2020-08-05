/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ExposureNotification
import Foundation
import UIKit

enum ExposureManagerStatus: Equatable {
    /// Exposure Notification is active
    case active

    /// Exposure Notification is inactive
    case inactive(ExposureManagerError)

    /// No authorisation has been given yet
    case notAuthorized

    /// Authorisation has been explicitly denied
    case authorizationDenied
}

enum ExposureManagerError: Error {
    case unknown
    case disabled
    case bluetoothOff
    case restricted
    case notAuthorized
    case rateLimited
    case internalTypeMismatch // programmers error
}

/// @mockable
protocol ExposureManaging {

    var authorizationStatus: ENAuthorizationStatus { get }

    // MARK: - Activation

    /// Activates the ExposureManager - Should be the first call to execute. The framework
    /// might be usable until an active state is returned
    func activate(completion: @escaping (ExposureManagerStatus) -> ())

    /// Deactives the ExporeManager.
    func deactivate()

    /// Detects exposures from a given set of exposure key URLs.
    /// A summary is returned when a match is found. If no summary is returned
    /// no match has been found
    func detectExposures(configuration: ExposureConfiguration,
                         diagnosisKeyURLs: [URL],
                         completion: @escaping (Result<ExposureDetectionSummary?, ExposureManagerError>) -> ())

    /// Returns this device's diagnosis keys
    func getDiagnonisKeys(completion: @escaping (Result<[DiagnosisKey], ExposureManagerError>) -> ())

    /// Enabled exposure notifications. Successful when completion is
    /// called without an error
    func setExposureNotificationEnabled(_ enabled: Bool, completion: @escaping (Result<(), ExposureManagerError>) -> ())

    /// Returns whether exposure notifications are enabled
    func isExposureNotificationEnabled() -> Bool

    /// Returns the current framework status
    func getExposureNotificationStatus() -> ExposureManagerStatus

    func getExposureInfo(summary: ExposureDetectionSummary,
                         userExplanation: String,
                         completionHandler: @escaping ([ExposureInformation]?, ExposureManagerError?) -> ())
}

/// @mockable
protocol ExposureManagerBuildable {
    /// Builds an ExposureManager instance.
    /// Returns nil if the OS does not support Exposure Notifications
    func build() -> ExposureManaging
}

final class ExposureManagerBuilder: Builder<EmptyDependency>, ExposureManagerBuildable {

    func build() -> ExposureManaging {
        #if targetEnvironment(simulator)
            return StubExposureManager()
        #else
            return ExposureManager(manager: ENManager())
        #endif
    }
}
