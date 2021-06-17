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
import RxRelay
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
    private var mockApplicationLifecycleStream: ApplicationLifecycleStreaming!
    
    private var didBecomeActiveRelay: PublishRelay<Void>!
    private var mockExposureState = BehaviorSubject<ExposureState>(value: .init(notifiedState: .notNotified, activeState: .active))
    
    override func setUp() {
        super.setUp()

        recordSnapshots = true

        mockRouter = ShareKeyViaWebsiteRoutingMock()
        mockExposureController = ExposureControllingMock()
        mockExposureStateStream = ExposureStateStreamingMock()
        mockInterfaceOrientationStream = InterfaceOrientationStreamingMock()
        mockApplicationController = ApplicationControllingMock()
        mockCardListener = CardListeningMock()
        mockExposureDataController = ExposureDataControllingMock()
        mockInterfaceOrientationStream.isLandscape = BehaviorSubject(value: false)
        mockPauseController = PauseControllingMock()
        
        didBecomeActiveRelay = PublishRelay<Void>()
        mockApplicationLifecycleStream = ApplicationLifecycleStreamingMock(didBecomeActive: didBecomeActiveRelay)
        
        mockExposureStateStream.exposureState = mockExposureState

        sut = ShareKeyViaWebsiteViewController(theme: theme,
                                                exposureController: mockExposureController,
                                                exposureStateStream: mockExposureStateStream,
                                                interfaceOrientationStream: mockInterfaceOrientationStream,
                                                applicationController: mockApplicationController,
                                                applicationLifecycleStream: mockApplicationLifecycleStream)
        sut.router = mockRouter
    }

    // MARK: - Tests

    func test_snapshot_stateLoading() {
        sut.state = .loading
        snapshots(matching: sut, waitForMainThread: true)
    }

    func test_snapshot_stateUploadKeys() {
        sut.state = .uploadKeys(confirmationKey: getFakeLabConfirmationKey())
        snapshots(matching: sut, waitForMainThread: true)
    }
    
    func test_snapshot_stateKeysUploaded() {
        sut.state = .keysUploaded(confirmationKey: getFakeLabConfirmationKey())
        snapshots(matching: sut, waitForMainThread: true)
    }
    
    func test_snapshot_stateError() {
        sut.state = .loadingError
        snapshots(matching: sut, waitForMainThread: true)
    }
    
    func test_viewDidLoad_calls_exposureController() {
        XCTAssertNotNil(sut.view)
        XCTAssertEqual(mockExposureController.requestLabConfirmationKeyCallCount, 1)
    }
    
    func test_didBecomeActive_shouldDismissScreenIfConfirmationKeyIsExpired() {
        // Arrange
        let completionExpectation = expectation(description: "completionExpectation")
        mockRouter.shareKeyViaWebsiteWantsDismissalHandler = { _ in completionExpectation.fulfill() }
        XCTAssertEqual(mockRouter.shareKeyViaWebsiteWantsDismissalCallCount, 0)
        
        // Force an expired confirmation key
        let keyExpirationDate = currentDate().addingTimeInterval(-1000)
        let confirmationKey = getFakeLabConfirmationKey(validUntilDate: keyExpirationDate)
        let confirmationKeyRequestExpectation = expectation(description: "completionExpectation")
        mockExposureController.requestLabConfirmationKeyHandler = { completion in
            completion(.success(confirmationKey))
            confirmationKeyRequestExpectation.fulfill()
        }
        
        // Setup listeners for state changes in viewDidLoad
        sut.viewDidLoad()
        
        // Wait until the confirmation key was requested (and stored in the viewcontroller)
        wait(for: [confirmationKeyRequestExpectation], timeout: 5)
        
        // Act
        didBecomeActiveRelay.accept(())
        
        // Assert
        waitForExpectations()
        XCTAssertEqual(mockRouter.shareKeyViaWebsiteWantsDismissalCallCount, 1)
    }
    
    func test_didBecomeActive_shouldNotDismissScreenIfConfirmationKeyIsNotExpired() {
        // Arrange
        let completionExpectation = expectation(description: "completionExpectation")
        completionExpectation.isInverted = true
        mockRouter.shareKeyViaWebsiteWantsDismissalHandler = { _ in completionExpectation.fulfill() }
        XCTAssertEqual(mockRouter.shareKeyViaWebsiteWantsDismissalCallCount, 0)
        
        // expiration date 5 minutes in the future
        let keyExpirationDate = currentDate().addingTimeInterval(5 * 60)
        let confirmationKey = getFakeLabConfirmationKey(validUntilDate: keyExpirationDate)
        let confirmationKeyRequestExpectation = expectation(description: "completionExpectation")
        mockExposureController.requestLabConfirmationKeyHandler = { completion in
            completion(.success(confirmationKey))
            confirmationKeyRequestExpectation.fulfill()
        }
        
        // Setup listeners for state changes in viewDidLoad
        sut.viewDidLoad()
        
        // Wait until the confirmation key was requested (and stored in the viewcontroller)
        wait(for: [confirmationKeyRequestExpectation], timeout: 5)
        
        // Act
        didBecomeActiveRelay.accept(())
        
        // Assert
        waitForExpectations()
        XCTAssertEqual(mockRouter.shareKeyViaWebsiteWantsDismissalCallCount, 0)
    }
    
    // MARK: - Private Helpers
    
    private func getFakeLabConfirmationKey(validUntilDate: Date = currentDate()) -> LabConfirmationKey {
        LabConfirmationKey(identifier: "key here",
                           bucketIdentifier: Data(),
                           confirmationKey: Data(),
                           validUntil: validUntilDate)
    }

}
