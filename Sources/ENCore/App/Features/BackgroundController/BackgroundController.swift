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

struct BackgroundTaskIdentifiers {
    static let decoySequence = "nl.rijksoverheid.en.background-decoy-sequence"
    static let decoy = "nl.rijksoverheid.en.background-decoy"
    static let update = "nl.rijksoverheid.en.background-update"
}

struct Configuration {
    let decoyProbabilityRange: Range<Float>
    let decoyHourRange: ClosedRange<Int>
    let decoyMinuteRange: ClosedRange<Int>
    let decoyDelayRange: ClosedRange<Int>
}

/// BackgroundController
///
/// Note: To tests this implementaion, run the application on device. Put a breakpoint at the `print("🐞 Scheduled Update")` statement and background the application.
/// When the breakpoint is hit put this into the console `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"nl.rijksoverheid.en.background-update"]`
/// and resume the application. The background task will be run.
final class BackgroundController: BackgroundControlling, Logging {

    private struct Constants {
        static let defaultDecoyProbability: Float = 0.00118
    }

    // MARK: - Init

    init(exposureController: ExposureControlling, configuration: Configuration) {
        self.exposureController = exposureController
        self.configuration = configuration
    }

    deinit {
        disposeBag.forEach { $0.cancel() }
    }

    // MARK: - BackgroundControlling

    func scheduleTasks() {
        scheduleUpdate()
        scheduleDeocySequence()
    }

    func handle(task: BGTask) {
        guard let task = task as? BGProcessingTask else {
            return logError("Task is not of type `BGProcessingTask`")
        }
        switch task.identifier {
        case BackgroundTaskIdentifiers.decoySequence:
            handleDecoySequence(task: task)
        case BackgroundTaskIdentifiers.decoy:
            handleDecoy(task: task)
        case BackgroundTaskIdentifiers.update:
            handleUpdate(task: task)
            scheduleUpdate()
        default:
            logError(" No Handler for: \(task.identifier)")
        }
    }

    // MARK: - Private

    private let exposureController: ExposureControlling
    private let configuration: Configuration
    private var disposeBag = Set<AnyCancellable>()

    private func scheduleDeocySequence() {
        guard let date = date(hour: 1, minute: 0) else {
            return logError("Error creating date")
        }

        let request = BGProcessingTaskRequest(identifier: BackgroundTaskIdentifiers.decoySequence)
        request.earliestBeginDate = date

        do {
            try BGTaskScheduler.shared.submit(request)
            logDebug("`scheduleDeocySequence` ✅")
        } catch {
            logError("Could not schedule decoy sequence: \(error)")
        }
    }

    private func handleDecoySequence(task: BGProcessingTask) {
        let r = Float.random(in: configuration.decoyProbabilityRange)
        let decoyProbability = Constants.defaultDecoyProbability
        guard r < decoyProbability else {
            task.setTaskCompleted(success: true)
            return logDebug("Not scheduling decoy \(r) < \(decoyProbability)")
        }
        scheduleDecoy(task: task)
    }

    private func scheduleDecoy(task: BGProcessingTask) {
        let hour = Int.random(in: configuration.decoyHourRange)
        let minute = Int.random(in: configuration.decoyMinuteRange)

        guard let date = date(hour: hour, minute: minute) else {
            task.setTaskCompleted(success: false)
            return logError("Error creating date")
        }

        let request = BGProcessingTaskRequest(identifier: BackgroundTaskIdentifiers.decoy)
        request.earliestBeginDate = date
        request.requiresNetworkConnectivity = true

        do {
            try BGTaskScheduler.shared.submit(request)
            logDebug("`scheduleDecoy` ✅")
            task.setTaskCompleted(success: true)
        } catch {
            logError("Could not schedule decoy: \(error)")
            task.setTaskCompleted(success: false)
        }
    }

    private func handleDecoy(task: BGProcessingTask) {
        // TODO: `requestLabConfirmationKey` & `requestStopKeys` should return Publishers so we can cancel the requests
        var cancelled = false

        exposureController.requestLabConfirmationKey { _ in
            // Note: We ignore the response
            self.logDebug("Decoy `/register` complete")
        }

        let delay = Double(Int.random(in: configuration.decoyDelayRange))
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.exposureController.requestStopKeys { _ in
                // Note: We ignore the response
                self.logDebug("Decoy `/postkeys` complete")
                if !cancelled {
                    task.setTaskCompleted(success: true)
                }
            }
        }

        // Handle running out of time
        task.expirationHandler = {
            cancelled = true
        }
    }

    private func scheduleUpdate() {
        guard ENManager.authorizationStatus == .authorized else {
            return logError("`ENManager.authorizationStatus` not authorized")
        }
        let request = BGProcessingTaskRequest(identifier: BackgroundTaskIdentifiers.update)
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: refreshInterval * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            logDebug("`scheduleUpdate` ✅")
        } catch {
            logError("Could not schedule app refresh: \(error)")
        }
    }

    private func handleUpdate(task: BGProcessingTask) {
        let sequence: [() -> AnyPublisher<(), ExposureDataError>] = [
            exposureController.updateWhenRequired,
            exposureController.processPendingUploadRequests
        ]

        logDebug("--- Start Background Updating ---")

        // Combine all processes together, the sequence will be exectued in the order they are in the `sequence` array
        let cancellable = Publishers.Sequence<[AnyPublisher<(), ExposureDataError>], ExposureDataError>(sequence: sequence.map { $0() })
            // execute them on by one
        let cancellable = Publishers.Sequence<[AnyPublisher<(), ExposureDataError>], ExposureDataError>(sequence: sequence.compactMap { $0() })
            // execute them one by one
            .flatMap(maxPublishers: .max(1)) { $0 }
            // collect them
            .collect()
            // notify the user if required
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.exposureController.notifyUserIfRequired()
            })
            .sink(receiveCompletion: { [weak self] result in
                switch result {
                case .finished:
                    self?.logDebug("--- Finished Background Updating ---")
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

    private let defaultRefreshInterval: TimeInterval = 60 // minutes
    private func date(hour: Int, minute: Int) -> Date? {
    private var receivedRefreshInterval: TimeInterval?

    /// Returns the refresh interval in minutes
    private var refreshInterval: TimeInterval {
        return receivedRefreshInterval ?? defaultRefreshInterval
        var components = DateComponents()
    }

    private func getAndSetRefreshInterval() {
        exposureController
        components.hour = hour
            .getAppRefreshInterval()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] value in self?.receivedRefreshInterval = TimeInterval(value) })
            .store(in: &disposeBag)
        components.minute = minute
        return Calendar.current.date(from: components)
    }
}
