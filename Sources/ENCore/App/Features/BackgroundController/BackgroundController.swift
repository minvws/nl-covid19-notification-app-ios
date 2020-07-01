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
final class BackgroundController: BackgroundControlling, Logging {

    private struct Constants {
        static let backgroundUpdateTask = "nl.rijksoverheid.en.background-update"
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
        case Constants.backgroundUpdateTask:
            guard let task = task as? BGProcessingTask else {
                return logError("Task is not of type `BGProcessingTask`")
            }
            handleUpdate(task: task)
            scheduleUpdate()
        default:
            logError(" No Handler for: \(task.identifier)")
        }
    }

    // MARK: - Private

    private let exposureController: ExposureControlling
    private var disposeBag = Set<AnyCancellable>()

    private func scheduleUpdate() {
        guard ENManager.authorizationStatus == .authorized else {
            return logError("`ENManager.authorizationStatus` not authorized")
        }
        let request = BGProcessingTaskRequest(identifier: Constants.backgroundUpdateTask)
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // TODO: Should be updated with values from AppConfig

        do {
            try BGTaskScheduler.shared.submit(request)
            logDebug("Scheduled Update")
        } catch {
            logWarning("Could not schedule app refresh: \(error)")
        }
    }

    private func handleUpdate(task: BGProcessingTask) {
        let sequence: [() -> AnyPublisher<(), ExposureDataError>] = [
            exposureController.updateWhenRequired,
            exposureController.processPendingUploadRequests
        ]

        // Combine all processes together, the sequence will be exectued in the order they are in the `sequence` array
        let cancellable = Publishers.Sequence<[AnyPublisher<(), ExposureDataError>], ExposureDataError>(sequence: sequence.compactMap { $0() })
            // execute them on by one
            .flatMap(maxPublishers: .max(1)) { $0 }
            // wait until all of them are done and collect them in an array
            // subsicbe to the result
            .sink(receiveCompletion: { [weak self] result in
                switch result {
                case .finished:
                    self?.logDebug("Finished Background Updating")
                    task.setTaskCompleted(success: true)
                case let .failure(error):
                    self?.logError("Error completiting sequence \(error.localizedDescription)")
                    task.setTaskCompleted(success: false)
                }
            }, receiveValue: { [weak self] _ in
                self?.logDebug("Completed task")
            })

        // Handle running out of time
        task.expirationHandler = {
            cancellable.cancel()
        }

        cancellable.store(in: &disposeBag)
    }
}
