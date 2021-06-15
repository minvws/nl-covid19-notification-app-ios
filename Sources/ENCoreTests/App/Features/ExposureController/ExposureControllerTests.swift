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
import XCTest

final class ExposureControllerTests: TestCase {
    private var controller: ExposureController!
    private var exposureController = ExposureControllingMock()
    private let mutableStateStream = MutableExposureStateStreamingMock()
    private let exposureManager = ExposureManagingMock()
    private let dataController = ExposureDataControllingMock()
    private let userNotificationController = UserNotificationControllingMock()
    private let networkStatusStream = NetworkStatusStreamingMock()
    private let currentAppVersion = "1.0"

    override func setUp() {
        super.setUp()

        networkStatusStream.networkReachable = true
        networkStatusStream.networkReachableStream = .just(true)

        controller = ExposureController(mutableStateStream: mutableStateStream,
                                        exposureManager: exposureManager,
                                        dataController: dataController,
                                        networkStatusStream: networkStatusStream,
                                        userNotificationController: userNotificationController,
                                        currentAppVersion: currentAppVersion)

        dataController.lastSuccessfulExposureProcessingDate = currentDate()
        dataController.fetchAndProcessExposureKeySetsHandler = { _ in .empty() }

        let stream = BehaviorSubject<ExposureState>(value: .init(notifiedState: .notNotified, activeState: .active))
        mutableStateStream.updateHandler = { [weak self] state in
            self?.mutableStateStream.currentExposureState = state
            stream.onNext(state)
        }
        mutableStateStream.exposureState = stream

        exposureManager.authorizationStatus = .authorized
        exposureManager.getExposureNotificationStatusHandler = { .active }
        exposureManager.isExposureNotificationEnabledHandler = { true }

        userNotificationController.getIsAuthorizedHandler = { completion in
            completion(true)
        }
    }

    func test_activate_shouldCallActivate() {
        exposureManager.activateHandler = { completion in completion(.active) }

        XCTAssertEqual(exposureManager.activateCallCount, 0)

        controller.activate()
            .subscribe()
            .disposed(by: disposeBag)

        XCTAssertEqual(exposureManager.activateCallCount, 1)
    }

    func test_activate_shouldNotBePerformedTwice() {
        exposureManager.activateHandler = { completion in completion(.active) }

        XCTAssertEqual(exposureManager.activateCallCount, 0)

        controller.activate()
            .subscribe()
            .disposed(by: disposeBag)

        controller.activate()
            .subscribe()
            .disposed(by: disposeBag)

        XCTAssertEqual(exposureManager.activateCallCount, 1)
    }

    func test_activate_activesAndUpdatesStream_inBackground() {
        exposureManager.activateHandler = { completion in completion(.active) }

        XCTAssertEqual(exposureManager.activateCallCount, 0)

        let exp = XCTestExpectation(description: "")

        controller
            .activate()
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(exposureManager.activateCallCount, 1)
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
            .activate()
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(exposureManager.setExposureNotificationEnabledCallCount, 0)
    }

    func test_activate_isExposureNotificationDisabled() {
        dataController.didCompleteOnboarding = true
        exposureManager.isExposureNotificationEnabledHandler = { false }
        setupActivation()

        let exp = XCTestExpectation(description: "")

        controller
            .activate()
            .subscribe(onCompleted: {
                exp.fulfill()
            })
            .disposed(by: disposeBag)
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(exposureManager.setExposureNotificationEnabledCallCount, 1)
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

    func test_confirmExposureNotification_shouldUpdateStateStreamOnSuccess() {
        activate()

        dataController.removeFirstNotificationReceivedDateHandler = {
            .empty()
        }
        dataController.removeLastExposureHandler = {
            .empty()
        }

        XCTAssertEqual(dataController.removeLastExposureCallCount, 0)
        XCTAssertEqual(dataController.removeFirstNotificationReceivedDateCallCount, 0)

        controller.confirmExposureNotification()

        XCTAssertEqual(dataController.removeLastExposureCallCount, 1)
        XCTAssertEqual(dataController.removeFirstNotificationReceivedDateCallCount, 1)
    }

    func test_managerIsActive_updatesStreamWithActive() {
        activate()
        let expectation = expect(activeState: .active)

        triggerUpdateStream()
        
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsInactiveBecauseBluetoothOff_updatesStreamWithInactiveBluetoothOff() {
        activate()
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.bluetoothOff) }

        let expectation = expect(activeState: .inactive(.bluetoothOff))

        triggerUpdateStream()
        
        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsInactiveBecauseDisabled_updatesStreamWithInactiveDisabled() {
        activate()
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.disabled) }

