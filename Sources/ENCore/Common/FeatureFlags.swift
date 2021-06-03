/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

/// @mockable
protocol FeatureFlagControlling {
    
    /// Determine wether feature flag is enabled for the given feature. Either via the remote appconfig or via a local override.
    func isFeatureFlagEnabled(feature: Feature) -> Bool
    
    /// Toggles the feature flag for the given feature based on its current enabled / disabled state.
    func toggleFeatureFlag(forFeature feature: Feature)
    
    /// Removes the local override setting for the featureflag of the given feature. After calling this the featureflag setting defaults back to the remote appconfig.
    func resetFeatureFlag(forFeature feature: Feature)
}

enum Feature: CaseIterable {
    case independentKeySharing
    
    var developerMenuDisplayName: String {
        switch self {
            case .independentKeySharing: return "Key sharing via coronatest.nl"
        }
    }
}

struct FeatureFlag {
    let feature: Feature
    let identifier: String
    let enabledByDefault: Bool
}

class FeatureFlagController: FeatureFlagControlling {
    
    private let flags = [
        FeatureFlag(feature: .independentKeySharing, identifier: "independentKeySharing", enabledByDefault: false)
    ]
    
    private let userDefaults: UserDefaultsProtocol
    private let exposureController: ExposureControlling
    
    init(
        userDefaults: UserDefaultsProtocol,
        exposureController: ExposureControlling
    ) {
        self.userDefaults = userDefaults
        self.exposureController = exposureController
    }
    
    func isFeatureFlagEnabled(feature: Feature) -> Bool {
        
        guard let flag = flag(forFeature: feature) else {
            return false
        }
        
        // Local feature flag settings override remote settings
        if let localOverride = userDefaults.object(forKey: flag.identifier) as? Bool {
            return localOverride
        }
        
        // Find remote feature flag for feature
        guard let remoteFeatureFlag = exposureController.getAppConfigFeatureFlags()?.first(where: { $0.id == flag.identifier }) else {
            return flag.enabledByDefault
        }
        
        return remoteFeatureFlag.featureEnabled
    }
    
    func toggleFeatureFlag(forFeature feature: Feature) {
        guard let flag = flag(forFeature: feature) else {
            return
        }
        
        userDefaults.set(!isFeatureFlagEnabled(feature: feature), forKey: flag.identifier)
    }
    
    func resetFeatureFlag(forFeature feature: Feature) {
        guard let flag = flag(forFeature: feature) else {
            return
        }
        userDefaults.removeObject(forKey: flag.identifier)
    }
    
    private func flag(forFeature feature: Feature) -> FeatureFlag? {
        flags.first(where: { $0.feature == feature })
    }
}
