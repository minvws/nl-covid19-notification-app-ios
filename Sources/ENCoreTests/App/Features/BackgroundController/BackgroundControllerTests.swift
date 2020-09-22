/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import BackgroundTasks
import Combine
@testable import ENCore
import Foundation
import XCTest

final class BackgroundControllerTests: XCTestCase {
    private var controller: BackgroundController!

    private let exposureController = ExposureControllingMock()
    private let networkController = NetworkControllingMock()
    private let taskScheduler = TaskSchedulingMock()

    private let exposureManager = ExposureManagingMock(authorizationStatus: .authorized)
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
        exposureController.appUpdateRequiredCheckHandler = {
            Just(()).eraseToAnyPublisher()
        }
    }

    // MARK: - Tests

    func test_scheduleDecoySequence() {
        exposureController.isAppDeactivatedHandler = {
            return Just(false).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }
        let calendar = Calendar.current
        let today = calendar.dateComponents([.day], from: Date()).day ?? 0
        let exp = expectation(description: "asyncTask")
        taskScheduler.submitHandler = { task in
            if task.identifier.contains(BackgroundTaskIdentifiers.decoySequence.rawValue) {
                guard let date = task.earliestBeginDate else {
                    return XCTFail()
                }
                let components = calendar.dateComponents([.hour, .day], from: date)
                XCTAssert(components.day == (today + 1))
                XCTAssert(components.hour == 1)
                exp.fulfill()
            }
        }

        controller.scheduleTasks()

        wait(for: [exp], timeout: 1)
    }

    func test_handeRefresh() {
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
    }

    func test_handleBackgroundDecoyRegister() {
        let exp = expectation(description: "HandleBackgroundDecoyRegister")

        exposureController.requestLabConfirmationKeyHandler = { completion in
            completion(.success(self.labConfirmationKey))
            // Async magic, no one likes it, but sometimes we have to do it.
            // Internally when scheduling an async process runs so we need to
            // have a delay here before we can fulfill the expectation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                exp.fulfill()
            }
        }

        let task = MockBGProcessingTask(identifier: .decoyRegister)

        controller.handle(task: task)
        wait(for: [exp], timeout: 2)

        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 1)

        XCTAssertNotNil(task.completed)
        XCTAssert(task.completed!)
    }

    func test_handleBackgroundDecoyStopKeys() {
        let exp = expectation(description: "HandleBackgroundDecoyStopKeys")

        exposureController.getPaddingHandler = {
            return Just(Padding(minimumRequestSize: 0, maximumRequestSize: 1)).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }

        networkController.stopKeysHandler = { _ in
            return Just(()).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
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
