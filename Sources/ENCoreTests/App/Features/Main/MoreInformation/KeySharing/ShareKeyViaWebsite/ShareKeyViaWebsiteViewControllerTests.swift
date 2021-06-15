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

final class ShareKeyViaWebsiteViewControllerSnapshotTests: TestCase {
    
    private var sut: ShareKeyViaWebsiteViewController!
    
    private var mockRouter: ShareKeyViaWebsiteRoutingMock!
    private var mockExposureController: ExposureControllingMock!
    private var mockExposureStateStream: ExposureStateStreamingMock!
    private var mockInterfaceOrientationStream: InterfaceOrientationStreamingMock!
    private var mockCardListener: CardListeningMock!
    private var mockExposureDataController: ExposureDataControllingMock!
    private var mockPauseController: PauseControllingMock!
    private var mockApplicationController: ApplicationControllingMock!
    
    override func setUp() {
        super.setUp()

        recordSnapshots = false

        mockRouter = ShareKeyViaWebsiteRoutingMock()
        mockExposureController = ExposureControllingMock()
        mockExposureStateStream = ExposureStateStreamingMock()
        mockInterfaceOrientationStream = InterfaceOrientationStreamingMock()
        mockApplicationController = ApplicationControllingMock()
        mockCardListener = CardListeningMock()
        mockExposureDataController = ExposureDataControllingMock()
        mockInterfaceOrientationStream.isLandscape = BehaviorSubject(value: false)
        mockPauseController = PauseControllingMock()

        mockExposureStateStream.exposureState = .just(ExposureState(
            notifiedState: .notNotified,
            activeState: .active
        ))

        sut = ShareKeyViaWebsiteViewController(theme: theme,
                                                exposureController: mockExposureController,
                                                exposureStateStream: mockExposureStateStream,
                                                interfaceOrientationStream: mockInterfaceOrientationStream,
                                                applicationController: mockApplicationController)
        sut.router = mockRouter
    }

    // MARK: - Tests

    func test_snapshotStateLoading() {
        sut.state = .loading
        snapshots(matching: sut, waitForMainThread: true)
    }

    func test_snapshotStateUploadKeys() {
        sut.state = .uploadKeys(confirmationKey: getFakeLabConfirmationKey())
        snapshots(matching: sut, waitForMainThread: true)
    }
    
    func test_snapshotStateKeysUploaded() {
        sut.state = .keysUploaded(confirmationKey: getFakeLabConfirmationKey())
        snapshots(matching: sut, waitForMainThread: true)
    }
    
    func test_viewDidLoad_calls_exposureController() {
        XCTAssertNotNil(sut.view)
        XCTAssertEqual(mockExposureController.requestLabConfirmationKeyCallCount, 1)
    }
    
    // MARK: - Private Helpers
    
    private func getFakeLabConfirmationKey() -> LabConfirmationKey {
        LabConfirmationKey(identifier: "key here",
                           bucketIdentifier: Data(),
                           confirmationKey: Data(),
                           validUntil: currentDate())
    }

}
