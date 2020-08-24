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
                .isAppDectivated()
                .sink(receiveCompletion: { _ in
                    // Do nothing
                }, receiveValue: { (isDeactivated: Bool) in
                    if isDeactivated {
                        self.removeAllTasks()
                    } else {
                        self.scheduleRefresh()
                        self.scheduleDecoySequence()
                    }
                }).store(in: &self.disposeBag)
        }

        operationQueue.async(execute: scheduleTasks)
    }

    func handle(task: BGTask) {
        guard let task = task as? BGProcessingTask else {
            return logError("Task is not of type `BGProcessingTask`")
        }
        guard let identifier = BackgroundTaskIdentifiers(rawValue: task.identifier.replacingOccurrences(of: bundleIdentifier + ".", with: "")) else {
            return logError("No Handler for: \(task.identifier)")
        }
        logDebug("Handling: \(identifier)")

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

    // MARK: - Refresh

    private func scheduleRefresh() {
        guard let date = date(hour: 1, minute: 0) else {
            return logError("Error creating date")
        }
        schedule(identifier: .refresh, date: date)
    }

    private func refresh(task: BGProcessingTask) {
        let sequence: [() -> AnyPublisher<(), Never>] = [
            processUpdate,
            processENStatusCheck
        ]

        let cancellable = Publishers.Sequence<[AnyPublisher<(), Never>], Never>(sequence: sequence.map { $0() })
            .flatMap { $0 }
            .collect()
            .sink(receiveCompletion: { [weak self] result in
                switch result {
                case .finished:
                    self?.logDebug("--- Finished Background Refresh ---")
                    task.setTaskCompleted(success: true)
                case let .failure(error):
                    self?.logError("Error completiting sequence \(error.localizedDescription)")
                    task.setTaskCompleted(success: false)
                }
            }, receiveValue: { [weak self] _ in
                self?.logDebug("Completed task")
            })

        cancellable.store(in: &disposeBag)

        // Handle running out of time
        task.expirationHandler = {
            cancellable.cancel()
        }
    }

    private func processUpdate() -> AnyPublisher<(), Never> {
        return Deferred {
            Future { [weak self] promise in
                guard let strongSelf = self else {
                    promise(.success(()))
                    return
                }
                guard strongSelf.exposureManager.authorizationStatus == .authorized else {
                    promise(.success(()))
                    return strongSelf.logError("`ENManager.authorizationStatus` not authorized")
                }

                let sequence: [() -> AnyPublisher<(), ExposureDataError>] = [
                    strongSelf.exposureController.updateWhenRequired,
                    strongSelf.exposureController.processPendingUploadRequests
                ]

                strongSelf.logDebug("--- Start Background Updating ---")

                // Combine all processes together, the sequence will be exectued in the order they are in the `sequence` array
                let cancellable = Publishers.Sequence<[AnyPublisher<(), ExposureDataError>], ExposureDataError>(sequence: sequence.map { $0() })
                    // execute them one by one
                    .flatMap(maxPublishers: .max(1)) { $0 }
                    // collect them
                    .collect()
                    // notify the user if required
                    .handleEvents(receiveCompletion: { [weak strongSelf] _ in
                        // FIXME: disabled for `57704`
                        // self?.exposureController.notifyUserIfRequired()
                        strongSelf?.logDebug("Should call `notifyUserIfRequired` - disabled for `57704`")
                    })
                    .sink(receiveCompletion: { [weak strongSelf] result in
                        switch result {
                        case .finished:
                            strongSelf?.logDebug("--- Finished Background Updating ---")
                        case let .failure(error):
                            strongSelf?.logError("Error completiting sequence \(error.localizedDescription)")
                        }
                        promise(.success(()))
                    }, receiveValue: { [weak self] _ in
                        self?.logDebug("Completed task")
                    })

                cancellable.store(in: &strongSelf.disposeBag)
            }
        }.eraseToAnyPublisher()
    }

    private func processENStatusCheck() -> AnyPublisher<(), Never> {
        return Deferred {
            Future { [weak self] promise in
                guard let strongSelf = self else {
                    return promise(.success(()))
                }
                defer {
                    strongSelf.exposureController.setLastEndStatusCheckDate(Date())
                }

                let status = strongSelf.exposureManager.getExposureNotificationStatus()
                guard status != .active else {
                    promise(.success(()))
                    return strongSelf.logDebug("`handleENStatusCheck` skipped as it is `active`")
                }
                guard let lastENStatusCheck = strongSelf.exposureController.lastENStatusCheckDate else {
                    return strongSelf.logDebug("No `lastENStatusCheck`, skipping")
                }
                let timeInterval = TimeInterval(60 * 60 * 24) // 24 hours

                guard lastENStatusCheck.advanced(by: timeInterval) < Date() else {
                    promise(.success(()))
                    return strongSelf.logDebug("`handleENStatusCheck` skipped as it hasn't been 24h")
                }
                strongSelf.logDebug("EN Status Check: triggering notification \(status)")

                strongSelf.userNotificationCenter.getAuthorizationStatus { status in
                    guard status == .authorized else {
                        promise(.success(()))
                        return strongSelf.logError("Not authorized to post notifications")
                    }

                    let content = UNMutableNotificationContent()
                    content.body = .notificationEnStatusNotActive
                    content.sound = .default
                    content.badge = 0

                    let request = UNNotificationRequest(identifier: PushNotificationIdentifier.enStatusDisabled.rawValue,
                                                        content: content,
                                                        trigger: nil)

                    strongSelf.userNotificationCenter.add(request) { error in
                        guard let error = error else {
                            return promise(.success(()))
                        }
                        strongSelf.logError("Error posting notification: \(error.localizedDescription)")
                        promise(.success(()))
                    }
                }
            }
        }.eraseToAnyPublisher()
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
                logError("Could not schedule \(identifier): \(error.localizedDescription)")
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

    private func removeAllTasks() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
}
