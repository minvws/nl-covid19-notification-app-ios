/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
@testable import ENCore
import Foundation
import XCTest

final class ExposureControllerTests: XCTestCase {
    private var controller: ExposureController!
    private let mutableStateStream = MutableExposureStateStreamingMock()
    private let exposureManager = ExposureManagingMock()
    private let dataController = ExposureDataControllingMock()
    private let networkStatusStream = NetworkStatusStreamingMock(networkStatusStream: CurrentValueSubject<Bool, Never>(true).eraseToAnyPublisher())

    override func setUp() {
        super.setUp()

        networkStatusStream.currentStatus = true
        controller = ExposureController(mutableStateStream: mutableStateStream,
                                        exposureManager: exposureManager,
                                        dataController: dataController,
                                        networkStatusStream: networkStatusStream)

        exposureManager.activateCallCount = 0
        mutableStateStream.updateCallCount = 0
    }

    func test_activate_activesAndUpdatesStream() {
        exposureManager.activateHandler = { completion in completion(.active) }
        exposureManager.getExposureNotificationStatusHandler = { .active }

        XCTAssertEqual(exposureManager.activateCallCount, 0)
        XCTAssertEqual(mutableStateStream.updateCallCount, 0)

        controller.activate()

        XCTAssertEqual(exposureManager.activateCallCount, 1)
        XCTAssertEqual(mutableStateStream.updateCallCount, 2)
    }

    func test_requestExposureNotificationPermission_callsManager_updatesStream() {
        var receivedEnabled: Bool!
        exposureManager.setExposureNotificationEnabledHandler = { enabled, completion in
            receivedEnabled = enabled

            completion(.success(()))
        }

        exposureManager.getExposureNotificationStatusHandler = { .active }

        XCTAssertEqual(exposureManager.setExposureNotificationEnabledCallCount, 0)
        XCTAssertEqual(mutableStateStream.updateCallCount, 0)

        controller.requestExposureNotificationPermission()

        XCTAssertEqual(mutableStateStream.updateCallCount, 1)
        XCTAssertEqual(exposureManager.setExposureNotificationEnabledCallCount, 1)
        XCTAssertNotNil(receivedEnabled)
        XCTAssertTrue(receivedEnabled)
    }

    func test_requestPushNotificationPermission() {
        // Not implemented yet
    }

    func test_confirmExposureNotification() {
        // Not implemented yet
    }

    func test_activate_noManager_updatesStreamWithRequiresOSUpdate() {
        exposureManager.activateHandler = { completion in completion(.active) }

        let expectation = expect(activeState: .inactive(.requiresOSUpdate))

        controller = ExposureController(mutableStateStream: mutableStateStream,
                                        exposureManager: nil,
                                        dataController: dataController,
                                        networkStatusStream: networkStatusStream)
        controller.activate()

        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsActive_updatesStreamWithActive() {
        exposureManager.getExposureNotificationStatusHandler = { .active }

        let expectation = expect(activeState: .active)

        triggerUpdateStream()

        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsActive_noNetwork() {
        exposureManager.getExposureNotificationStatusHandler = { .active }

        networkStatusStream.currentStatus = false
        let expectation = expect(activeState: .inactive(.airplaneMode))

        triggerUpdateStream()

        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsInactiveBecauseBluetoothOff_updatesStreamWithInactiveBluetoothOff() {
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.bluetoothOff) }

        let expectation = expect(activeState: .inactive(.bluetoothOff))

        triggerUpdateStream()

        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsInactiveBecauseDisabled_updatesStreamWithInactiveDisabled() {
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.disabled) }

        let expectation = expect(activeState: .inactive(.disabled))

        triggerUpdateStream()

        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsInactiveBecauseRestricted_updatesStreamWithInactiveDisabled() {
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.restricted) }

        let expectation = expect(activeState: .inactive(.disabled))