        let expectation = expect(activeState: .inactive(.disabled))

        triggerUpdateStream()

        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsInactiveBecauseRestricted_updatesStreamWithInactiveDisabled() {
        activate()
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.restricted) }

        let expectation = expect(activeState: .inactive(.disabled))

        triggerUpdateStream()

        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsInactiveBecauseNotAuthorized_updatesStreamWithNotAuthorized() {
        activate()
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.notAuthorized) }

        let expectation = expect(activeState: .notAuthorized)

        triggerUpdateStream()

        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsInactiveBecauseUnknown_doesNotUpdateStream() {
        activate()
        exposureManager.getExposureNotificationStatusHandler = { .inactive(.unknown) }

        let expectation = expect(noUpdateExpected: true)

        triggerUpdateStream()

        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertTrue(expectation.evaluate())
    }

    func test_managerIsNotAuthorized_updatesStreamWithNotAuthorized() {
        activate()
        exposureManager.getExposureNotificationStatusHandler = { .notAuthorized }

        let expectation = expect(activeState: .notAuthorized)

        triggerUpdateStream()

        waitForExpectations(timeout: 2, handler: nil)
        XCTAssertTrue(expectation.evaluate())
    }

    func test_requestLabConfirmationKey_isSuccess_callsCompletionWithKey() {
        let expirationDate = currentDate()

        dataController.requestLabConfirmationKeyHandler = {
            let labConfirmationKey = LabConfirmationKey(identifier: "identifier",
                                                        bucketIdentifier: Data(),
                                                        confirmationKey: Data(),
                                                        validUntil: expirationDate)
            return .just(labConfirmationKey)
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
            .error(ExposureDataError.serverError)
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
            .empty()
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
        mutableStateStream.exposureState = .just(mutableStateStream.currentExposureState!)
        dataController.fetchAndProcessExposureKeySetsHandler = { _ in
            .empty()
        }

        XCTAssertEqual(dataController.fetchAndProcessExposureKeySetsCallCount, 0)

        controller
            .updateWhenRequired()
            .subscribe { _ in }
            .disposed(by: disposeBag)

        XCTAssertEqual(dataController.fetchAndProcessExposureKeySetsCallCount, 1)
    }

    func test_updateWhenRequired_callsDataControllerWhenBluetoothInactive() {
        mutableStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .inactive(.bluetoothOff))
        mutableStateStream.exposureState = .just(mutableStateStream.currentExposureState!)
        dataController.fetchAndProcessExposureKeySetsHandler = { _ in
            .empty()
        }

        XCTAssertEqual(dataController.fetchAndProcessExposureKeySetsCallCount, 0)

        controller
            .updateWhenRequired()
            .subscribe { _ in }
            .disposed(by: disposeBag)

        XCTAssertEqual(dataController.fetchAndProcessExposureKeySetsCallCount, 1)
    }

    func test_updateWhenRequired_callsDataControllerWhenNotificationsDisabled() {
        mutableStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .inactive(.pushNotifications))
        mutableStateStream.exposureState = .just(mutableStateStream.currentExposureState!)
        dataController.fetchAndProcessExposureKeySetsHandler = { _ in
            .empty()
        }

        XCTAssertEqual(dataController.fetchAndProcessExposureKeySetsCallCount, 0)

        controller
            .updateWhenRequired()
            .subscribe { _ in }
            .disposed(by: disposeBag)

        XCTAssertEqual(dataController.fetchAndProcessExposureKeySetsCallCount, 1)
    }

    func test_updateWhenRequired_doesNotCallDataControllerWhenAuthorizedDenied() {
        mutableStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .authorizationDenied)
        mutableStateStream.exposureState = .just(mutableStateStream.currentExposureState!)
        dataController.fetchAndProcessExposureKeySetsHandler = { _ in
            .empty()
        }

        XCTAssertEqual(dataController.fetchAndProcessExposureKeySetsCallCount, 0)

        controller
            .updateWhenRequired()
            .subscribe { _ in }
            .disposed(by: disposeBag)

        XCTAssertEqual(dataController.fetchAndProcessExposureKeySetsCallCount, 0)
    }

    func test_updateWhenRequired_doesNotCallDataControllerWhenNotAuthorized() {
        mutableStateStream.currentExposureState = .init(notifiedState: .notNotified, activeState: .notAuthorized)
        mutableStateStream.exposureState = .just(mutableStateStream.currentExposureState!)
        dataController.fetchAndProcessExposureKeySetsHandler = { _ in
            .empty()
        }

        XCTAssertEqual(dataController.fetchAndProcessExposureKeySetsCallCount, 0)

        controller
            .updateWhenRequired()
            .subscribe { _ in }
            .disposed(by: disposeBag)

        XCTAssertEqual(dataController.fetchAndProcessExposureKeySetsCallCount, 0)
    }

    func test_noRecentUpdate_returnsNoRecentNotificationInactiveState() {
        dataController.lastSuccessfulExposureProcessingDate = currentDate().addingTimeInterval(-24 * 60 * 60 - 1)
        activate()
        let expectation = expect(activeState: .inactive(.noRecentNotificationUpdates))

        triggerUpdateStream()
        
        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertTrue(expectation.evaluate())
    }

    func test_updateAndProcessPendingUploads() {
        dataController.processPendingUploadRequestsHandler = {
            .empty()
        }

        dataController.processExpiredUploadRequestsHandler = {
            .empty()
        }

        mutableStateStream.exposureState = .just(.init(notifiedState: .notNotified, activeState: .active))
        exposureManager.authorizationStatus = .authorized

        let exp = expectation(description: "Wait for async")

        controller
            .updateAndProcessPendingUploads()
            .subscribe(onCompleted: {
                exp.fulfill()
            }, onError: { _ in
                XCTFail()
            })
            .disposed(by: disposeBag)

        wait(for: [exp], timeout: 1)
    }

    func test_updateAndProcessPendingUploads_notAuthorized() {
        exposureManager.authorizationStatus = .notAuthorized

        let exp = expectation(description: "Wait for async")

        controller
            .updateAndProcessPendingUploads()
            .subscribe(onCompleted: {
                XCTFail()
            }, onError: { error in
                XCTAssertEqual(error as? ExposureDataError, .notAuthorized)
                exp.fulfill()
            })
            .disposed(by: disposeBag)

        wait(for: [exp], timeout: 1)
    }

    func test_exposureNotificationStatusCheck_active_setsLastENStatusCheck() {
        exposureManager.getExposureNotificationStatusHandler = {
            .active
        }

        controller
            .exposureNotificationStatusCheck()
            .subscribe { _ in }
            .disposed(by: disposeBag)

        XCTAssertEqual(dataController.setLastENStatusCheckDateCallCount, 1)
        XCTAssertEqual(userNotificationController.getAuthorizationStatusCallCount, 0)
    }

    func test_exposureNotificationStatusCheck_notActive_noLastCheck_setsLastENStatusCheck() {
        exposureManager.getExposureNotificationStatusHandler = {
            .inactive(.disabled)
        }
        dataController.lastENStatusCheckDate = nil

        controller
            .exposureNotificationStatusCheck()
            .subscribe { _ in }
            .disposed(by: disposeBag)

        XCTAssertEqual(dataController.setLastENStatusCheckDateCallCount, 1)
        XCTAssertEqual(userNotificationController.getAuthorizationStatusCallCount, 0)
    }

    func test_exposureNotificationStatusCheck_notActive_lessThan24h_doesntSetLastENStatusCheck() {
        exposureManager.getExposureNotificationStatusHandler = {
            .inactive(.disabled)
        }

        let timeInterval = TimeInterval(60 * 60 * 20) // 20 hours
        dataController.lastENStatusCheckDate = currentDate().advanced(by: -timeInterval)

        controller
            .exposureNotificationStatusCheck()
            .subscribe { _ in }
            .disposed(by: disposeBag)

        XCTAssertEqual(dataController.setLastENStatusCheckDateCallCount, 0)
        XCTAssertEqual(userNotificationController.getAuthorizationStatusCallCount, 0)
    }

    func test_exposureNotificationStatusCheck_notActive_notifiesAfter24h() {
        
        XCTAssertEqual(userNotificationController.displayNotActiveNotificationCallCount, 0)
        
        exposureManager.getExposureNotificationStatusHandler = {
            .inactive(.disabled)
        }

        let timeInterval = TimeInterval(60 * 60 * 25) // 25 hours
        dataController.lastENStatusCheckDate = currentDate().advanced(by: -timeInterval)

        controller
            .exposureNotificationStatusCheck()
            .subscribe { _ in }
            .disposed(by: disposeBag)

        XCTAssertEqual(dataController.setLastENStatusCheckDateCallCount, 1)
        XCTAssertEqual(userNotificationController.displayNotActiveNotificationCallCount, 1)
    }

    func test_lastOpenedNotificationCheck_moreThan3Hours_postsNotification() {
        
        XCTAssertEqual(userNotificationController.displayExposureReminderNotificationCallCount, 0)
        
        let timeInterval = TimeInterval(60 * 60 * 4) // 4 hours
        dataController.lastAppLaunchDate = currentDate().advanced(by: -(timeInterval + 1))
        dataController.lastExposure = ExposureReport(date: currentDate())
        dataController.lastUnseenExposureNotificationDate = currentDate().advanced(by: -timeInterval)

        controller
            .lastOpenedNotificationCheck()
            .subscribe { _ in }
            .disposed(by: disposeBag)

        XCTAssertEqual(userNotificationController.displayExposureReminderNotificationCallCount, 1)
    }

    func test_lastOpenedNotificationCheck_lessThan3Hours_doesntPostNotification() {
        let timeInterval = TimeInterval(60 * 60 * 2) // 2 hours
        dataController.lastAppLaunchDate = currentDate().advanced(by: -timeInterval)
        dataController.lastExposure = ExposureReport(date: currentDate())
        dataController.lastUnseenExposureNotificationDate = currentDate().advanced(by: -timeInterval)

        controller
            .lastOpenedNotificationCheck()
            .subscribe { _ in }
            .disposed(by: disposeBag)

        XCTAssertEqual(userNotificationController.getAuthorizationStatusCallCount, 0)
        XCTAssertEqual(userNotificationController.displayExposureReminderNotificationCallCount, 0)
    }

    func test_lastOpenedNotificationCheck_48Hours_ToDays() {
        let timeInterval = TimeInterval(60 * 60 * 48) // 48 hours
        dataController.lastExposure = ExposureReport(date: currentDate().advanced(by: -timeInterval))

        let days = currentDate().days(sinceDate: dataController.lastExposure!.date)

        XCTAssertEqual(days, 2)
    }

    func test_getAppVersionInformation_shouldCallDataController() {
        let completionExpectation = expectation(description: "completion")

        dataController.getAppVersionInformationHandler = {
            .just(.init(minimumVersion: "1.0.0", minimumVersionMessage: "minimumVersionMessage", appStoreURL: "http://www.example.com"))
        }

        controller.getAppVersionInformation { appVersionInformation in
            XCTAssertEqual(appVersionInformation?.minimumVersion, "1.0.0")
            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_getAppVersionInformation_shouldReturnNilOnError() {
        let completionExpectation = expectation(description: "completion")

        dataController.getAppVersionInformationHandler = {
            .error(ExposureDataError.networkUnreachable)
        }

        controller.getAppVersionInformation { appVersionInformation in
            XCTAssertNil(appVersionInformation)
            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_getStoredAppConfigFeatureFlags_shouldCallDataController() {
        // Arrange
        let completionExpectation = expectation(description: "completion")

        dataController.getStoredAppConfigFeatureFlagsHandler = {
            completionExpectation.fulfill()
            return [.init(id: "someId", featureEnabled: true)]
        }

        // Act
        let featureFlags = controller.getStoredAppConfigFeatureFlags()

        // Assert
        waitForExpectations()
        XCTAssertEqual(featureFlags, [.init(id: "someId", featureEnabled: true)])
    }
    
    func test_getStoredShareKeyURL_shouldCallDataController() {
        // Arrange
        let completionExpectation = expectation(description: "completion")

        dataController.getStoredShareKeyURLHandler = {
            completionExpectation.fulfill()
            return "http://www.someurl.com"
        }

        // Act
        let url = controller.getStoredShareKeyURL()

        // Assert
        waitForExpectations()
        XCTAssertEqual(url, "http://www.someurl.com")
    }

    // MARK: - postExposureManagerActivation

    func test_postExposureManagerActivation_shouldUpdateStateStream() {
        networkStatusStream.networkReachable = true
        let completionExpectation = expectation(description: "completion")
        let stream = BehaviorSubject<ExposureState>(value: .init(notifiedState: .notNotified, activeState: .active))
        mutableStateStream.exposureState = stream

        exposureManager.setExposureNotificationEnabledHandler = { _, completion in
            XCTAssertTrue(Thread.current.qualityOfService == .userInitiated)
            completion(.success(()))
        }
        exposureManager.activateHandler = { completion in
            XCTAssertTrue(Thread.current.isMainThread)
            completion(.active)
        }
        userNotificationController.getAuthorizationStatusHandler = { completion in
            XCTAssertTrue(Thread.current.qualityOfService == .userInitiated)
            completion(.authorized)
        }

        controller.activate()
            .subscribe(onCompleted: {
                self.controller.postExposureManagerActivation()
                completionExpectation.fulfill()
                
            })
            .disposed(by: disposeBag)

        stream.onNext(.init(notifiedState: .notNotified, activeState: .active))
        
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(mutableStateStream.updateArgValues.last?.notifiedState, .notNotified)
        XCTAssertEqual(mutableStateStream.updateArgValues.last?.activeState, .active)
    }

    // MARK: - Pausing

    func test_pause() {
        let date = Date(timeIntervalSince1970: 1593538088) // 30/06/20 17:28
        let exposureManagerExpectation = expectation(description: "setExposureNotificationEnabled")
        exposureManager.setExposureNotificationEnabledHandler = { enabled, completion in
            XCTAssertFalse(enabled)
            exposureManagerExpectation.fulfill()
            completion(.success(()))
        }

        controller.pause(untilDate: date)

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(exposureManager.setExposureNotificationEnabledCallCount, 1)
        XCTAssertEqual(dataController.pauseEndDateSetCallCount, 1)
        XCTAssertEqual(dataController.pauseEndDate, date)
        XCTAssertEqual(mutableStateStream.updateCallCount, 1)
        XCTAssertEqual(mutableStateStream.updateArgValues.first?.notifiedState, .notNotified)
        XCTAssertEqual(mutableStateStream.updateArgValues.first?.activeState, .inactive(.paused(date)))
    }

    func test_unpause() {
        activate()

        let exposureManagerExpectation = expectation(description: "setExposureNotificationEnabled")
        exposureManager.setExposureNotificationEnabledHandler = { enabled, completion in
            XCTAssertTrue(enabled)
            exposureManagerExpectation.fulfill()
            completion(.success(()))
        }

        controller.unpause()

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(exposureManager.setExposureNotificationEnabledCallCount, 1)
        XCTAssertEqual(dataController.pauseEndDateSetCallCount, 1)
        XCTAssertEqual(dataController.pauseEndDate, nil)
        XCTAssertEqual(mutableStateStream.updateArgValues.last?.notifiedState, .notNotified)
        XCTAssertEqual(mutableStateStream.updateArgValues.last?.activeState, .active)
    }

    func test_unpause_inInactiveState() {
        let exposureManagerExpectation = expectation(description: "setExposureNotificationEnabled")
        exposureManager.setExposureNotificationEnabledHandler = { enabled, completion in
            XCTAssertTrue(enabled)
            exposureManagerExpectation.fulfill()
            completion(.success(()))
        }

        exposureManager.activateHandler = { completion in
            completion(.active)
        }
        userNotificationController.getAuthorizationStatusHandler = { completion in
            completion(.authorized)
        }

        controller.unpause()

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(exposureManager.setExposureNotificationEnabledCallCount, 1)
        XCTAssertEqual(dataController.pauseEndDateSetCallCount, 1)
        XCTAssertEqual(dataController.pauseEndDate, nil)
        XCTAssertEqual(mutableStateStream.updateArgValues.last?.notifiedState, .notNotified)
        XCTAssertEqual(mutableStateStream.updateArgValues.last?.activeState, .active)
    }
    
    func test_refreshStatus_shouldRunOnBackgroundThread() {
        // Arrange
        let updateStreamExpectation = expectation(description: "updateStream")
        dataController.pauseEndDate = currentDate().addingTimeInterval(2000) // some random enddate
        mutableStateStream.updateHandler = { _ in
            XCTAssertTrue(Thread.current.qualityOfService == .userInitiated)
            updateStreamExpectation.fulfill()
        }
        
        // Act
        controller.refreshStatus()
        
        // Assert
        waitForExpectations(timeout: 2, handler: nil)
    }

    // MARK: - Private

    private func setupActivation() {
        exposureManager.setExposureNotificationEnabledHandler = { _, completion in
            completion(.success(()))
        }
        exposureManager.activateHandler = { completion in
            completion(.active)
        }
        userNotificationController.getAuthorizationStatusHandler = { completion in
            completion(.authorized)
        }
    }

    private func activate() {
        setupActivation()
        controller.activate()
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func triggerUpdateStream() {
        controller.refreshStatus()
    }

    private func expect(activeState: ExposureActiveState? = nil, notifiedState: ExposureNotificationState? = nil, noUpdateExpected: Bool = false) -> ExpectStatusEvaluator {
        let completionExpectation = expectation(description: "completion")
        completionExpectation.isInverted = noUpdateExpected
        let evaluator = ExpectStatusEvaluator(activeState: activeState, notifiedState: notifiedState, updateExpectation: completionExpectation)

        mutableStateStream.updateHandler = evaluator.updateHandler

        return evaluator
    }

    private final class ExpectStatusEvaluator {
        private let expectedActiveState: ExposureActiveState?
        private let expectedNotifiedState: ExposureNotificationState?
        private let updateExpectation: XCTestExpectation

        private var receivedState: ExposureState?

        init(activeState: ExposureActiveState?, notifiedState: ExposureNotificationState?, updateExpectation expectation: XCTestExpectation) {
            expectedActiveState = activeState
            expectedNotifiedState = notifiedState
            updateExpectation = expectation
        }

        var updateHandler: (ExposureState) -> () {
            return { [weak self] state in
                self?.receivedState = state
                self?.updateExpectation.fulfill()
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
                                  validUntil: currentDate())
    }
}
