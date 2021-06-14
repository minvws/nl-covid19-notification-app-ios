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
    private var viewController: ThankYouViewController!
    private let listener = ThankYouListenerMock()
    private let interfaceOrientationStream = InterfaceOrientationStreamingMock()

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        recordSnapshots = false

        interfaceOrientationStream.isLandscape = BehaviorSubject(value: false)

        let key = LabConfirmationKey(identifier: "ABCDEFG".asGGDkey,
                                     bucketIdentifier: Data(),
                                     confirmationKey: Data(),
                                     validUntil: currentDate())

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
