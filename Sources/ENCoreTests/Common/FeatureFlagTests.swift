/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import XCTest

class FeatureFlagTests: TestCase {

    private var sut: FeatureFlagController!
    private var mockUserDefaults: UserDefaultsProtocolMock!
    private var mockExposureController: ExposureControllingMock!
    private var mockEnvironmentController: EnvironmentControllingMock!

    override func setUpWithError() throws {
        mockUserDefaults = UserDefaultsProtocolMock()
        mockExposureController = ExposureControllingMock()
        mockEnvironmentController = EnvironmentControllingMock()

        mockEnvironmentController.isDebugVersion = false
        mockEnvironmentController.appSupportsDeveloperMenu = false

        sut = FeatureFlagController(userDefaults: mockUserDefaults,
                                    exposureController: mockExposureController,
                                    environmentController: mockEnvironmentController)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_isFeatureFlagEnabled_byDefault() {
        // Arrange
        mockExposureController.getStoredAppConfigFeatureFlagsHandler = { nil }

        // Act
        let result = sut.isFeatureFlagEnabled(feature: .independentKeySharing)

        // Assert
        XCTAssertTrue(result)
        XCTAssertEqual(mockExposureController.getStoredAppConfigFeatureFlagsCallCount, 1)
    }

    func test_isFeatureFlagEnabled_viaAppConfig_enabled() {
        // Arrange
        mockExposureController.getStoredAppConfigFeatureFlagsHandler = {
            [
                .init(id: "independentKeySharing", featureEnabled: true)
            ]
        }

        // Act
        let result = sut.isFeatureFlagEnabled(feature: .independentKeySharing)

        // Assert
        XCTAssertTrue(result)
        XCTAssertEqual(mockExposureController.getStoredAppConfigFeatureFlagsCallCount, 1)
    }

    func test_isFeatureFlagEnabled_viaAppConfig_disabled() {
        // Arrange
        mockExposureController.getStoredAppConfigFeatureFlagsHandler = {
            [
                .init(id: "independentKeySharing", featureEnabled: false)
            ]
        }

        // Act
        let result = sut.isFeatureFlagEnabled(feature: .independentKeySharing)

        // Assert
        XCTAssertFalse(result)
        XCTAssertEqual(mockExposureController.getStoredAppConfigFeatureFlagsCallCount, 1)
    }
}
