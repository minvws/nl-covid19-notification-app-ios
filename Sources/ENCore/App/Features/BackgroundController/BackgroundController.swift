/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import BackgroundTasks
import Combine
import ENFoundation
import ExposureNotification
import Foundation
import UserNotifications

enum BackgroundTaskIdentifiers: String {
    case refresh = "exposure-notification"
    case decoyStopKeys = "background-decoy-stop-keys"
    case decoySequence = "background-decoy-sequence"
    case decoyRegister = "background-decoy-register"
}

struct BackgroundTaskConfiguration {
    let decoyProbabilityRange: Range<Float>
    let decoyHourRange: ClosedRange<Int>
    let decoyMinuteRange: ClosedRange<Int>
    let decoyDelayRangeLowerBound: ClosedRange<Int>
    let decoyDelayRangeUpperBound: ClosedRange<Int>
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
         configuration: BackgroundTaskConfiguration,
         exposureManager: ExposureManaging,
         userNotificationCenter: UserNotificationCenter,
         bundleIdentifier: String) {
        self.exposureController = exposureController
        self.configuration = configuration
        self.networkController = networkController
        self.exposureManager = exposureManager
        self.userNotificationCenter = userNotificationCenter
        self.bundleIdentifier = bundleIdentifier
    }

    deinit {
        disposeBag.forEach { $0.cancel() }
    }

    // MARK: - BackgroundControlling

    func scheduleTasks() {
        let scheduleTasks: () -> () = {
            self.exposureController
                .isAppDeactivated()
                .sink(receiveCompletion: { _ in
                    // Do nothing
                }, receiveValue: { (isDeactivated: Bool) in
                    if isDeactivated {
                        self.logDebug("Background: ExposureController is deactivated - Removing all tasks")
                        self.removeAllTasks()
                    } else {
                        self.logDebug("Background: ExposureController is activated - Schedule refresh and decoy")
                        self.scheduleRefresh()
                        self.scheduleDecoySequence()
                    }
                }).store(in: &self.disposeBag)
        }

        operationQueue.async(execute: scheduleTasks)
    }

    func handle(task: BGTask) {
        LogHandler.setup()

        guard let task = task as? BGProcessingTask else {
            return logError("Background: Task is not of type `BGProcessingTask`")
        }
        guard let identifier = BackgroundTaskIdentifiers(rawValue: task.identifier.replacingOccurrences(of: bundleIdentifier + ".", with: "")) else {
            return logError("Background: No Handler for: \(task.identifier)")
        }
        logDebug("Background: Handling task \(identifier)")

        let handleTask: () -> () = {
            switch identifier {
            case .decoySequence:
                self.handleDecoySequence(task: task)
                self.scheduleDecoySequence()
            case .decoyRegister:
                self.handleDecoyRegister(task: task)
            case .decoyStopKeys:
                self.handleDecoyStopkeys(task: task)
            case .refresh:
                self.refresh(task: task)
                self.scheduleRefresh()
            }
        }

        operationQueue.async(execute: handleTask)
    }

    // MARK: - Private

    /// Returns the refresh interval in minutes
    private var refreshInterval: TimeInterval {
        return receivedRefreshInterval ?? defaultRefreshInterval
    }

    private let defaultRefreshInterval: TimeInterval = 60 // minutes
    private var receivedRefreshInterval: TimeInterval?

    private let exposureManager: ExposureManaging
    private let userNotificationCenter: UserNotificationCenter
    private let exposureController: ExposureControlling
    private let networkController: NetworkControlling
    private let configuration: BackgroundTaskConfiguration
    private var disposeBag = Set<AnyCancellable>()
    private let bundleIdentifier: String
    private let operationQueue = DispatchQueue(label: "nl.rijksoverheid.en.background-processing")

    // MARK: - Decoy Scheduling

    /// Review document at https://github.com/minvws/nl-covid19-notification-app-coordination-private/blob/master/architecture/Traffic%20Analysis%20Mitigation%20With%20Decoys.md
    ///
    /// Sequence of scheduling a decoy
    ///
    /// 1. Every day at 1:00 AM, determine whether a decoy traffic sequence is to be scheduled with a probability of Appconfig.decoyProbability (taken from the `/appconfig` response). This is a value between `0` and `1`. The default value when the app has not successfully retrieved Appconfig yet, is the aforementioned `0.00118`. So take a number `R = random_float(0..1)` and only if `R < Appconfig.decoyProbability`, continue with the next step. Otherwise, stop this procedure and wait for the next round (in 24 hours).
    /// 2. Pick a random time decoyTime between `00:00` and `24:00` of the current day. (Note: we do not take into account Sundays and holidays that may have no genuine upload traffic since health authority offices may be closed.)
    /// 3. Schedule a decoy transmission job (simulating a `/register` call) at decoyTime.
    /// 4a. If `random_int(0..10) == 0: decoyInterval = random_int(1..(24*60*60)) `   (i.e. with chance of 10%, decoyInterval is between 1 sec and 24 hours)
    /// 4b. Otherwise: `decoyInterval = random_int(1..900)`      (i.e. with chance of 90%, decoyInterval is between 1 sec and 15 minutes)
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
        let percentage = Int.random(in: 0 ... 10)
        let delay = percentage == 0 ? Int.random(in: configuration.decoyDelayRangeLowerBound) : Int.random(in: configuration.decoyDelayRangeUpperBound)
        let date = Date().addingTimeInterval(Double(delay))

        schedule(identifier: .decoyRegister, date: date, requiresNetworkConnectivity: true) { result in
            task.setTaskCompleted(success: result)
        }
    }

    private func handleDecoySequence(task: BGProcessingTask) {
        func execute(decoyProbability: Float) {
            let r = Float.random(in: configuration.decoyProbabilityRange)
            guard r < decoyProbability else {
                task.setTaskCompleted(success: true)
                return logDebug("Not scheduling decoy \(r) >= \(decoyProbability)")
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

    // MARK: - Refresh

    private func scheduleRefresh() {
        let timeInterval = refreshInterval * 60
        let date = Date().addingTimeInterval(timeInterval)

        schedule(identifier: .refresh, date: date, requiresNetworkConnectivity: true)
    }

    private func refresh(task: BGProcessingTask) {
        let sequence: [() -> AnyPublisher<(), Never>] = [
            { self.exposureController.activate(inBackgroundMode: true) },
            processUpdate,
            processENStatusCheck
        ]

        logDebug("Background: starting refresh task")

        let cancellable = Publishers.Sequence<[AnyPublisher<(), Never>], Never>(sequence: sequence.map { $0() })
            .flatMap(maxPublishers: .max(1)) { $0 }
            .collect()
            .sink(receiveCompletion: { [weak self] result in
                switch result {
                case .finished:
                    self?.logDebug("--- Finished Background Refresh ---")
                    task.setTaskCompleted(success: true)
                case let .failure(error):
                    self?.logError("Background: Error completing sequence \(error.localizedDescription)")
                    task.setTaskCompleted(success: false)
                }
            }, receiveValue: { [weak self] _ in
                self?.logDebug("Background: Completed refresh task")
            })

        cancellable.store(in: &disposeBag)

        // Handle running out of time
        task.expirationHandler = {
            cancellable.cancel()
        }
    }

    private func processUpdate() -> AnyPublisher<(), Never> {
        logDebug("Background: Process Update Function Called")

        return exposureController
            .updateAndProcessPendingUploads()
            .replaceError(with: ())
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.logDebug("Background: Process Update Completed")
                    case .failure:
                        self?.logDebug("Background: Process Update Failed")
                    }
                },
                receiveCancel: { [weak self] in self?.logDebug("Background: Process Update Cancelled") }
            )
            .eraseToAnyPublisher()
    }

    private func processENStatusCheck() -> AnyPublisher<(), Never> {
        logDebug("Background: Exposure Notification Status Check Function Called")

        return exposureController
            .exposureNotificationStatusCheck()
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.logDebug("Background: Exposure Notification Status Check Completed")
                    case .failure:
                        self?.logDebug("Background: Exposure Notification Status Check Failed")
                    }
                },
                receiveCancel: { [weak self] in self?.logDebug("Background: Exposure Notification Status Check Cancelled") }
            )
            .eraseToAnyPublisher()
    }

    // Returns a Date with the specified hour and minute, for the next day
    // E.g. date(hour: 1, minute: 0) returns 1:00 am for the next day
    private func date(hour: Int, minute: Int) -> Date? {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else {
            return nil
        }

        var components = calendar.dateComponents([.day, .month, .year, .timeZone], from: tomorrow)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)
    }

    private func schedule(identifier: BackgroundTaskIdentifiers, date: Date? = nil, requiresNetworkConnectivity: Bool = false, completion: ((Bool) -> ())? = nil) {
        let backgroundTaskIdentifier = bundleIdentifier + "." + identifier.rawValue

        logDebug("Background: Scheduling `\(identifier)` for earliestDate \(String(describing: date)), requiresNetwork: \(requiresNetworkConnectivity)")

        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)

        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = requiresNetworkConnectivity
        request.earliestBeginDate = date

        do {
            try BGTaskScheduler.shared.submit(request)
            logDebug("Background: Scheduled `\(identifier)` ✅")
            completion?(true)
        } catch {
            logError("Background: Could not schedule \(backgroundTaskIdentifier): \(error.localizedDescription)")
            completion?(true)
        }
    }

    private func removeAllTasks() {
        logDebug("Background: Removing all scheduled tasks")
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
}
