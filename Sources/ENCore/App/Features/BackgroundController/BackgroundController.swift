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
import RxSwift
import UserNotifications

enum BackgroundTaskIdentifiers: String {
    case refresh = "exposure-notification"
    case decoyStopKeys = "background-decoy-stop-keys"
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
/// Note: To tests this implementaion, run the application on device. Put a breakpoint at the `logDebug("Background: Scheduled `\(identifier)` ✅")` statement and background the application.
/// When the breakpoint is hit put this into the console `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"nl.rijksoverheid.en.exposure-notification"]`
/// and resume the application. The background task will be run.
final class BackgroundController: BackgroundControlling, Logging {

    // MARK: - Init

    init(exposureController: ExposureControlling,
         networkController: NetworkControlling,
         configuration: BackgroundTaskConfiguration,
         exposureManager: ExposureManaging,
         dataController: ExposureDataControlling,
         userNotificationCenter: UserNotificationCenter,
         taskScheduler: TaskScheduling,
         bundleIdentifier: String,
         randomizer: RandomizerProtocol) {
        self.exposureController = exposureController
        self.configuration = configuration
        self.networkController = networkController
        self.exposureManager = exposureManager
        self.dataController = dataController
        self.userNotificationCenter = userNotificationCenter
        self.taskScheduler = taskScheduler
        self.bundleIdentifier = bundleIdentifier
        self.randomizer = randomizer
    }

    deinit {
        disposeBag.forEach { $0.cancel() }
    }

    // MARK: - BackgroundControlling

