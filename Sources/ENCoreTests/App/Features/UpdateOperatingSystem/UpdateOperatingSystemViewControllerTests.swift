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

final class UpdateOperatingSystemViewControllerTests: TestCase {

    private var viewController: UpdateOperatingSystemViewController!
    private var mockInterfaceOrientationStream: InterfaceOrientationStreamingMock!
    private var mockEnableSettingsBuilder: EnableSettingBuildableMock!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        mockInterfaceOrientationStream = InterfaceOrientationStreamingMock()
        mockInterfaceOrientationStream.isLandscape = BehaviorSubject(value: false)
        mockEnableSettingsBuilder = EnableSettingBuildableMock()

        recordSnapshots = false || forceRecordAllSnapshots

        viewController = UpdateOperatingSystemViewController(
            theme: theme,
            interfaceOrientationStream: mockInterfaceOrientationStream,
            enableSettingBuilder: mockEnableSettingsBuilder)
    }

    // MARK: - Tests

    func testSnapshotUpdateOperatingSystemViewController() {
        snapshots(matching: viewController)
    }

    func testSnapshotUpdateOperatingSystemViewControllerArabic() {
        LocalizationOverrides.overriddenLocalization = "ar"
        LocalizationOverrides.overriddenIsRTL = true
        LocalizationOverrides.overriddenCurrentLanguageIdentifier = "ar"

        snapshots(matching: viewController)

        LocalizationOverrides.overriddenLocalization = nil
        LocalizationOverrides.overriddenIsRTL = nil
        LocalizationOverrides.overriddenCurrentLanguageIdentifier = nil
    }
}
