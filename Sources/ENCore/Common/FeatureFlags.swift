/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol FeatureFlagControlling {
    func isFeatureFlagEnabled(feature: Feature) -> Bool
    func toggleFeatureFlag(forFeature feature: Feature)
}

enum Feature: String, CaseIterable {
    case backgroundKeysetDownloading
    
    var displayName: String {
        switch self {
        case .backgroundKeysetDownloading:
            return "Background Keyset Downloading"
        }
    }
    
    var defaultEnabled: Bool {
        switch self {
        case .backgroundKeysetDownloading:
            return false
        }
    }
}

class FeatureFlagController: FeatureFlagControlling {
    
    static let shared = FeatureFlagController()
    
    private init() {}
    
    func isFeatureFlagEnabled(feature: Feature) -> Bool {
        UserDefaults.standard.object(forKey: feature.rawValue) as? Bool ?? feature.defaultEnabled
    }
    
    func toggleFeatureFlag(forFeature feature: Feature) {
        UserDefaults.standard.set(!isFeatureFlagEnabled(feature: feature), forKey: feature.rawValue)
    }
}
