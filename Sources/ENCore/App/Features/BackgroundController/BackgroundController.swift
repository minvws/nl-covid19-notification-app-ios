/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import BackgroundTasks
import Combine
import ExposureNotification
import Foundation

/// BackgroundController
///
/// Note: To tests this implementaion, run the application on device. Put a breakpoint at the `print("🐞 Scheduled Update")` statement and background the application.
/// When the breakpoint is hit put this into the console `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"nl.rijksoverheid.en.background-update"]`
/// and resume the application. The background task will be run.
final class BackgroundController: BackgroundControlling {

    private struct Constants {
        static let backgroundTask = "nl.rijksoverheid.en.background-update"
    }

    // MARK: - Init

    init(exposureController: ExposureControlling) {
        self.exposureController = exposureController
    }

    deinit {
        disposeBag.forEach { $0.cancel() }
    }

    // MARK: - BackgroundControlling

    func scheduleTasks() {
        scheduleUpdate()
    }

    func handle(task: BGTask) {
        switch task.identifier {
        case Constants.backgroundTask:
            guard let task = task as? BGProcessingTask else {
                return print("🔥 Task is not of type `BGProcessingTask`")
            }
            handleUpdate(task: task)
            scheduleUpdate()
        default:
            print("🔥 No Handler for: \(task.identifier)")
        }
    }

    // MARK: - Private

    private let exposureController: ExposureControlling
    private var disposeBag = Set<AnyCancellable>()

    private func scheduleUpdate() {
        guard ENManager.authorizationStatus == .authorized else {
            return print("🔥 `ENManager.authorizationStatus` not authorized")
        }
        let request = BGProcessingTaskRequest(identifier: Constants.backgroundTask)
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // TODO: Should be updated with values from AppConfig

        do {
            try BGTaskScheduler.shared.submit(request)
            print("🐞 Scheduled Update")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }

    private func handleUpdate(task: BGProcessingTask) {
        let sequence = [
            exposureController.updateWhenRequired(),
            exposureController.processPendingUploadRequests()
        ]

        // Combine all processes together, the sequence will be exectued in the order they are in the `sequence` array
        let cancellable = Publishers.Sequence<[AnyPublisher<(), ExposureDataError>], ExposureDataError>(sequence: sequence)
            // execute them on by one
            .flatMap(maxPublishers: .max(1)) { $0 }
            // wait until all of them are done and collect them in an array
            // subsicbe to the result
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    print("🐞 Finished Background Updating")
                    task.setTaskCompleted(success: true)
                case let .failure(error):
                    print("🔥 Error completiting sequence \(error.localizedDescription)")
                    task.setTaskCompleted(success: false)
                }
            }, receiveValue: { _ in
                print("🐞 Completed task")
            })

        // Handle running out of time
        task.expirationHandler = {
            cancellable.cancel()
        }

        cancellable.store(in: &disposeBag)
    }
}
