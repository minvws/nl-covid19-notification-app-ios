/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
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

    /// Feature that is enabled / disabled by this flag
    let feature: Feature

    /// Identifier for this featureflag. This should match with the identifier that returned in the remote feature flag settings coming from the AppConfig file in the API
    let identifier: String

    /// Determines if this feature is enabled by default
    let enabledByDefault: Bool

    /// Determines if this feature should be available in non-debug / tests builds (in other words: wether the feature is ready for release to the general public)
    let releasable: Bool
}

class FeatureFlagController: FeatureFlagControlling, Logging {

    private let flags = [
        FeatureFlag(feature: .independentKeySharing, identifier: "independentKeySharing", enabledByDefault: true, releasable: true)
    ]

    private let userDefaults: UserDefaultsProtocol
    private let exposureController: ExposureControlling
    private let environmentController: EnvironmentControlling

    init(
        userDefaults: UserDefaultsProtocol,
        exposureController: ExposureControlling,
        environmentController: EnvironmentControlling
    ) {
        self.userDefaults = userDefaults
        self.exposureController = exposureController
        self.environmentController = environmentController
    }

    func isFeatureFlagEnabled(feature: Feature) -> Bool {

        guard let flag = flag(forFeature: feature) else {
            return false
        }

        logDebug("FeatureFlags: Checking status of feature: \(flag.identifier)")

        // Should this feature even be available in a release build?
        guard environmentController.isDebugVersion || flag.releasable else {
            logDebug("FeatureFlags: Feature \(flag.identifier) is not releasable and this is not a debug version of the app")
            return false
        }

        // Local feature flag settings override remote settings in debug builds
        if environmentController.isDebugVersion || environmentController.appSupportsDeveloperMenu {
            if let localOverride = userDefaults.object(forKey: flag.identifier) as? Bool {
                logDebug("FeatureFlags: Feature Flag \(flag.identifier) is overriden locally. value: \(localOverride)")
                return localOverride
            }
        }

        // Find remote feature flag for feature
        guard let remoteFeatureFlag = exposureController.getStoredAppConfigFeatureFlags()?.first(where: { $0.id == flag.identifier }) else {
            logDebug("FeatureFlags: Feature Flag \(flag.identifier) cannot be found in app config. using enabledByDefault value: \(flag.enabledByDefault)")
            return flag.enabledByDefault
        }

        logDebug("FeatureFlags: Remote Feature Flag \(flag.identifier) status: \(remoteFeatureFlag.featureEnabled)")

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