    func scheduleTasks() {

        let scheduleTasks: () -> () = {
            self.exposureController
                .isAppDeactivated()
                .subscribe { isDeactivated in
                    if isDeactivated {
                        self.logDebug("Background: ExposureController is deactivated - Removing all tasks")
                        self.removeAllTasks()
                    } else {
                        self.logDebug("Background: ExposureController is activated - Schedule refresh sequence")
                        self.scheduleRefresh()
                    }
                } onError: { error in
                    self.logDebug("Background: ExposureController activated state result: \(error)")
                    self.logDebug("Background: Scheduling refresh sequence")
                    self.scheduleRefresh()
                }
                .disposed(by: self.rxDisposeBag)
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

    private let taskScheduler: TaskScheduling
    private let exposureManager: ExposureManaging
    private let userNotificationCenter: UserNotificationCenter
    private let exposureController: ExposureControlling
    private let dataController: ExposureDataControlling
    private let networkController: NetworkControlling
    private let configuration: BackgroundTaskConfiguration
    private var disposeBag = Set<AnyCancellable>()
    private var rxDisposeBag = DisposeBag()
    private let bundleIdentifier: String
    private let operationQueue = DispatchQueue(label: "nl.rijksoverheid.en.background-processing")
    private let randomizer: RandomizerProtocol

    private func handleDecoyStopkeys(task: BGProcessingTask) {

        guard isExposureManagerActive else {
            task.setTaskCompleted(success: true)
            logDebug("ExposureManager inactive - Not handling \(task.identifier)")
            return
        }

        self.logDebug("Decoy `/stopkeys` started")
        let disposable = exposureController
            .getPadding()
            .flatMap { padding in
                self.networkController
                    .stopKeys(padding: padding)
                    .subscribe(on: MainScheduler.instance)
                    .catch { error in
                        throw (error as? NetworkError)?.asExposureDataError ?? ExposureDataError.internalError
                    }
            }
            .subscribe { _ in
                // Note: We ignore the response
                self.logDebug("Decoy `/stopkeys` complete")
                task.setTaskCompleted(success: true)
            } onFailure: { _ in
                // Note: We ignore the response
                self.logDebug("Decoy `/stopkeys` complete")
                task.setTaskCompleted(success: true)
            }

        // Handle running out of time
        task.expirationHandler = {
            self.logDebug("Decoy `/stopkeys` expired")
            disposable.dispose()
        }
    }

    ///    When the user opens the app
    ///        if (config.decoyProbability),
    ///        rand(1-x) seconds after the manifest run ‘register decoy’ in the foreground,
    ///        Schedule the ‘stopkeys’ decoy’ as a normal/regular background task rand(0-15) minutes later (the chance that this bg task works is high, because the user used the app less than x ago)
    ///
    ///     Ensure only 1 decoy per day
    ///     x = the time it typically takes a slow, real user to go from app startup to the ggd code screen.
    ///     y = about 5 minutes (about less, e.g. 250 sec) this param value depends on how long a prioritized task is allowed to run
    func performDecoySequenceIfNeeded() {

        guard self.dataController.canProcessDecoySequence else {
            return self.logDebug("Not running decoy `/register` Process already run today")
        }

        func execute(decoyProbability: Float) {

            let r = self.randomizer.randomFloat(in: configuration.decoyProbabilityRange)
            guard r < decoyProbability else {
                return logDebug("Not running decoy `/register` \(r) >= \(decoyProbability)")
            }

            self.dataController.setLastDecoyProcessDate(currentDate())

            exposureController.requestLabConfirmationKey { _ in

                self.logDebug("Decoy `/register` complete")

                let date = currentDate().addingTimeInterval(
                    TimeInterval(self.randomizer.randomInt(in: 0 ... 900)) // random number between 0 and 15 minutes
                )
                self.schedule(identifier: BackgroundTaskIdentifiers.decoyStopKeys, date: date)
            }
        }

        exposureController
            .getDecoyProbability()
            .delay(.seconds(randomizer.randomInt(in: 1 ... 60)), scheduler: MainScheduler.instance) // random number between 1 and 60 seconds
            .subscribe(onSuccess: { decoyProbability in
                execute(decoyProbability: decoyProbability)
            })
            .disposed(by: rxDisposeBag)
    }

    func removeAllTasks() {
        logDebug("Background: Removing all scheduled tasks")
        taskScheduler.cancelAllTaskRequests()
    }

    // MARK: - Refresh

    private func scheduleRefresh() {
        let timeInterval = refreshInterval * 60
        let date = currentDate().addingTimeInterval(timeInterval)

        schedule(identifier: .refresh, date: date)
    }

    private func refresh(task: BGProcessingTask) {
        let sequence: [() -> AnyPublisher<(), Never>] = [
            { self.exposureController.activate(inBackgroundMode: true) },
            processUpdate,
            processENStatusCheck,
            appUpdateRequiredCheck,
            updateTreatmentPerspective,
            processLastOpenedNotificationCheck,
            processDecoyRegisterAndStopKeys
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

    private func appUpdateRequiredCheck() -> AnyPublisher<(), Never> {
        logDebug("Background: App Update Required Check Function Called")

        return exposureController
            .sendNotificationIfAppShouldUpdate()
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.logDebug("Background: App Update Required Check Completed")
                    case .failure:
                        self?.logDebug("Background: App Update Required Check Failed")
                    }
                },
                receiveCancel: { [weak self] in self?.logDebug("Background: App Update Required Check Cancelled") }
            )
            .eraseToAnyPublisher()
    }

    private func updateTreatmentPerspective() -> AnyPublisher<(), Never> {
        logDebug("Background: Update Treatment Perspective Message Function Called")

        return exposureController
            .updateTreatmentPerspective()
            .map { _ in return () }
            .replaceError(with: ())
            .handleEvents(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.logDebug("Background: Update Treatment Perspective Message Completed")
                    case .failure:
                        self?.logDebug("Background: Update Treatment Perspective Message Failed")
                    }
                },
                receiveCancel: { [weak self] in self?.logDebug("Background: Update Treatment Perspective Message Cancelled") }
            )
            .eraseToAnyPublisher()
    }

    private func processLastOpenedNotificationCheck() -> AnyPublisher<(), Never> {
        return exposureController.lastOpenedNotificationCheck()
    }

