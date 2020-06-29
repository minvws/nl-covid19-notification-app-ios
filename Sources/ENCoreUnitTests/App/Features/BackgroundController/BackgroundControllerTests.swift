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

        controller = BackgroundController(exposureController: exposureController)
    }

    // MARK: - Tests

    func test_handleBackgroundTask_success() {
        exposureController.updateWhenRequiredPublisherHandler = {
            return Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }
        exposureController.processPendingUploadRequestsPublisherHandler = {
            return Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }

        let task = MockBGProcessingTask(identifier: "nl.rijksoverheid.en.background-update")

        controller.handle(task: task)

        XCTAssertNotNil(task.completed)
        XCTAssert(task.completed!)
    }

    func test_handleBackgroundTask_failure() {
        exposureController.updateWhenRequiredPublisherHandler = {
            Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }
        exposureController.processPendingUploadRequestsPublisherHandler = {
            Fail(error: ExposureDataError.internalError).eraseToAnyPublisher()
        }

        let task = MockBGProcessingTask(identifier: "nl.rijksoverheid.en.background-update")

        controller.handle(task: task)

        XCTAssertNotNil(task.completed)
        XCTAssertFalse(task.completed!)
    }

    func test_handleBackgroundTask_cancel() {
        exposureController.updateWhenRequiredPublisherHandler = {
            Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }
        var cancelled = false
        let stream = PassthroughSubject<(), ExposureDataError>()
            .handleEvents(receiveCancel: {
                cancelled = true
            })
            .eraseToAnyPublisher()
        exposureController.processPendingUploadRequestsPublisherHandler = {
            return stream
        }

        let task = MockBGProcessingTask(identifier: "nl.rijksoverheid.en.background-update")
        controller.handle(task: task)
        task.expirationHandler?()

        XCTAssert(cancelled)
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
