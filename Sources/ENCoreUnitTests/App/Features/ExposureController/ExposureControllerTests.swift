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

final class ExposureControllerTests: TestCase {
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

        dataController.lastSuccessfulFetchDate = Date()
        dataController.fetchAndProcessExposureKeySetsHandler = { _ in Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher() }

        let stream = PassthroughSubject<ExposureState, Never>()
        mutableStateStream.updateHandler = { [weak self] state in
            self?.mutableStateStream.currentExposureState = state
            stream.send(state)
        }
        mutableStateStream.exposureState = stream.eraseToAnyPublisher()

        exposureManager.getExposureNotificationStatusHandler = { .active }
    }

    func test_activate_activesAndUpdatesStream() {
        exposureManager.activateHandler = { completion in completion(.active) }

        XCTAssertEqual(exposureManager.activateCallCount, 0)
        XCTAssertEqual(mutableStateStream.updateCallCount, 0)

        controller.activate()

        XCTAssertEqual(exposureManager.activateCallCount, 1)
        XCTAssert(mutableStateStream.updateCallCount > 1)
    }

    func test_requestExposureNotificationPermission_callsManager_updatesStream() {
        var receivedEnabled: Bool!
        exposureManager.setExposureNotificationEnabledHandler = { enabled, completion in
            receivedEnabled = enabled

            completion(.success(()))
        }

        XCTAssertEqual(exposureManager.setExposureNotificationEnabledCallCount, 0)
        XCTAssertEqual(mutableStateStream.updateCallCount, 0)

        controller.requestExposureNotificationPermission()

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

    func test_managerIsActive_updatesStreamWithActive() {
        activate()
        let expectation = expect(activeState: .active)

        triggerUpdateStream()

        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsInactiveBecauseBluetoothOff_updatesStreamWithInactiveBluetoothOff() {
        activate()
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.bluetoothOff) }

        let expectation = expect(activeState: .inactive(.bluetoothOff))

        triggerUpdateStream()

        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsInactiveBecauseDisabled_updatesStreamWithInactiveDisabled() {
        activate()
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.disabled) }

        let expectation = expect(activeState: .inactive(.disabled))

        triggerUpdateStream()

        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsInactiveBecauseRestricted_updatesStreamWithInactiveDisabled() {
        activate()
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.restricted) }

        let expectation = expect(activeState: .inactive(.disabled))

        triggerUpdateStream()

        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsInactiveBecauseNotAuthorized_updatesStreamWithNotAuthorized() {
        activate()
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.notAuthorized) }

        let expectation = expect(activeState: .notAuthorized)

        triggerUpdateStream()

        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsInactiveBecauseUnknown_updatesStreamWithDisabled() {
        activate()
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.unknown) }

        let expectation = expect(activeState: .inactive(.disabled))

        triggerUpdateStream()

        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsNotAuthorized_updatesStreamWithNotAuthorized() {
        activate()
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
        mutableStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .active)
        dataController.fetchAndProcessExposureKeySetsHandler = { _ in
            return Just(())
                .setFailureType(to: ExposureDataError.self)
                .eraseToAnyPublisher()
        }

        XCTAssertEqual(dataController.fetchAndProcessExposureKeySetsCallCount, 0)

        controller
            .updateWhenRequired()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        XCTAssertEqual(dataController.fetchAndProcessExposureKeySetsCallCount, 1)
    }

    func test_noRecentUpdate_returnsNoRecentNotificationInactiveState() {
        dataController.lastSuccessfulFetchDate = Date().addingTimeInterval(-24 * 60 * 60 - 1)
        exposureManager.activateHandler = { $0(.active) }

        controller.activate()
        controller.refreshStatus()

        XCTAssertEqual(mutableStateStream.currentExposureState?.activeState, .inactive(.noRecentNotificationUpdates))
    }

    func test_updatesAndFetches_afterInitialActiveState() {
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.bluetoothOff) }
        exposureManager.activateHandler = { $0(.active) }

        dataController.fetchAndProcessExposureKeySetsCallCount = 0

        controller.activate()

        exposureManager.getExposureNotificationStatusHandler = { .active }
        mutableStateStream.update(state: .init(notifiedState: .notNotified, activeState: .active))

        XCTAssertEqual(dataController.fetchAndProcessExposureKeySetsCallCount, 1)
    }

    // MARK: - Private

    private func activate() {
        exposureManager.activateHandler = { completion in
            completion(.active)
        }
        controller.activate()
    }

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
