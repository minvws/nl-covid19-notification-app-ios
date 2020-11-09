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
    private var exposureController = ExposureControllingMock()
    private let mutableStateStream = MutableExposureStateStreamingMock()
    private let exposureManager = ExposureManagingMock()
    private let dataController = ExposureDataControllingMock()
    private let userNotificationCenter = UserNotificationCenterMock()
    private var mutableBluetoothStateStream = MutableBluetoothStateStreamingMock()
    private let networkStatusStream = NetworkStatusStreamingMock(networkStatusStream: CurrentValueSubject<Bool, Never>(true).eraseToAnyPublisher())
    private let currentAppVersion = "1.0"

    override func setUp() {
        super.setUp()

        networkStatusStream.currentStatus = true
        controller = ExposureController(mutableStateStream: mutableStateStream,
                                        exposureManager: exposureManager,
                                        dataController: dataController,
                                        networkStatusStream: networkStatusStream,
                                        userNotificationCenter: userNotificationCenter,
                                        mutableBluetoothStateStream: mutableBluetoothStateStream,
                                        currentAppVersion: currentAppVersion)

        dataController.lastSuccessfulProcessingDate = Date()
        dataController.fetchAndProcessExposureKeySetsHandler = { _ in Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher() }

        let stream = PassthroughSubject<ExposureState, Never>()
        mutableStateStream.updateHandler = { [weak self] state in
            self?.mutableStateStream.currentExposureState = state
            stream.send(state)
        }
        mutableStateStream.exposureState = stream.eraseToAnyPublisher()

        exposureManager.authorizationStatus = .authorized
        exposureManager.getExposureNotificationStatusHandler = { .active }
        exposureManager.isExposureNotificationEnabledHandler = { true }

        userNotificationCenter.getAuthorizationStatusHandler = { completition in
            completition(.authorized)
        }
        userNotificationCenter.addHandler = { _, completition in
            completition?(nil)
        }
    }

    func test_activate_activesAndDoesntUpdatesStream() {
        exposureManager.activateHandler = { completion in completion(.active) }

        XCTAssertEqual(exposureManager.activateCallCount, 0)
        XCTAssertEqual(mutableStateStream.updateCallCount, 0)

        controller.activate(inBackgroundMode: false)

        XCTAssertEqual(exposureManager.activateCallCount, 1)
        XCTAssert(mutableStateStream.updateCallCount > 1)
    }

    func test_activate_activesAndUpdatesStream_inBackground() {
        exposureManager.activateHandler = { completion in completion(.active) }

        XCTAssertEqual(exposureManager.activateCallCount, 0)
        XCTAssertEqual(mutableStateStream.updateCallCount, 0)

        let exp = XCTestExpectation(description: "")

        controller
            .activate(inBackgroundMode: true).sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(exposureManager.activateCallCount, 1)
        XCTAssertEqual(mutableStateStream.updateCallCount, 1)
    }

    func test_deactive_callsDeactivate() {
        XCTAssertEqual(exposureManager.deactivateCallCount, 0)

        controller.deactivate()

        XCTAssertEqual(exposureManager.deactivateCallCount, 1)
    }

    func test_activate_isExposureNotificationEnabled() {
        exposureManager.isExposureNotificationEnabledHandler = { true }
        setupActivation()

        let exp = XCTestExpectation(description: "")

        controller
            .activate(inBackgroundMode: false).sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(exposureManager.setExposureNotificationEnabledCallCount, 0)
        XCTAssert(mutableStateStream.updateCallCount > 1)
    }

    func test_activate_isExposureNotificationDisabled() {
        dataController.didCompleteOnboarding = true
        exposureManager.isExposureNotificationEnabledHandler = { false }
        setupActivation()

        let exp = XCTestExpectation(description: "")

        controller
            .activate(inBackgroundMode: false).sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(exposureManager.setExposureNotificationEnabledCallCount, 1)
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

        controller.requestExposureNotificationPermission(nil)

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

    func test_managerIsInactiveBecauseUnknown_doesNotUpdateStream() {
        activate()
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.unknown) }

        let expectation = expect()

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
        exposureManager.getDiagnosisKeysHandler = { completion in
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

        XCTAssertEqual(exposureManager.getDiagnosisKeysCallCount, 0)
        XCTAssertEqual(dataController.uploadCallCount, 0)

        let exp = expectation(description: "Scheduling complete")

        var receivedResult: ExposureControllerUploadKeysResult!
        controller.requestUploadKeys(forLabConfirmationKey: LabConfirmationKey.test) { result in
            receivedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(exposureManager.getDiagnosisKeysCallCount, 1)
        XCTAssertEqual(dataController.uploadCallCount, 1)
        XCTAssertNotNil(receivedResult)
        XCTAssertEqual(receivedResult, ExposureControllerUploadKeysResult.success)
    }

    func test_requestUploadKeys_failsWithNotAuthorizedError_callsCompletionWithNotAuthorized() {
        exposureManager.getDiagnosisKeysHandler = { completion in completion(.failure(.notAuthorized)) }

        XCTAssertEqual(exposureManager.getDiagnosisKeysCallCount, 0)
        XCTAssertEqual(dataController.uploadCallCount, 0)

        var receivedResult: ExposureControllerUploadKeysResult!
        controller.requestUploadKeys(forLabConfirmationKey: LabConfirmationKey.test) { result in
            receivedResult = result
        }

        XCTAssertEqual(exposureManager.getDiagnosisKeysCallCount, 1)
        XCTAssertEqual(dataController.uploadCallCount, 0)
        XCTAssertNotNil(receivedResult)
        XCTAssertEqual(receivedResult, ExposureControllerUploadKeysResult.notAuthorized)
    }

    func test_requestUploadKeys_failsWithOtherError_callsCompletionWithNotActive() {
        exposureManager.getDiagnosisKeysHandler = { completion in completion(.failure(.unknown)) }

        XCTAssertEqual(exposureManager.getDiagnosisKeysCallCount, 0)
        XCTAssertEqual(dataController.uploadCallCount, 0)

        var receivedResult: ExposureControllerUploadKeysResult!
        controller.requestUploadKeys(forLabConfirmationKey: LabConfirmationKey.test) { result in
            receivedResult = result
        }

        XCTAssertEqual(exposureManager.getDiagnosisKeysCallCount, 1)
        XCTAssertEqual(dataController.uploadCallCount, 0)
        XCTAssertNotNil(receivedResult)
        XCTAssertEqual(receivedResult, ExposureControllerUploadKeysResult.inactive)
    }

    func test_updateWhenRequired_callsDataControllerWhenActive() {
        mutableStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .active)
        mutableStateStream.exposureState = Just(mutableStateStream.currentExposureState!).eraseToAnyPublisher()
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

    func test_updateWhenRequired_callsDataControllerWhenBluetoothInactive() {
        mutableStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .inactive(.bluetoothOff))
        mutableStateStream.exposureState = Just(mutableStateStream.currentExposureState!).eraseToAnyPublisher()
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

    func test_updateWhenRequired_callsDataControllerWhenNotificationsDisabled() {
        mutableStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .inactive(.pushNotifications))
        mutableStateStream.exposureState = Just(mutableStateStream.currentExposureState!).eraseToAnyPublisher()
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
        dataController.lastSuccessfulProcessingDate = Date().addingTimeInterval(-24 * 60 * 60 - 1)
        exposureManager.isExposureNotificationEnabledHandler = { true }
        exposureManager.activateHandler = { $0(.active) }

        controller.activate(inBackgroundMode: false)
        controller.refreshStatus()

        XCTAssertEqual(mutableStateStream.currentExposureState?.activeState, .inactive(.noRecentNotificationUpdates))
    }

    func test_updatesAndFetches_afterInitialActiveState() {
        exposureManager.getExposureNotificationStatusHandler = { .active }
        exposureManager.activateHandler = { $0(.active) }

        controller.activate(inBackgroundMode: false)

        mutableStateStream.update(state: .init(notifiedState: .notNotified, activeState: .active))
        mutableStateStream.exposureState = Just(.init(notifiedState: .notNotified, activeState: .active)).eraseToAnyPublisher()

        XCTAssertEqual(dataController.fetchAndProcessExposureKeySetsCallCount, 1)
    }

    func test_updateAndProcessPendingUploads() {
        dataController.processPendingUploadRequestsHandler = {
            Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }

        mutableStateStream.exposureState = Just(.init(notifiedState: .notNotified, activeState: .active)).eraseToAnyPublisher()
        exposureManager.authorizationStatus = .authorized

        let exp = expectation(description: "Wait for async")

        controller
            .updateAndProcessPendingUploads()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure:
                    XCTFail()
                case .finished:
                    exp.fulfill()
                }
            }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        wait(for: [exp], timeout: 1)
    }

    func test_updateAndProcessPendingUploads_notAuthorized() {
        exposureManager.authorizationStatus = .notAuthorized

        let exp = expectation(description: "Wait for async")

        controller
            .updateAndProcessPendingUploads()
            .sink(receiveCompletion: { result in
                switch result {
                case let .failure(error):
                    XCTAssert(error == .notAuthorized)
                case .finished:
                    XCTFail()
                }
                exp.fulfill()
            }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        wait(for: [exp], timeout: 1)
    }

    func test_exposureNotificationStatusCheck_active_setsLastENStatusCheck() {
        exposureManager.getExposureNotificationStatusHandler = {
            return .active
        }

        controller
            .exposureNotificationStatusCheck()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        XCTAssertEqual(dataController.setLastENStatusCheckDateCallCount, 1)
        XCTAssertEqual(userNotificationCenter.getAuthorizationStatusCallCount, 0)
    }

    func test_exposureNotificationStatusCheck_notActive_noLastCheck_setsLastENStatusCheck() {
        exposureManager.getExposureNotificationStatusHandler = {
            return .inactive(.disabled)
        }
        dataController.lastENStatusCheckDate = nil

        controller
            .exposureNotificationStatusCheck()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        XCTAssertEqual(dataController.setLastENStatusCheckDateCallCount, 1)
        XCTAssertEqual(userNotificationCenter.getAuthorizationStatusCallCount, 0)
    }

    func test_exposureNotificationStatusCheck_notActive_lessThan24h_doesntSetLastENStatusCheck() {
        exposureManager.getExposureNotificationStatusHandler = {
            return .inactive(.disabled)
        }

        let timeInterval = TimeInterval(60 * 60 * 20) // 20 hours
        dataController.lastENStatusCheckDate = Date().advanced(by: -timeInterval)

        controller
            .exposureNotificationStatusCheck()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        XCTAssertEqual(dataController.setLastENStatusCheckDateCallCount, 0)
        XCTAssertEqual(userNotificationCenter.getAuthorizationStatusCallCount, 0)
    }

    func test_exposureNotificationStatusCheck_notActive_notifiesAfter24h() {
        exposureManager.getExposureNotificationStatusHandler = {
            return .inactive(.disabled)
        }

        let timeInterval = TimeInterval(60 * 60 * 25) // 25 hours
        dataController.lastENStatusCheckDate = Date().advanced(by: -timeInterval)

        controller
            .exposureNotificationStatusCheck()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        XCTAssertEqual(dataController.setLastENStatusCheckDateCallCount, 1)
        XCTAssertEqual(userNotificationCenter.getAuthorizationStatusCallCount, 1)
        XCTAssertEqual(userNotificationCenter.addCallCount, 1)
    }

    func test_lastOpenedNotificationCheck_moreThan3Hours_postsNotification() {
        let timeInterval = TimeInterval(60 * 60 * 4) // 4 hours
        dataController.lastAppLaunchDate = Date().advanced(by: -timeInterval)
        dataController.lastExposure = ExposureReport(date: Date())
        dataController.lastUnseenExposureNotificationDate = Date().advanced(by: -timeInterval)

        controller
            .lastOpenedNotificationCheck()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        XCTAssertEqual(userNotificationCenter.getAuthorizationStatusCallCount, 1)
        XCTAssertEqual(userNotificationCenter.addCallCount, 1)
    }

    func test_lastOpenedNotificationCheck_lessThan3Hours_doesntPostNotification() {
        let timeInterval = TimeInterval(60 * 60 * 2) // 2 hours
        dataController.lastAppLaunchDate = Date().advanced(by: -timeInterval)
        dataController.lastExposure = ExposureReport(date: Date())
        dataController.lastUnseenExposureNotificationDate = Date().advanced(by: -timeInterval)

        controller
            .lastOpenedNotificationCheck()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .disposeOnTearDown(of: self)

        XCTAssertEqual(userNotificationCenter.getAuthorizationStatusCallCount, 0)
        XCTAssertEqual(userNotificationCenter.addCallCount, 0)
    }

    func test_lastOpenedNotificationCheck_48Hours_ToDays() {
        let timeInterval = TimeInterval(60 * 60 * 48) // 48 hours
        dataController.lastExposure = ExposureReport(date: Date().advanced(by: -timeInterval))

        let days = controller.daysAgo(dataController.lastExposure!.date)

        XCTAssertEqual(days, 2)
    }

    func test_notifyUser24HoursNoCheck() {

        let timeInterval = TimeInterval(60 * 60 * 48) // 48 hours
        let lastLocalNotificationExposureDate = Date().advanced(by: -timeInterval)
        let lastSuccessfulProcessingDate = Date().advanced(by: -timeInterval)

        dataController.lastSuccessfulProcessingDate = lastSuccessfulProcessingDate
        dataController.lastLocalNotificationExposureDate = lastLocalNotificationExposureDate

        controller.notifyUser24HoursNoCheckIfRequired()

        XCTAssertEqual(dataController.lastLocalNotificationExposureDate, lastLocalNotificationExposureDate)
    }

    func test_notNotifyUser24HoursDidCheck() {

        let timeInterval = TimeInterval(60 * 60 * 48) // 48 hours
        let lastLocalNotificationExposureDate = Date().advanced(by: -timeInterval)

        dataController.lastSuccessfulProcessingDate = Date()
        dataController.lastLocalNotificationExposureDate = lastLocalNotificationExposureDate

        controller.notifyUser24HoursNoCheckIfRequired()

        XCTAssertEqual(dataController.lastLocalNotificationExposureDate, lastLocalNotificationExposureDate)
    }

    // MARK: - Private

    private func setupActivation() {
        exposureManager.setExposureNotificationEnabledHandler = { _, completion in
            completion(.success(()))
        }
        exposureManager.activateHandler = { completion in
            completion(.active)
        }
        userNotificationCenter.getAuthorizationStatusHandler = { completion in
            completion(.authorized)
        }
    }

    private func activate() {
        setupActivation()
        controller.activate(inBackgroundMode: false)
    }

    private func triggerUpdateStream() {
        controller.refreshStatus()
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
            guard let state = receivedState else {
                return expectedActiveState == nil && expectedNotifiedState == nil
            }

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
