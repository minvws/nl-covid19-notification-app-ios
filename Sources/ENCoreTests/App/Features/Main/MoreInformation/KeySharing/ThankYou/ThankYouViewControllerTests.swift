/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import ENFoundation
import Foundation
import RxSwift
import SnapshotTesting
import XCTest

final class ThankYouViewControllerTests: TestCase {
    private var sut: ThankYouViewController!

    private var mockListener: ThankYouListenerMock!
    private var mockInterfaceOrientationStream: InterfaceOrientationStreamingMock!
    private var mockFeatureFlagController: FeatureFlagControllingMock!
    private var labConfirmationKey: LabConfirmationKey!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        recordSnapshots = false || forceRecordAllSnapshots

        mockListener = ThankYouListenerMock()
        mockInterfaceOrientationStream = InterfaceOrientationStreamingMock()
        mockFeatureFlagController = FeatureFlagControllingMock()

        mockInterfaceOrientationStream.isLandscape = BehaviorSubject(value: false)

        labConfirmationKey = LabConfirmationKey(identifier: "ABCDEFG".asGGDkey,
                                                bucketIdentifier: Data(),
                                                confirmationKey: Data(),
                                                validUntil: currentDate())
    }

    // MARK: - Tests

    func test_thankYou_snapshotStateLoading() {

        mockFeatureFlagController.isFeatureFlagEnabledHandler = { feature in
            return feature != .independentKeySharing
        }

        sut = ThankYouViewController(listener: mockListener,
                                     theme: theme,
                                     exposureConfirmationKey: labConfirmationKey,
                                     interfaceOrientationStream: mockInterfaceOrientationStream,
                                     featureFlagController: mockFeatureFlagController)

        snapshots(matching: sut)
    }

    func test_thankYou_snapshotStateLoading_withIndependentKeySharing() {

        mockFeatureFlagController.isFeatureFlagEnabledHandler = { feature in
            return feature == .independentKeySharing
        }

        sut = ThankYouViewController(listener: mockListener,
                                     theme: theme,
                                     exposureConfirmationKey: labConfirmationKey,
                                     interfaceOrientationStream: mockInterfaceOrientationStream,
                                     featureFlagController: mockFeatureFlagController)

        snapshots(matching: sut)
    }

    func test_thankYou_snapshot_arabic() {

        LocalizationOverrides.overriddenLocalization = "ar"
        LocalizationOverrides.overriddenIsRTL = true
        LocalizationOverrides.overriddenCurrentLanguageIdentifier = "ar"

        mockFeatureFlagController.isFeatureFlagEnabledHandler = { feature in
            return feature != .independentKeySharing
        }

        sut = ThankYouViewController(listener: mockListener,
                                     theme: theme,
                                     exposureConfirmationKey: labConfirmationKey,
                                     interfaceOrientationStream: mockInterfaceOrientationStream,
                                     featureFlagController: mockFeatureFlagController)

        snapshots(matching: sut)

        LocalizationOverrides.overriddenLocalization = nil
        LocalizationOverrides.overriddenIsRTL = nil
        LocalizationOverrides.overriddenCurrentLanguageIdentifier = nil
    }
}
