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

enum BackgroundTaskIdentifiers: String {
    case update = "nl.rijksoverheid.en.background-update"
    case decoyStopKeys = "nl.rijksoverheid.en.background-decoy-stop-keys"
    case decoySequence = "nl.rijksoverheid.en.background-decoy-sequence"
    case decoyRegister = "nl.rijksoverheid.en.background-decoy-register"
}

struct BackgroundTaskConfiguration {
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

    // MARK: - Init

    init(exposureController: ExposureControlling,
         networkController: NetworkControlling,
         configuration: BackgroundTaskConfiguration) {
        self.exposureController = exposureController
        self.configuration = configuration
        self.networkController = networkController
    }

    deinit {
        disposeBag.forEach { $0.cancel() }
    }

    // MARK: - BackgroundControlling

    func scheduleTasks() {
        scheduleUpdate()
        scheduleDecoySequence()
    }

    func handle(task: BGTask) {
        guard let task = task as? BGProcessingTask else {
            return logError("Task is not of type `BGProcessingTask`")
        }
        guard let identifier = BackgroundTaskIdentifiers(rawValue: task.identifier) else {
            return logError("No Handler for: \(task.identifier)")
        }

        switch identifier {
        case .decoySequence:
            handleDecoySequence(task: task)
            scheduleDecoySequence()
        case .decoyRegister:
            handleDecoyRegister(task: task)
        case .decoyStopKeys:
            handleDecoyStopkeys(task: task)
        case .update:
            handleUpdate(task: task)
            scheduleUpdate()
        }
    }

    // MARK: - Private

    /// Returns the refresh interval in minutes
    private var refreshInterval: TimeInterval {
        return receivedRefreshInterval ?? defaultRefreshInterval
    }

    private let defaultRefreshInterval: TimeInterval = 60 // minutes
    private var receivedRefreshInterval: TimeInterval?
    private let exposureController: ExposureControlling
    private let networkController: NetworkControlling
    private let configuration: BackgroundTaskConfiguration
    private var disposeBag = Set<AnyCancellable>()

    // MARK: - Decoy Scheduling

    /// Review document at https://github.com/minvws/nl-covid19-notification-app-coordination-private/blob/master/architecture/Traffic%20Analysis%20Mitigation%20With%20Decoys.md
    ///
    /// Sequence of scheduling a decoy
    ///
    /// 1. Every day at 1:00 AM, determine whether a decoy traffic sequence is to be scheduled with a probability of Appconfig.decoyProbability (taken from the `/appconfig` response). This is a value between `0` and `1`. The default value when the app has not successfully retrieved Appconfig yet, is the aforementioned `0.00118`. So take a number `R = random_float(0..1)` and only if `R < Appconfig.decoyProbability`, continue with the next step. Otherwise, stop this procedure and wait for the next round (in 24 hours).
    /// 2. Pick a random time decoyTime between `7AM` and `7PM` of the current day. (Note: we do not take into account Sundays and holidays that may have no genuine upload traffic since health authority offices may be closed.)
    /// 3. Schedule a decoy transmission job (simulating a `/register` call) at decoyTime.
    /// 4. Pick a random number of seconds `decoyInterval = random_int(5..900)` (interval between first and second decoy call).
    /// 5. Schedule a second decoy transmission job (simulating a `/postkeys` call) for time decoyTime + decoyInterval.

    private func scheduleDecoySequence() {
        // The decoy sequence should be run at 1am.
        guard let date = date(hour: 1, minute: 0) else {
            return logError("Error creating date")
        }

        schedule(identifier: BackgroundTaskIdentifiers.decoySequence, date: date)
    }

    private func scheduleDecoyRegister(task: BGProcessingTask) {
        let hour = Int.random(in: configuration.decoyHourRange)
        let minute = Int.random(in: configuration.decoyMinuteRange)

        guard let date = date(hour: hour, minute: minute) else {
            task.setTaskCompleted(success: false)
            return logError("Error creating date")
        }

        schedule(identifier: .decoyRegister, date: date, requiresNetworkConnectivity: true) { result in
            task.setTaskCompleted(success: result)
        }
    }

