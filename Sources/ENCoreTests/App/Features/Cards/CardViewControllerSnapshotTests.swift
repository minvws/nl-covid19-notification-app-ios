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

final class CardViewControllerSnapshotTests: TestCase {
    private var viewController: CardViewController!
    private var mockCardListener: CardListeningMock!
    private var mockExposureDataController: ExposureDataControllingMock!
    private var mockPauseController: PauseControllingMock!

    override func setUp() {
        super.setUp()

        mockCardListener = CardListeningMock()
        mockExposureDataController = ExposureDataControllingMock()
        mockPauseController = PauseControllingMock()

        recordSnapshots = false
    }

    func test_cardViewController_bluetoothOff() {
        viewController = CardViewController(listener: mockCardListener,
                                            theme: theme,
                                            types: [.bluetoothOff],
                                            dataController: mockExposureDataController,
                                            pauseController: mockPauseController)

        snapshots(matching: viewController)
    }

    func test_cardViewController_bluetoothOffAndInteropAnnouncement() {
        viewController = CardViewController(listener: mockCardListener,
                                            theme: theme,
                                            types: [.bluetoothOff, .interopAnnouncement],
                                            dataController: mockExposureDataController,
                                            pauseController: mockPauseController)

        snapshots(matching: viewController)
    }

    func test_cardViewController_exposureOff() {
        viewController = CardViewController(listener: mockCardListener,
                                            theme: theme,
                                            types: [.exposureOff],
                                            dataController: mockExposureDataController,
                                            pauseController: mockPauseController)

        snapshots(matching: viewController)
    }

    func test_cardViewController_noLocalNotifications() {
        viewController = CardViewController(listener: mockCardListener,
                                            theme: theme,
                                            types: [.noLocalNotifications],
                                            dataController: mockExposureDataController,
                                            pauseController: mockPauseController)
        snapshots(matching: viewController)
    }

    func test_cardViewController_noInternet() {
        viewController = CardViewController(listener: mockCardListener,
                                            theme: theme,
                                            types: [.noInternet(retryHandler: {})],
                                            dataController: mockExposureDataController,
                                            pauseController: mockPauseController)

        snapshots(matching: viewController)
    }
}
