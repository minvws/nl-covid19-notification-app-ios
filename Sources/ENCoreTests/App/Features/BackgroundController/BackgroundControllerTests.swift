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

    private let exposureManager = ExposureManagingMock(authorizationStatus: .authorized)
    private let userNotificationCenter = UserNotificationCenterMock()

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        let configuration = BackgroundTaskConfiguration(decoyProbabilityRange: 0 ..< 1,
                                                        decoyHourRange: 0 ... 1,
                                                        decoyMinuteRange: 0 ... 1,
                                                        decoyDelayRange: 0 ... 1)

        controller = BackgroundController(exposureController: exposureController,
                                          networkController: networkController,
                                          configuration: configuration,
                                          exposureManager: exposureManager,
                                          userNotificationCenter: userNotificationCenter)
    }

    // MARK: - Tests

    /*
     func test_handleBackgroundUpdateTask_success() {
         exposureController.updateWhenRequiredHandler = {
             return Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
         }
         exposureController.processPendingUploadRequestsHandler = {
             return Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
         }

         let exp = expectation(description: "asyncTask")
         let task = MockBGProcessingTask(identifier: BackgroundTaskIdentifiers.update)
         task.completion = {
             exp.fulfill()
         }

         controller.handle(task: task)

         wait(for: [exp], timeout: 1)

         XCTAssertNotNil(task.completed)
         XCTAssert(task.completed!)
     }

     func test_handleBackgroundUpdateTask_failure() {
         exposureManager.getExposureNotificationStatusHandler = {
             return .active
         }
         exposureController.updateWhenRequiredHandler = {
             Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
         }
         exposureController.processPendingUploadRequestsHandler = {
             Fail(error: ExposureDataError.internalError).eraseToAnyPublisher()
         }

         let exp = expectation(description: "async task")
         let task = MockBGProcessingTask(identifier: .update)
         task.completion = {
             exp.fulfill()
         }

         controller.handle(task: task)

         wait(for: [exp], timeout: 1)

         XCTAssertNotNil(task.completed)
         XCTAssertFalse(task.completed!)
     }

     func test_handleBackgroundTask_cancel() {
         exposureManager.getExposureNotificationStatusHandler = {
             return .active
         }
         exposureController.updateWhenRequiredHandler = {
             Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
         }
         var cancelled = false

         let exp = expectation(description: "asyncTask")
         let stream = PassthroughSubject<(), ExposureDataError>()
             .handleEvents(receiveCancel: {
                 cancelled = true

                 exp.fulfill()
             })
             .eraseToAnyPublisher()

         exposureController.processPendingUploadRequestsHandler = {
             return stream
         }

         let task = MockBGProcessingTask(identifier: .update)

         controller.handle(task: task)

         // hacky: wait for a bit for the async handle function to complete
         sleep(2)

         task.expirationHandler?()

         wait(for: [exp], timeout: 1)

         XCTAssert(cancelled)
     }
     */

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

    /*
     func test_handleENStatusCheck() {
         let exp = expectation(description: "HandleENStatusCheck")
         exposureManager.getExposureNotificationStatusHandler = {
             return .authorizationDenied
         }
         userNotificationCenter.getAuthorizationStatusHandler = { completion in
             completion(.authorized)
         }
         userNotificationCenter.addHandler = { _, completion in
             exp.fulfill()
             completion?(nil)
         }
         let date = Calendar.current.date(byAdding: .hour, value: -24, to: Date())!
         exposureController.lastENStatusCheckDate = date

         let task = MockBGProcessingTask(identifier: .statusCheck)

         controller.handle(task: task)
         wait(for: [exp], timeout: 2)

         XCTAssertEqual(userNotificationCenter.addCallCount, 1)

         XCTAssertNotNil(task.completed)
         XCTAssert(task.completed!)
     }

     func test_handleENStatusCheck_doesntCallIfLessThan24hours() {
         exposureManager.getExposureNotificationStatusHandler = {
             return .authorizationDenied
         }

         let date = Calendar.current.date(byAdding: .hour, value: -20, to: Date())!
         exposureController.lastENStatusCheckDate = date

         let exp = expectation(description: "asyncTask")
         let task = MockBGProcessingTask(identifier: .statusCheck)
         task.completion = {
             exp.fulfill()
         }

         controller.handle(task: task)

         wait(for: [exp], timeout: 1)

         XCTAssertEqual(userNotificationCenter.addCallCount, 0)

         XCTAssertNotNil(task.completed)
         XCTAssert(task.completed!)
     }
     */

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
