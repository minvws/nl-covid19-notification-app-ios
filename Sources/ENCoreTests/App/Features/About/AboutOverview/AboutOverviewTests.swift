/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

@testable import ENCore
import Foundation
import SnapshotTesting
import XCTest

final class AboutOverviewViewControllerTests: TestCase {

    private var mockListener: AboutOverviewListenerMock!
    private var mockFeatureFlagController: FeatureFlagControllingMock!
        
    // MARK: - Setup

    override func setUp() {
        super.setUp()
        
        mockListener = AboutOverviewListenerMock()
        mockFeatureFlagController = FeatureFlagControllingMock()

        recordSnapshots = false
    }

    // MARK: - Tests

    func test_snapshot_aboutOverviewViewController_renderCorrectly() {
        mockFeatureFlagController.isFeatureFlagEnabledHandler = { feature in
            switch feature {
            case .independentKeySharing:
                return false
            }
        }
        
        let aboutManager = AboutManager(featureFlagController: mockFeatureFlagController)
        let viewController = AboutOverviewViewController(listener: mockListener,
                                                         aboutManager: aboutManager,
                                                         theme: theme)
        snapshots(matching: viewController)
    }
}
