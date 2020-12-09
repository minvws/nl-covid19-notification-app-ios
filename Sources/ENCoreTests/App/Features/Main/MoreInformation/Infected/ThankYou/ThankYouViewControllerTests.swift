/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import ENCore
import Foundation
import SnapshotTesting
import XCTest

final class ThankYouViewControllerTests: TestCase {
    private var viewController: ThankYouViewController!
    private let listener = ThankYouListenerMock()
    private let interfaceOrientationStream = InterfaceOrientationStreamingMock()

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        interfaceOrientationStream.isLandscape = Just<Bool>(false).eraseToAnyPublisher()

        let key = LabConfirmationKey(identifier: "Key Here",
                                     bucketIdentifier: Data(),
                                     confirmationKey: Data(),
                                     validUntil: Date())

        viewController = ThankYouViewController(listener: listener,
                                                theme: theme,
                                                exposureConfirmationKey: key,
                                                interfaceOrientationStream: interfaceOrientationStream)
    }

    // MARK: - Tests

    func test_thankYou_snapshotStateLoading() {
        snapshots(matching: viewController)
    }
}
