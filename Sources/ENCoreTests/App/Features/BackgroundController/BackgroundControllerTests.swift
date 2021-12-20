/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import BackgroundTasks
@testable import ENCore
import ENFoundation
import Foundation
import RxSwift
import XCTest

final class BackgroundControllerTests: TestCase {
    private var controller: BackgroundController!

    private let exposureController = ExposureControllingMock()
    private let dataController = ExposureDataControllingMock()
    private let networkController = NetworkControllingMock()
    private let taskScheduler = TaskSchedulingMock()

    private var exposureManager = ExposureManagingMock(authorizationStatus: .authorized)
    private let userNotificationController = UserNotificationControllingMock()
    private let mockRandomNumberGenerator = RandomNumberGeneratingMock()
    private let environmentController = EnvironmentControllingMock()

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        let configuration = BackgroundTaskConfiguration(decoyProbabilityRange: 0 ..< 1,
                                                        decoyHourRange: 0 ... 1,
                                                        decoyMinuteRange: 0 ... 1,
                                                        decoyDelayRangeLowerBound: 0 ... 1,
                                                        decoyDelayRangeUpperBound: 0 ... 1)

        controller = BackgroundController(exposureController: exposureController,
                                          networkController: networkController,
                                          configuration: configuration,
                                          exposureManager: exposureManager,
                                          dataController: dataController,
                                          userNotificationController: userNotificationController,
                                          taskScheduler: taskScheduler,
                                          bundleIdentifier: "nl.rijksoverheid.en",
                                          randomNumberGenerator: mockRandomNumberGenerator,
                                          environmentController: environmentController)

        exposureManager.getExposureNotificationStatusHandler = { .active }
        exposureController.activateHandler = { .empty() }
        exposureController.updateWhenRequiredHandler = { .empty() }
        exposureController.processPendingUploadRequestsHandler = { .empty() }
        exposureController.exposureNotificationStatusCheckHandler = { .empty() }
        exposureController.updateAndProcessPendingUploadsHandler = { .empty() }
        exposureController.sendNotificationIfAppShouldUpdateHandler = { .empty() }
        exposureController.updateTreatmentPerspectiveHandler = { .empty() }
        exposureController.lastOpenedNotificationCheckHandler = { .empty() }
        exposureController.refreshStatusHandler = { completion in completion?() }

