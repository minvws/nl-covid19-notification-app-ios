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

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        let configuration = BackgroundTaskConfiguration(decoyProbabilityRange: 0 ..< 1,
                                                        decoyHourRange: 0 ... 1,
                                                        decoyMinuteRange: 0 ... 1,
                                                        decoyDelayRange: 0 ... 1)

        controller = BackgroundController(exposureController: exposureController,
                                          configuration: configuration)
    }

    // MARK: - Tests

    func test_handleBackgroundUpdateTask_success() {
        exposureController.updateWhenRequiredHandler = {
            return Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }
        exposureController.processPendingUploadRequestsHandler = {
            return Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }

        let task = MockBGProcessingTask(identifier: BackgroundTaskIdentifiers.update)

        controller.handle(task: task)

        XCTAssertNotNil(task.completed)
        XCTAssert(task.completed!)
    }

    func test_handleBackgroundUpdateTask_failure() {
        exposureController.updateWhenRequiredHandler = {
            Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }
        exposureController.processPendingUploadRequestsHandler = {
            Fail(error: ExposureDataError.internalError).eraseToAnyPublisher()
        }

        let task = MockBGProcessingTask(identifier: BackgroundTaskIdentifiers.update)

        controller.handle(task: task)

        XCTAssertNotNil(task.completed)
        XCTAssertFalse(task.completed!)
    }

    func test_handleBackgroundTask_cancel() {
        exposureController.updateWhenRequiredHandler = {
            Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }
        var cancelled = false
        let stream = PassthroughSubject<(), ExposureDataError>()
            .handleEvents(receiveCancel: {
                cancelled = true
            })
            .eraseToAnyPublisher()
        exposureController.processPendingUploadRequestsHandler = {
            return stream
        }

        let task = MockBGProcessingTask(identifier: BackgroundTaskIdentifiers.update)
        controller.handle(task: task)
        task.expirationHandler?()

        XCTAssert(cancelled)
    }

    func test_handleBackgroundDecoy() {
        let exp = expectation(description: "HandleBackgroundDecoy")

        exposureController.requestLabConfirmationKeyHandler = { completion in
            completion(.success(self.labConfirmationKey))
        }

        exposureController.requestStopKeysHandler = { completion in
            completion(.success(()))
            exp.fulfill()
        }

        let task = MockBGProcessingTask(identifier: BackgroundTaskIdentifiers.decoy)

        controller.handle(task: task)
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(exposureController.requestLabConfirmationKeyCallCount, 1)
        XCTAssertEqual(exposureController.requestStopKeysCallCount, 1)

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

    override var identifier: String {
        return _identifier
    }

    private let _identifier: String

    init(identifier: String) {
        self._identifier = identifier
    }

    override func setTaskCompleted(success: Bool) {
        completed = success
    }
}