    private func scheduleDecoyStopKeys(task: BGProcessingTask) {
        let delay = Double(Int.random(in: configuration.decoyDelayRange))
        let date = Date().addingTimeInterval(delay)

        schedule(identifier: .decoyRegister, date: date, requiresNetworkConnectivity: true) { result in
            task.setTaskCompleted(success: result)
        }
    }

    private func handleDecoySequence(task: BGProcessingTask) {
        func execute(decoyProbability: Float) {
            let r = Float.random(in: configuration.decoyProbabilityRange)
            guard r < decoyProbability else {
                task.setTaskCompleted(success: true)
                return logDebug("Not scheduling decoy \(r) < \(decoyProbability)")
            }
            scheduleDecoyRegister(task: task)
        }

        exposureController
            .getDecoyProbability()
            .sink(receiveCompletion: { _ in
            }, receiveValue: { value in
                execute(decoyProbability: value)
            })
            .store(in: &disposeBag)
    }

    private func handleDecoyRegister(task: BGProcessingTask) {
        exposureController.requestLabConfirmationKey { _ in
            // Note: We ignore the response
            self.logDebug("Decoy `/register` complete")
            self.scheduleDecoyStopKeys(task: task)
        }

        // Handle running out of time
        task.expirationHandler = {
            // TODO: We need to actually stop the `requestLabConfirmationKey` request
        }
    }

    private func handleDecoyStopkeys(task: BGProcessingTask) {
        let cancellable = exposureController
            .getPadding()
            .flatMap { padding in
                self.networkController
                    .stopKeys(padding: padding)
                    .mapError { $0.asExposureDataError }
            }.sink(receiveCompletion: { _ in
                // Note: We ignore the response
                self.logDebug("Decoy `/postkeys` complete")
                task.setTaskCompleted(success: true)
            }, receiveValue: { _ in })

        // Handle running out of time
        task.expirationHandler = {
            cancellable.cancel()
        }
    }

    // MARK: - Background Updates

    private func scheduleUpdate() {
        guard ENManager.authorizationStatus == .authorized else {
            return logError("`ENManager.authorizationStatus` not authorized")
        }
        let date = Date(timeIntervalSinceNow: refreshInterval * 60)

        schedule(identifier: .update, date: date, requiresNetworkConnectivity: true)
    }

    private func handleUpdate(task: BGProcessingTask) {
        let sequence: [() -> AnyPublisher<(), ExposureDataError>] = [
            exposureController.updateWhenRequired,
            exposureController.processPendingUploadRequests
        ]

        logDebug("--- Start Background Updating ---")

        // Combine all processes together, the sequence will be exectued in the order they are in the `sequence` array
        let cancellable = Publishers.Sequence<[AnyPublisher<(), ExposureDataError>], ExposureDataError>(sequence: sequence.map { $0() })
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

    private func getAndSetRefreshInterval() {
        exposureController
            .getAppRefreshInterval()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] value in self?.receivedRefreshInterval = TimeInterval(value) })
            .store(in: &disposeBag)
    }

    private func date(hour: Int, minute: Int) -> Date? {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)
    }

    private func schedule(identifier: BackgroundTaskIdentifiers, date: Date, requiresNetworkConnectivity: Bool = false, completion: ((Bool) -> ())? = nil) {
        func execute() {
            let request = BGProcessingTaskRequest(identifier: identifier.rawValue)
            request.requiresNetworkConnectivity = requiresNetworkConnectivity
            request.earliestBeginDate = date

            do {
                try BGTaskScheduler.shared.submit(request)
                logDebug("Scheduled `\(identifier)` ✅")
                completion?(true)
            } catch {
                logError("Could not schedule \(identifier): \(error)")
                completion?(true)
            }
        }

        BGTaskScheduler.shared.getPendingTaskRequests { tasks in
            guard tasks.filter({ $0.identifier == identifier.rawValue }).isEmpty else {
                completion?(true)
                return
            }
            execute()
        }
    }
}