        triggerUpdateStream()

        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsInactiveBecauseNotAuthorized_updatesStreamWithNotAuthorized() {
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.notAuthorized) }

        let expectation = expect(activeState: .notAuthorized)

        triggerUpdateStream()

        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsInactiveBecauseUnknown_updatesStreamWithDisabled() {
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.unknown) }

        let expectation = expect(activeState: .inactive(.disabled))

        triggerUpdateStream()

        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsNotAuthorized_updatesStreamWithNotAuthorized() {
        exposureManager.getExposureNotificationStatusHandler = { .notAuthorized }

        let expectation = expect(activeState: .notAuthorized)

        triggerUpdateStream()

        XCTAssertTrue(expectation.evaluate())
    }

    func test_requestLabConfirmationKey_isSuccess_callsCompletionWithKey() {
        let expirationDate = Date()

        dataController.requestLabConfirmationKeyHandler = {
            let labConfirmationKey = LabConfirmationKey(identifier: "identifier",
                                                        bucketIdentifier: Data(),
                                                        confirmationKey: Data(),
                                                        validUntil: expirationDate)
            return Just(labConfirmationKey)
                .setFailureType(to: ExposureDataError.self)
                .eraseToAnyPublisher()
        }

        XCTAssertEqual(dataController.requestLabConfirmationKeyCallCount, 0)

        var receivedResult: Result<ExposureConfirmationKey, ExposureDataError>!

        let exp = expectation(description: "Wait for async")
        controller.requestLabConfirmationKey { result in
            receivedResult = result

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(dataController.requestLabConfirmationKeyCallCount, 1)
        XCTAssertNotNil(receivedResult)
        XCTAssertNotNil(try! receivedResult.get())
        XCTAssertEqual(try! receivedResult.get().key, "identifier")
        XCTAssertEqual(try! receivedResult.get().expiration, expirationDate)
    }

    func test_requestLabConfirmationKey_isFailure_callsCompletionWithFailure() {
        dataController.requestLabConfirmationKeyHandler = {
            return Fail(error: ExposureDataError.serverError)
                .eraseToAnyPublisher()
        }

        XCTAssertEqual(dataController.requestLabConfirmationKeyCallCount, 0)

        var receivedResult: Result<ExposureConfirmationKey, ExposureDataError>!

        let exp = expectation(description: "Wait for async")
        controller.requestLabConfirmationKey { result in
            receivedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(dataController.requestLabConfirmationKeyCallCount, 1)
        XCTAssertNotNil(receivedResult)

        guard case let .failure(error) = receivedResult else {
            XCTFail("Expecting error")
            return
        }
        XCTAssertEqual(error, ExposureDataError.serverError)
    }

    func test_requestUploadKeys_exposureManagerReturnsKeys_callsCompletionWithKeys() {
        exposureManager.getDiagnonisKeysHandler = { completion in
            let keys = [
                DiagnosisKey(keyData: Data(),
                             rollingPeriod: 0,
                             rollingStartNumber: 0,
                             transmissionRiskLevel: 0)
            ]

            completion(.success(keys))
        }

        dataController.uploadHandler = { _, _ in
            Just(())
                .setFailureType(to: ExposureDataError.self)
                .eraseToAnyPublisher()
        }

        XCTAssertEqual(exposureManager.getDiagnonisKeysCallCount, 0)
        XCTAssertEqual(dataController.uploadCallCount, 0)

        let exp = expectation(description: "Scheduling complete")

        var receivedResult: ExposureControllerUploadKeysResult!
        controller.requestUploadKeys(forLabConfirmationKey: LabConfirmationKey.test) { result in
            receivedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(exposureManager.getDiagnonisKeysCallCount, 1)
        XCTAssertEqual(dataController.uploadCallCount, 1)
        XCTAssertNotNil(receivedResult)
        XCTAssertEqual(receivedResult, ExposureControllerUploadKeysResult.success)
    }

    func test_requestUploadKeys_failsWithNotAuthorizedError_callsCompletionWithNotAuthorized() {
        exposureManager.getDiagnonisKeysHandler = { completion in completion(.failure(.notAuthorized)) }

        XCTAssertEqual(exposureManager.getDiagnonisKeysCallCount, 0)
        XCTAssertEqual(dataController.uploadCallCount, 0)

        var receivedResult: ExposureControllerUploadKeysResult!
        controller.requestUploadKeys(forLabConfirmationKey: LabConfirmationKey.test) { result in
            receivedResult = result
        }

        XCTAssertEqual(exposureManager.getDiagnonisKeysCallCount, 1)
        XCTAssertEqual(dataController.uploadCallCount, 0)
        XCTAssertNotNil(receivedResult)
        XCTAssertEqual(receivedResult, ExposureControllerUploadKeysResult.notAuthorized)
    }

    func test_requestUploadKeys_failsWithOtherError_callsCompletionWithNotActive() {
        exposureManager.getDiagnonisKeysHandler = { completion in completion(.failure(.unknown)) }

        XCTAssertEqual(exposureManager.getDiagnonisKeysCallCount, 0)
        XCTAssertEqual(dataController.uploadCallCount, 0)

        var receivedResult: ExposureControllerUploadKeysResult!
        controller.requestUploadKeys(forLabConfirmationKey: LabConfirmationKey.test) { result in
            receivedResult = result
        }

        XCTAssertEqual(exposureManager.getDiagnonisKeysCallCount, 1)
        XCTAssertEqual(dataController.uploadCallCount, 0)
        XCTAssertNotNil(receivedResult)
        XCTAssertEqual(receivedResult, ExposureControllerUploadKeysResult.inactive)
    }

    func test_updateWhenRequired_callsDataControllerWhenActive() {
        exposureManager.getExposureNotificationStatusHandler = { .active }
        mutableStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .active)
        dataController.fetchAndProcessExposureKeySetsHandler = { _ in
            return Just(())
                .setFailureType(to: ExposureDataError.self)
                .eraseToAnyPublisher()
        }

        XCTAssertEqual(dataController.fetchAndProcessExposureKeySetsCallCount, 0)

        controller.updateWhenRequired()

        XCTAssertEqual(dataController.fetchAndProcessExposureKeySetsCallCount, 1)
    }

    // MARK: - Private

    private func triggerUpdateStream() {
        // trigger status update by mocking enabling notifications
        exposureManager.setExposureNotificationEnabledHandler = { _, completion in completion(.success(())) }

        controller.requestExposureNotificationPermission()
    }

    private func expect(activeState: ExposureActiveState? = nil, notifiedState: ExposureNotificationState? = nil) -> ExpectStatusEvaluator {
        let evaluator = ExpectStatusEvaluator(activeState: activeState, notifiedState: notifiedState)

        mutableStateStream.updateHandler = evaluator.updateHandler

        return evaluator
    }

    private final class ExpectStatusEvaluator {
        private let expectedActiveState: ExposureActiveState?
        private let expectedNotifiedState: ExposureNotificationState?

        private var receivedState: ExposureState?

        init(activeState: ExposureActiveState?, notifiedState: ExposureNotificationState?) {
            expectedActiveState = activeState
            expectedNotifiedState = notifiedState
        }

        var updateHandler: (ExposureState) -> () {
            return { [weak self] state in
                self?.receivedState = state
            }
        }

        func evaluate() -> Bool {
            guard let state = receivedState else { return false }

            var matchActiveState = true
            var matchNotified = true

            if let activeState = expectedActiveState {
                matchActiveState = activeState == state.activeState
            }

            if let notifiedState = expectedNotifiedState {
                matchNotified = notifiedState == state.notifiedState
            }

            return matchActiveState && matchNotified
        }
    }
}

private extension LabConfirmationKey {
    static var test: LabConfirmationKey {
        return LabConfirmationKey(identifier: "test",
                                  bucketIdentifier: Data(),
                                  confirmationKey: Data(),
                                  validUntil: Date())
    }
}
