/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import BackgroundTasks
import Combine
@testable import ENCore
import ENFoundation
import Foundation
import XCTest

final class BackgroundControllerTests: XCTestCase {
    private var controller: BackgroundController!

    private let exposureController = ExposureControllingMock()
    private let dataController = ExposureDataControllingMock()
    private let networkController = NetworkControllingMock()
    private let taskScheduler = TaskSchedulingMock()

    private var exposureManager = ExposureManagingMock(authorizationStatus: .authorized)
    private let userNotificationCenter = UserNotificationCenterMock()

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
                                          userNotificationCenter: userNotificationCenter,
                                          taskScheduler: taskScheduler,
                                          bundleIdentifier: "nl.rijksoverheid.en")

        exposureManager.getExposureNotificationStatusHandler = {
            return .active
        }
        exposureController.activateHandler = { _ in
            return Just(()).eraseToAnyPublisher()
        }
        exposureController.updateWhenRequiredHandler = {
            return Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }
        exposureController.processPendingUploadRequestsHandler = {
            return Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }
        exposureController.exposureNotificationStatusCheckHandler = {
            Just(()).eraseToAnyPublisher()
        }
        exposureController.updateAndProcessPendingUploadsHandler = {
            Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }

        exposureController.sendNotificationIfAppShouldUpdateHandler = {
            Just(()).eraseToAnyPublisher()
        }
        exposureController.updateTreatmentPerspectiveHandler = {
            Just(TreatmentPerspective.emptyMessage).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }

        exposureController.lastOpenedNotificationCheckHandler = {
            Just(()).eraseToAnyPublisher()
        }
    }

    // MARK: - Tests

    func test_handleRefresh() {
        let exp = expectation(description: "asyncTask")
        let task = MockBGProcessingTask(identifier: BackgroundTaskIdentifiers.refresh)
        task.completion = {
            exp.fulfill()
        }

        controller.handle(task: task)

        wait(for: [exp], timeout: 1)

        XCTAssertNotNil(task.completed)
        XCTAssertEqual(exposureController.updateAndProcessPendingUploadsCallCount, 1)
        XCTAssertEqual(exposureController.exposureNotificationStatusCheckCallCount, 1)

        XCTAssertEqual(exposureController.sendNotificationIfAppShouldUpdateCallCount, 1)
        XCTAssertEqual(exposureController.lastOpenedNotificationCheckCallCount, 1)
    }

    func test_handleBackgroundDecoyStopKeys() {
        let exp = expectation(description: "HandleBackgroundDecoyStopKeys")

        exposureManager.getExposureNotificationStatusHandler = {
            return .active
        }

        exposureController.getPaddingHandler = {
            return .just(Padding(minimumRequestSize: 0, maximumRequestSize: 1))
        }

        networkController.stopKeysHandler = { _ in
            return .just(())
        }

        let task = MockBGProcessingTask(identifier: .decoyStopKeys)
        task.completion = {
            exp.fulfill()
        }

        controller.handle(task: task)
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(networkController.stopKeysCallCount, 1)

        XCTAssertNotNil(task.completed)
        XCTAssert(task.completed!)
    }

    func test_notHandleBackgroundDecoyRegisterENinactive() {
        let exp = expectation(description: "HandleBackgroundDecoyRegister")

        exposureManager.getExposureNotificationStatusHandler = {
            return .inactive(.disabled)
        }

        let task = MockBGProcessingTask(identifier: .refresh)
        task.completion = {
            exp.fulfill()
        }

        controller.handle(task: task)

        wait(for: [exp], timeout: 2)

        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 0)

        XCTAssertNotNil(task.completed)
        XCTAssert(task.completed!)
    }

    func test_notHandleBackgroundDecoyStopKeysENinactive() {
        let exp = expectation(description: "HandleBackgroundDecoyStopKeys")

        exposureManager.getExposureNotificationStatusHandler = {
            return .inactive(.disabled)
        }

        exposureController.getPaddingHandler = {
            return .just(Padding(minimumRequestSize: 0, maximumRequestSize: 1))
        }

        networkController.stopKeysHandler = { _ in
            return .just(())
        }

        let task = MockBGProcessingTask(identifier: .decoyStopKeys)
        task.completion = {
            exp.fulfill()
        }

        controller.handle(task: task)
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(networkController.stopKeysCallCount, 0)

        XCTAssertNotNil(task.completed)
        XCTAssert(task.completed!)
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

    // MARK: - Private

    private var labConfirmationKey: LabConfirmationKey {
        LabConfirmationKey(identifier: "", bucketIdentifier: Data(), confirmationKey: Data(), validUntil: Date())
    }
}

private final class MockBGProcessingTask: BGProcessingTask {

    private(set) var completed: Bool?
    var completion: (() -> ())?

    override var identifier: String {
        return _identifier
    }

    private let _identifier: String

    init(identifier: BackgroundTaskIdentifiers) {
        self._identifier = identifier.rawValue
    }

    override func setTaskCompleted(success: Bool) {
        completed = success

        completion?()
    }
}