    ///    Every prioritized background run,
    ///       if (config.decoyProbability) then:
    ///       rand(1-x) seconds after the manifest run ‘register decoy’
    ///       rand(0-y) minutes later, run ‘stopkeys decoy’ (during the prioritized background run)
    ///
    ///    x = the time it typically takes a slow, real user to go from app startup to the ggd code screen.
    ///    Ensure only 1 decoy per day
    ///    y = about 5 minutes (about less, e.g. 250 sec) and/or new param: iOS decoyDelayBetweenRegisterAndUpload (this param value depends on how long a prioritized task is allowed to run)
    private func processDecoyRegisterAndStopKeys() -> AnyPublisher<(), Never> {
        return Deferred {
            Future { promise in

                guard self.isExposureManagerActive else {
                    self.logDebug("ExposureManager inactive - Not handling processDecoyRegisterAndStopKeys")
                    return promise(.success(()))
                }

                guard self.dataController.canProcessDecoySequence else {
                    self.logDebug("Not running decoy `/register` Process already run today")
                    return promise(.success(()))
                }

                func processStopKeys() {
                    self.exposureController
                        .getPadding()
                        .asObservable()
                        .delay(.seconds(self.randomizer.randomInt(in: 1 ... 250)), scheduler: MainScheduler.instance)
                        .flatMap { padding in
                            self.networkController
                                .stopKeys(padding: padding)
                                .catch { error in
                                    throw (error as? NetworkError)?.asExposureDataError ?? ExposureDataError.internalError
                                }
                        }
                        .subscribe(onError: { _ in
                            // Note: We ignore the response
                            self.logDebug("Decoy `/stopkeys` complete")
                            return promise(.success(()))
                        }, onCompleted: {
                            // Note: We ignore the response
                            self.logDebug("Decoy `/stopkeys` complete")
                            return promise(.success(()))
                        })
                        .disposed(by: self.rxDisposeBag)
                }

                func processDecoyRegister(decoyProbability: Float) {

                    let r = self.randomizer.randomFloat(in: self.configuration.decoyProbabilityRange)
                    guard r < decoyProbability else {
                        self.logDebug("Not running decoy `/register` \(r) >= \(decoyProbability)")
                        return promise(.success(()))
                    }

                    self.dataController.setLastDecoyProcessDate(currentDate())

                    self.exposureController.requestLabConfirmationKey { _ in
                        self.logDebug("Decoy `/register` complete")
                        processStopKeys()
                    }
                }

                self.exposureController
                    .getDecoyProbability()
                    .delay(.seconds(self.randomizer.randomInt(in: 1 ... 60)), scheduler: MainScheduler.instance)
                    .subscribe(onSuccess: { decoyProbability in
                        processDecoyRegister(decoyProbability: decoyProbability)
                    })
                    .disposed(by: self.rxDisposeBag)
            }
        }.eraseToAnyPublisher()
    }

    // Returns a Date with the specified hour and minute, for the next day
    // E.g. date(hour: 1, minute: 0) returns 1:00 am for the next day
    private func date(hour: Int, minute: Int, dayOffset: Int = 1) -> Date? {

        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: dayOffset, to: currentDate()) else {
            return nil
        }

        var components = calendar.dateComponents([.day, .month, .year, .timeZone], from: tomorrow)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)
    }

    private func schedule(identifier: BackgroundTaskIdentifiers, date: Date? = nil, completion: ((Bool) -> ())? = nil) {
        let backgroundTaskIdentifier = bundleIdentifier + "." + identifier.rawValue

        logDebug("Background: Scheduling `\(identifier)` for earliestDate \(String(describing: date))")

        taskScheduler.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)

        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = date

        do {
            try taskScheduler.submit(request)
            logDebug("Background: Scheduled `\(identifier)` ✅")
            completion?(true)
        } catch {
            logError("Background: Could not schedule \(backgroundTaskIdentifier): \(error.localizedDescription)")
            completion?(true)
        }
    }

    private var isExposureManagerActive: Bool {
        exposureManager.getExposureNotificationStatus() == .active
    }
}
