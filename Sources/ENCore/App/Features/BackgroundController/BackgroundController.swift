/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import BackgroundTasks
import Foundation

/// BackgroundController
///
/// Note: To tests this implementaion, run the application on device. Put a breakpoint at the `print("Done")` statement and background the application.
/// When the breakpoint is hit put this into the console `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"nl.rijksoverheid.en.refersh"]`
/// and resume the application. The background task will be run.
final class BackgroundController: BackgroundControlling {

    private struct Constants {
        static let backgroundTask = "nl.rijksoverheid.en.background_task"
    }

    // MARK: - Init

    init(exposureController: ExposureControlling) {
        self.exposureController = exposureController
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
        default:
            print("🔥 No Handler for: \(task.identifier)")
        }
    }

    // MARK: - Private

    private let exposureController: ExposureControlling

    private func scheduleUpdate() {
        let request = BGAppRefreshTaskRequest(identifier: Constants.backgroundTask)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // Fetch no earlier than 15 minutes from now

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
        print("🐞 Done")
    }

    private func handleUpdate(task: BGProcessingTask) {
        scheduleUpdate()

        // TODO: Order of operations `Refresh`, `Upload Pending Requests`, `Cleanup`

        task.expirationHandler = {
            // TODO: `exposureController.fetchAndProcessExposureKeySets` should be cancelled
            print("🔥 Task should be cancelled")
        }

        exposureController.fetchAndProcessExposureKeySets {
            task.setTaskCompleted(success: true)
            print("🐞 Fetched & Processed Exposure Keys")
        }
    }
}
