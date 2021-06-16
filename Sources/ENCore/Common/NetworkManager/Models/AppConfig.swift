/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct AppConfig: Codable {
    let version, manifestFrequency: Int?
    let decoyProbability: Float?
    let appStoreURL: String?
    let iOSMinimumVersion: String?
    let iOSMinimumVersionMessage: String?
    let iOSAppStoreURL: String?
    let requestMinimumSize: Int?
    let requestMaximumSize: Int?
    let repeatedUploadDelay: Int?
    let coronaMelderDeactivated: String?
    let appointmentPhoneNumber: String?
    let featureFlags: [FeatureFlag]?
    let shareKeyURL: String?
    
    struct FeatureFlag: Codable {
        let id: String
        let featureEnabled: Bool
    }
}
