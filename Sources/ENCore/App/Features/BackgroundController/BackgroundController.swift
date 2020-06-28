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
        static let clean = "nl.rijksoverheid.en.clean"
        static let refresh = "nl.rijksoverheid.en.refersh"
    }

    // MARK: - Init

    init(exposureController: ExposureControlling) {
        self.exposureController = exposureController
    }

    // MARK: - BackgroundControlling

    func scheduleTasks() {
        scheduleRefresh()
        scheduleDatabaseCleaningIfNeeded()
    }

    func handle(task: BGTask) {
        switch task.identifier {
        case Constants.clean:
            guard let task = task as? BGProcessingTask else {
                return print("🔥 Task is not of type `BGProcessingTask`")
            }
            handleClean(task: task)
        case Constants.refresh:
            guard let task = task as? BGAppRefreshTask else {
                return print("🔥 Task is not of type `BGAppRefreshTask`")
            }
            handleRefresh(task: task)
        default:
            print("🔥 No Handler for: \(task.identifier)")
        }
    }

    // MARK: - Private

    private let exposureController: ExposureControlling

    private func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Constants.refresh)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // Fetch no earlier than 15 minutes from now

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
        print("🐞 Done")
    }

    private func scheduleDatabaseCleaningIfNeeded() {
        // TODO:
    }

    private func handleRefresh(task: BGAppRefreshTask) {
        scheduleRefresh()

        task.expirationHandler = {
            // TODO: `exposureController.fetchAndProcessExposureKeySets` should be cancelled
            print("🔥 Task should be cancelled")
        }

        exposureController.fetchAndProcessExposureKeySets {
            task.setTaskCompleted(success: true)
            print("🐞 Fetched & Processed Exposure Keys")
        }
    }

    private func handleClean(task: BGProcessingTask) {
        // TODO:
    }
}