        dataController.removePreviousExposureDateIfNeededHandler = { .empty() }
    }

    // MARK: - Tests

    func test_handleRefresh() {
        let exp = expectation(description: "asyncTask")
        let task = BackgroundTaskMock(isBackgroundProcessingTask: true,
                                      identifier: BackgroundTaskIdentifiers.refresh.rawValue)
        task.setTaskCompletedHandler = { success in
            if success { exp.fulfill() }
        }

        controller.handle(task: task)

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(exposureController.updateAndProcessPendingUploadsCallCount, 1)
        XCTAssertEqual(exposureController.exposureNotificationStatusCheckCallCount, 1)

        XCTAssertEqual(exposureController.sendNotificationIfAppShouldUpdateCallCount, 1)
        XCTAssertEqual(exposureController.lastOpenedNotificationCheckCallCount, 1)
    }

    func test_handleRefreshWithoutTask() {

        controller.refresh(task: nil)

        XCTAssertEqual(exposureController.updateAndProcessPendingUploadsCallCount, 1)
        XCTAssertEqual(exposureController.exposureNotificationStatusCheckCallCount, 1)

        XCTAssertEqual(exposureController.sendNotificationIfAppShouldUpdateCallCount, 1)
        XCTAssertEqual(exposureController.lastOpenedNotificationCheckCallCount, 1)
    }

    func test_refresh_shouldActivateExposureController() {

        let completableCreationExpectation = expectation(description: "completable created")
        let completableSubscriptionExpectation = expectation(description: "subscribed to completable")

        exposureController.activateHandler = {
            completableCreationExpectation.fulfill()
            return Completable.empty().do(onSubscribe: {
                completableSubscriptionExpectation.fulfill()
            })
        }

        controller.refresh(task: nil)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_refresh_shouldUpdateStatusStream() {

        controller.refresh(task: nil)

        XCTAssertEqual(exposureController.refreshStatusCallCount, 1)
    }

    func test_refresh_shouldRemovePreviousExposureDates() {
        XCTAssertEqual(dataController.removePreviousExposureDateIfNeededCallCount, 0)

        controller.refresh(task: nil)

        XCTAssertEqual(dataController.removePreviousExposureDateIfNeededCallCount, 1)
    }

    func test_refresh_shouldFetchAndProcessKeySets() {
        let completableCreationExpectation = expectation(description: "completable created")
        let completableSubscriptionExpectation = expectation(description: "subscribed to completable")

        exposureController.updateWhenRequiredHandler = {
            completableCreationExpectation.fulfill()
            return Completable.empty().do(onSubscribe: {
                completableSubscriptionExpectation.fulfill()
            })
        }

        controller.refresh(task: nil)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_refresh_shouldNotFetchAndProcessKeySetsIfRefreshStatusStreamDoesNotFinish() {
        let completableCreationExpectation = expectation(description: "completable created")
        let completableSubscriptionExpectation = expectation(description: "subscribed to completable")
        completableSubscriptionExpectation.isInverted = true

        exposureController.refreshStatusHandler = { completion in /* intentionally not calling completion handler */ }

        exposureController.updateWhenRequiredHandler = {
            completableCreationExpectation.fulfill()
            return Completable.empty().do(onSubscribe: {
                completableSubscriptionExpectation.fulfill()
            })
        }

        controller.refresh(task: nil)

        waitForExpectations()
    }

    func test_refresh_shouldProcessPendingUploads() {
        let completableCreationExpectation = expectation(description: "completable created")
        let completableSubscriptionExpectation = expectation(description: "subscribed to completable")

        exposureController.updateAndProcessPendingUploadsHandler = {
            completableCreationExpectation.fulfill()
            return Completable.empty().do(onSubscribe: {
                completableSubscriptionExpectation.fulfill()
            })
        }

        controller.refresh(task: nil)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_refresh_shouldSendInactiveFrameworkNotificationIfNeeded() {
        let completableCreationExpectation = expectation(description: "completable created")
        let completableSubscriptionExpectation = expectation(description: "subscribed to completable")

        exposureController.exposureNotificationStatusCheckHandler = {
            completableCreationExpectation.fulfill()
            return Completable.empty().do(onSubscribe: {
                completableSubscriptionExpectation.fulfill()
            })
        }

        controller.refresh(task: nil)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_refresh_shouldSendNotificationIfAppShouldUpdate() {
        let completableCreationExpectation = expectation(description: "completable created")
        let completableSubscriptionExpectation = expectation(description: "subscribed to completable")

        exposureController.sendNotificationIfAppShouldUpdateHandler = {
            completableCreationExpectation.fulfill()
            return Completable.empty().do(onSubscribe: {
                completableSubscriptionExpectation.fulfill()
            })
        }

        controller.refresh(task: nil)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_refresh_shouldUpdateTreatmentPerspective() {
        let completableCreationExpectation = expectation(description: "completable created")
        let completableSubscriptionExpectation = expectation(description: "subscribed to completable")

        exposureController.updateTreatmentPerspectiveHandler = {
            completableCreationExpectation.fulfill()
            return Completable.empty().do(onSubscribe: {
                completableSubscriptionExpectation.fulfill()
            })
        }

        controller.refresh(task: nil)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_refresh_shouldSendExposureReminderNotificationIfNeeded() {
        let completableCreationExpectation = expectation(description: "completable created")
        let completableSubscriptionExpectation = expectation(description: "subscribed to completable")

        exposureController.lastOpenedNotificationCheckHandler = {
            completableCreationExpectation.fulfill()
            return Completable.empty().do(onSubscribe: {
                completableSubscriptionExpectation.fulfill()
            })
        }

        controller.refresh(task: nil)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_refresh_shouldProcessDecoyRegisterAndStopKeys() {
        let exp = expectation(description: "stopkeys")

        exposureManager.getExposureNotificationStatusHandler = {
            return .active
        }

        dataController.canProcessDecoySequence = true
        exposureController.getDecoyProbabilityHandler = { .just(1) }
        exposureController.requestLabConfirmationKeyHandler = { completion in
            completion(.success(ExposureConfirmationKeyMock(key: "", expiration: currentDate())))
        }
        exposureController.getPaddingHandler = {
            return .just(Padding(minimumRequestSize: 0, maximumRequestSize: 1))
        }

        networkController.stopKeysHandler = { _ in
            exp.fulfill()
            return .empty()
        }

        controller.refresh(task: nil)

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(networkController.stopKeysCallCount, 1)
        XCTAssertEqual(exposureController.getPaddingCallCount, 1)
    }

    func test_handleRefresh_duringPauseState_shouldSendPauseExpirationReminder() {
        let exp = expectation(description: "asyncTask")
        let notificationExpectation = expectation(description: "notification")

        let task = BackgroundTaskMock(isBackgroundProcessingTask: true,
                                      identifier: BackgroundTaskIdentifiers.refresh.rawValue)
        task.setTaskCompletedHandler = { success in
            if success { exp.fulfill() }
        }

        userNotificationController.displayPauseExpirationReminderHandler = { completion in
            notificationExpectation.fulfill()
            completion(true)
        }

        dataController.isAppPaused = true
        dataController.pauseEndDate = currentDate().addingTimeInterval(-.hours(2))

        controller.handle(task: task)

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(userNotificationController.displayPauseExpirationReminderCallCount, 1)

        XCTAssertEqual(exposureController.updateAndProcessPendingUploadsCallCount, 0)
        XCTAssertEqual(exposureController.exposureNotificationStatusCheckCallCount, 0)
        XCTAssertEqual(exposureController.sendNotificationIfAppShouldUpdateCallCount, 0)
        XCTAssertEqual(exposureController.lastOpenedNotificationCheckCallCount, 0)
    }

    func test_handleRefresh_duringPauseState_withinHourOfExpirationTime_shouldNOTSendPauseExpirationReminder() {
        let exp = expectation(description: "asyncTask")

        let task = BackgroundTaskMock(isBackgroundProcessingTask: true,
                                      identifier: BackgroundTaskIdentifiers.refresh.rawValue)
        task.setTaskCompletedHandler = { success in
            if success { exp.fulfill() }
        }

        userNotificationController.displayPauseExpirationReminderHandler = { completion in
            completion(true)
        }

        dataController.isAppPaused = true
        dataController.pauseEndDate = currentDate().addingTimeInterval(-.minutes(10))

        controller.handle(task: task)

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(userNotificationController.displayPauseExpirationReminderCallCount, 0)
    }

    func test_notHandleBackgroundDecoyRegisterENinactive() {
        let exp = expectation(description: "HandleBackgroundDecoyRegister")

        exposureManager.getExposureNotificationStatusHandler = {
            return .inactive(.disabled)
        }

        let task = BackgroundTaskMock(isBackgroundProcessingTask: true,
                                      identifier: BackgroundTaskIdentifiers.refresh.rawValue)
        task.setTaskCompletedHandler = { success in
            if success { exp.fulfill() }
        }

        controller.handle(task: task)

        wait(for: [exp], timeout: 2)

        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 0)
    }

    func test_notHandleBackgroundDecoyStopKeysENinactive() {

        exposureManager.getExposureNotificationStatusHandler = {
            return .inactive(.disabled)
        }

        exposureController.getPaddingHandler = {
            return .just(Padding(minimumRequestSize: 0, maximumRequestSize: 1))
        }

        networkController.stopKeysHandler = { _ in
            return .empty()
        }

        controller.performDecoySequenceIfNeeded()

        XCTAssertEqual(networkController.stopKeysCallCount, 0)
        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 0)
    }

    func test_performDecoySequenceIfNeeded_shouldNotWorkIfENisInactive() {
        exposureManager.getExposureNotificationStatusHandler = {
            return .inactive(.disabled)
        }

        controller.performDecoySequenceIfNeeded()

        XCTAssertEqual(exposureController.getDecoyProbabilityCallCount, 0)
        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 0)
    }

    func test_performDecoySequenceIfNeeded_shouldNotWorkIfDecoySequenceAlreadyDoneToday() {
        exposureManager.getExposureNotificationStatusHandler = {
            return .active
        }

        dataController.canProcessDecoySequence = false

        controller.performDecoySequenceIfNeeded()

        XCTAssertEqual(exposureController.getDecoyProbabilityCallCount, 0)
        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 0)
    }

    func test_scheduleTasks_shouldScheduleRefreshIfAppIsNotDeactivated() {

        let cancelTaskExpectation = expectation(description: "cancelTask")
        let submitTaskExpectation = expectation(description: "submitTask")

        exposureController.isAppDeactivatedHandler = {
            .just(false)
        }

        taskScheduler.cancelHandler = { identifier in
            XCTAssertEqual(identifier, "nl.rijksoverheid.en.exposure-notification")
            cancelTaskExpectation.fulfill()
        }

        taskScheduler.submitHandler = { bgTaskRequest in
            XCTAssertEqual(bgTaskRequest.identifier, "nl.rijksoverheid.en.exposure-notification")
            submitTaskExpectation.fulfill()
        }

        controller.scheduleTasks()

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(taskScheduler.cancelCallCount, 1)
        XCTAssertEqual(taskScheduler.submitCallCount, 1)
    }

    func test_scheduleTasks_shouldNotScheduleRefreshIfAppIsDeactivated() {

        let cancelAllTaskExpectation = expectation(description: "cancelAllTask")

        exposureController.isAppDeactivatedHandler = {
            .just(true)
        }

        taskScheduler.cancelAllTaskRequestsHandler = {
            cancelAllTaskExpectation.fulfill()
        }

        controller.scheduleTasks()

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(taskScheduler.cancelAllTaskRequestsCallCount, 1)
        XCTAssertEqual(taskScheduler.cancelCallCount, 0)
        XCTAssertEqual(taskScheduler.submitCallCount, 0)
    }

    func test_scheduleTasks_shouldCancelAllTaskRequestsAppIsDeactivated() {

        let cancelAllTaskExpectation = expectation(description: "cancelAllTask")
        exposureController.isAppDeactivatedHandler = { .just(true) }
        taskScheduler.cancelAllTaskRequestsHandler = { cancelAllTaskExpectation.fulfill() }

        controller.scheduleTasks()

        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_scheduleTasks_shouldRemovePreviousExposureDateAppIsDeactivated() {
        let cancelAllTaskExpectation = expectation(description: "cancelAllTask")
        taskScheduler.cancelAllTaskRequestsHandler = { cancelAllTaskExpectation.fulfill() }

        exposureController.isAppDeactivatedHandler = { .just(true) }

        XCTAssertEqual(dataController.removePreviousExposureDateIfNeededCallCount, 0)

        controller.scheduleTasks()

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(dataController.removePreviousExposureDateIfNeededCallCount, 1)
    }

    func test_scheduleTasks_shouldScheduleRefreshIfAppDeactivatedCannotBeDetermined() {

        let cancelTaskExpectation = expectation(description: "cancelTask")
        let submitTaskExpectation = expectation(description: "submitTask")

        exposureController.isAppDeactivatedHandler = {
            .error(ExposureDataError.networkUnreachable)
        }

        taskScheduler.cancelHandler = { identifier in
            XCTAssertEqual(identifier, "nl.rijksoverheid.en.exposure-notification")
            cancelTaskExpectation.fulfill()
        }

        taskScheduler.submitHandler = { bgTaskRequest in
            XCTAssertEqual(bgTaskRequest.identifier, "nl.rijksoverheid.en.exposure-notification")
            submitTaskExpectation.fulfill()
        }

        controller.scheduleTasks()

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(taskScheduler.cancelCallCount, 1)
        XCTAssertEqual(taskScheduler.submitCallCount, 1)
    }

    func test_performDecoySequenceIfNeeded() {
        let completionExpectation = expectation(description: "completion")

        environmentController.isiOS13orHigher = true
        dataController.canProcessDecoySequence = true
        mockRandomNumberGenerator.randomIntHandler = { _ in 0 }
        mockRandomNumberGenerator.randomFloatHandler = { _ in 0 }
        exposureController.getDecoyProbabilityHandler = { .just(1) }
        exposureController.requestLabConfirmationKeyHandler = { completion in
            XCTAssertTrue(Thread.current.qualityOfService == .utility)
            completion(.success(ExposureConfirmationKeyMock(key: "", expiration: currentDate())))
        }

        exposureController.getPaddingHandler = {
            return .just(Padding(minimumRequestSize: 0, maximumRequestSize: 1))
        }
        networkController.stopKeysHandler = { _ in
            completionExpectation.fulfill()
            return .empty()
        }

        controller.performDecoySequenceIfNeeded()

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(dataController.setLastDecoyProcessDateCallCount, 1)
        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 1)
        XCTAssertEqual(networkController.stopKeysCallCount, 1)
        XCTAssertEqual(exposureController.getPaddingCallCount, 1)
    }

    func test_performDecoySequenceIfNeededIos12() {
        let completionExpectation = expectation(description: "completion")

        environmentController.isiOS13orHigher = false

        dataController.canProcessDecoySequence = true
        mockRandomNumberGenerator.randomIntHandler = { _ in 0 }
        mockRandomNumberGenerator.randomFloatHandler = { _ in 0 }
        exposureController.getDecoyProbabilityHandler = { .just(1) }

        exposureController.requestLabConfirmationKeyHandler = { completion in
            completion(.success(ExposureConfirmationKeyMock(key: "", expiration: currentDate())))
        }

        exposureManager.getExposureNotificationStatusHandler = {
            return .active
        }

        exposureController.getPaddingHandler = {
            return .just(Padding(minimumRequestSize: 0, maximumRequestSize: 1))
        }

        networkController.stopKeysHandler = { _ in
            completionExpectation.fulfill()
            return .empty()
        }

        exposureController.requestLabConfirmationKeyHandler = { completion in
            completion(.success(ExposureConfirmationKeyMock(key: "", expiration: currentDate())))
        }

        controller.performDecoySequenceIfNeeded()

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(dataController.setLastDecoyProcessDateCallCount, 1)
        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 1)
        XCTAssertEqual(networkController.stopKeysCallCount, 1)
        XCTAssertEqual(exposureController.getPaddingCallCount, 1)
        XCTAssertEqual(taskScheduler.submitCallCount, 0)
    }

    func test_performDecoySequenceIfNeeded_shouldNotPerformDecoyOnSameDay() {

        dataController.canProcessDecoySequence = false

        controller.performDecoySequenceIfNeeded()

        XCTAssertEqual(dataController.setLastDecoyProcessDateCallCount, 0)
        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 0)
        XCTAssertEqual(taskScheduler.submitCallCount, 0)
    }

    func test_registerActivityHandle_shouldSetLaunchActivityHandler() {

        environmentController.isiOS12 = true

        XCTAssertEqual(exposureManager.setLaunchActivityHandlerCallCount, 0)

        controller.registerActivityHandle()

        XCTAssertEqual(exposureManager.setLaunchActivityHandlerCallCount, 1)
    }

    func test_registerActivityHandle_shouldNotSetLaunchActivityHandlerOniOS13AndHigher() {

        environmentController.isiOS12 = false

        XCTAssertEqual(exposureManager.setLaunchActivityHandlerCallCount, 0)

        controller.registerActivityHandle()

        XCTAssertEqual(exposureManager.setLaunchActivityHandlerCallCount, 0)
    }

    func test_scheduleRemoteNotification_shouldRemoveNotificationFirst() {

        controller.scheduleRemoteNotification()

        XCTAssertEqual(userNotificationController.removeScheduledRemoteNotificationCallCount, 1)
    }

    func test_scheduleRemoteNotification_shouldScheduleNotification_withoutProbability() throws {

        exposureController.getScheduledNotificatonHandler = {
            self.getScheduledNotification(probability: nil)
        }

        controller.scheduleRemoteNotification()

        XCTAssertEqual(userNotificationController.scheduleRemoteNotificationCallCount, 1)
        let (title, body, datecomponents, targetscreen) = try XCTUnwrap(userNotificationController.scheduleRemoteNotificationArgValues.first)
        XCTAssertEqual(title, "Title")
        XCTAssertEqual(body, "Body")
        XCTAssertEqual(targetscreen, "share")
    }

    func test_scheduleRemoteNotification_withZeroProbability() throws {

        mockRandomNumberGenerator.randomFloatHandler = { range in
            0.1
        }
        exposureController.getScheduledNotificatonHandler = {
            self.getScheduledNotification(probability: 0)
        }

        controller.scheduleRemoteNotification()

        XCTAssertEqual(userNotificationController.scheduleRemoteNotificationCallCount, 0)
    }

    func test_scheduleRemoteNotification_with100PercentProbability() throws {

        mockRandomNumberGenerator.randomFloatHandler = { range in
            XCTAssertEqual(range.lowerBound, 0)
            XCTAssertEqual(range.upperBound, 1)
            return 0.1
        }
        exposureController.getScheduledNotificatonHandler = {
            self.getScheduledNotification(probability: 1)
        }

        controller.scheduleRemoteNotification()

        XCTAssertEqual(userNotificationController.scheduleRemoteNotificationCallCount, 1)
    }

    func test_scheduleRemoteNotification_withEqualProbability() throws {

        mockRandomNumberGenerator.randomFloatHandler = { range in
            0.5
        }
        exposureController.getScheduledNotificatonHandler = {
            self.getScheduledNotification(probability: 0.5)
        }

        controller.scheduleRemoteNotification()

        XCTAssertEqual(userNotificationController.scheduleRemoteNotificationCallCount, 1)
    }

    // MARK: - Private

    private func getScheduledNotification(probability: Float?) -> ApplicationConfiguration.ScheduledNotification {
        ApplicationConfiguration.ScheduledNotification(
            scheduledDateTime: "2021-12-16T14:00:00+01:00",
            title: "Title",
            body: "Body",
            targetScreen: "share",
            probability: probability
        )
    }

    private var labConfirmationKey: LabConfirmationKey {
        LabConfirmationKey(identifier: "", bucketIdentifier: Data(), confirmationKey: Data(), validUntil: currentDate())
    }
}
