/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

#if canImport(BackgroundTasks)
    import BackgroundTasks
#endif

import ENFoundation
import ExposureNotification
import Foundation
import RxSwift
import UIKit
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
         randomNumberGenerator: RandomNumberGenerating,
         environmentController: EnvironmentControlling) {
        self.exposureController = exposureController
        self.configuration = configuration
        self.networkController = networkController
        self.exposureManager = exposureManager
        self.dataController = dataController
        self.userNotificationCenter = userNotificationCenter
        self.taskScheduler = taskScheduler
        self.bundleIdentifier = bundleIdentifier
        self.randomNumberGenerator = randomNumberGenerator
        self.environmentController = environmentController
    }

    // MARK: - BackgroundControlling

    func scheduleTasks() {

        let scheduleTasks: () -> () = {
            self.exposureController
                .isAppDeactivated()
                .subscribe(onSuccess: { isDeactivated in
                    if isDeactivated {
                        self.logDebug("Background: ExposureController is deactivated - Removing all tasks")
                        self.removeAllTasks()
                    } else {
                        self.logDebug("Background: ExposureController is activated - Schedule refresh sequence")
                        self.scheduleRefresh()
                    }
                }, onFailure: { error in
                    self.logError("Background: ExposureController activated state result: \(error)")
                    self.logError("Background: Scheduling refresh sequence")
                    self.scheduleRefresh()
                    })
                .disposed(by: self.disposeBag)
        }

        operationQueue.async(execute: scheduleTasks)
    }

    @available(iOS 13, *)
    func handle(task: BGTask) {
        LogHandler.setup()

        guard let task = task as? BGProcessingTask else {
            return logError("Background: Task is not of type `BGProcessingTask`")
        }
        guard let identifier = BackgroundTaskIdentifiers(rawValue: task.identifier.replacingOccurrences(of: bundleIdentifier + ".", with: "")) else {
            return logError("Background: No Handler for: \(task.identifier)")
        }
        logDebug("Background: Handling task \(identifier)")

        // in a paused state, we only handle refresh background tasks.
        // We use this process to send a reminder to users that the app is still in a paused state
        guard !dataController.isAppPaused else {
            handleTaskDuringPause(task: task, withIdentifier: identifier)
            return
        }

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

    @available(iOS 13, *)
    private func handleTaskDuringPause(task: BGTask, withIdentifier identifier: BackgroundTaskIdentifiers) {
        logInfo("Handling background task in paused state")
        func completeTask() {
            self.scheduleRefresh()
            task.setTaskCompleted(success: true)
        }

        if identifier == .refresh, shouldShowPauseExpirationReminder {
            logInfo("Displaying unpause reminder notification")
            userNotificationCenter.displayPauseExpirationReminder {
                completeTask()
            }
        } else {
            completeTask()
        }
    }

    // ENManager gives apps that register an activity handler
    // in iOS 12.5 up to 3.5 minutes of background time at
    // least once per day. In iOS 13 and later, registering an
    // activity handler does nothing.
    func registerActivityHandle() {

        logDebug("BackgroundController - registerActivityHandle() called")

        guard environmentController.isiOS12 else {
            logDebug("BackgroundController - Not registering activityHandler because we are not on iOS 12.5")
            return
        }

        self.exposureManager.setLaunchActivityHandler { [weak self] activityFlags in

            guard let strongSelf = self else { return }

            strongSelf.logDebug("BackgroundController.registerActivityHandle() setLaunchActivityHandler: \(activityFlags)")

            if activityFlags.contains(.periodicRun) {

                strongSelf.logInfo("Periodic activity callback called (iOS 12.5)")

                // in a paused state we don't to a refresh

                if strongSelf.shouldShowPauseExpirationReminder {
                    strongSelf.logInfo("Displaying unpause reminder notification")
                    strongSelf.userNotificationCenter.displayPauseExpirationReminder(completion: {})
                } else {
                    strongSelf.refresh(task: nil)
                }

                strongSelf.sendBackgroundUpdateNotification()
            }
        }
    }

    func handleDecoyStopkeys(task: BackgroundTask?) {

        guard isExposureManagerActive else {
            task?.setTaskCompleted(success: true)
            logDebug("ExposureManager inactive - Not handling \(String(describing: task?.identifier))")
            return
        }

        self.logDebug("Decoy `/stopkeys` started")
        let disposable = exposureController
            .getPadding()
            .flatMapCompletable { padding in
                self.networkController
                    .stopKeys(padding: padding)
                    .subscribe(on: MainScheduler.instance)
                    .catch { error in
                        if let exposureDataError = (error as? NetworkError)?.asExposureDataError {
                            self.logError("Decoy `/stopkeys` error: \(exposureDataError)")
                            throw exposureDataError
                        } else {
                            self.logDebug("Decoy `/stopkeys` error: ExposureDataError.internalError")
                            throw ExposureDataError.internalError
                        }
                    }
            }
            .subscribe(onCompleted: {
                // Note: We ignore the response
                self.logDebug("Decoy `/stopkeys` complete")
                task?.setTaskCompleted(success: true)
            }, onError: { _ in
                self.logError("Decoy `/stopkeys` complete")
                task?.setTaskCompleted(success: true)
                })

        // Handle running out of time
        if var task = task {
            task.expirationHandler = {
                self.logDebug("Decoy `/stopkeys` expired")
                disposable.dispose()
            }
        }
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
    private var disposeBag = DisposeBag()
    private let bundleIdentifier: String
    private let operationQueue = DispatchQueue(label: "nl.rijksoverheid.en.background-processing")
    private let randomNumberGenerator: RandomNumberGenerating
    private let environmentController: EnvironmentControlling

    ///    When the user opens the app
    ///        if (config.decoyProbability),
    ///        rand(1-x) seconds after the manifest run ‘register decoy’ in the foreground,
    ///        Schedule the ‘stopkeys’ decoy’ as a normal/regular background task rand(0-15) minutes later (the chance that this bg task works is high, because the user used the app less than x ago)
    ///
    ///     Ensure only 1 decoy per day
    ///     x = the time it typically takes a slow, real user to go from app startup to the ggd code screen.
    ///     y = about 5 minutes (about less, e.g. 250 sec) this param value depends on how long a prioritized task is allowed to run
    func performDecoySequenceIfNeeded() {

        guard self.isExposureManagerActive else {
            self.logDebug("ExposureManager inactive - Not handling performDecoySequenceIfNeeded")
            return
        }

        guard self.dataController.canProcessDecoySequence else {
            return self.logDebug("Not running decoy `/register` Process already run today")
        }

        func execute(decoyProbability: Float) {

            let r = self.randomNumberGenerator.randomFloat(in: configuration.decoyProbabilityRange)
            guard r < decoyProbability else {
                return logDebug("Not running decoy `/register` \(r) >= \(decoyProbability)")
            }

            self.dataController.setLastDecoyProcessDate(currentDate())

            exposureController.requestLabConfirmationKey { _ in

                self.logDebug("Decoy `/register` complete")

                let date = currentDate().addingTimeInterval(
                    TimeInterval(self.randomNumberGenerator.randomInt(in: 0 ... 900)) // random number between 0 and 15 minutes
                )

                if self.environmentController.isiOS13orHigher {
                    if #available(iOS 13, *) {
                        self.schedule(identifier: BackgroundTaskIdentifiers.decoyStopKeys, date: date)
                    }
                } else {
                    DispatchQueue.global(qos: .utility)
                        .asyncAfter(deadline: DispatchTime.now() + .seconds(self.randomNumberGenerator.randomInt(in: 0 ... 30))) {
                            self.handleDecoyStopkeys(task: nil)
                        }
                }
            }
        }

        exposureController
            .getDecoyProbability()
            .delay(.seconds(randomNumberGenerator.randomInt(in: 1 ... 60)), scheduler: MainScheduler.instance) // random number between 1 and 60 seconds
            .subscribe(onSuccess: { decoyProbability in
                execute(decoyProbability: decoyProbability)
        })
            .disposed(by: disposeBag)
    }

    func removeAllTasks() {
        logDebug("Background: Removing all scheduled tasks")
        taskScheduler.cancelAllTaskRequests()
    }

    // MARK: - Refresh

    func refresh(task: BackgroundTask?) {
        let sequence: [Completable] = [
            activateExposureController(inBackgroundMode: true),
            processUpdate(),
            processENStatusCheck(),
            appUpdateRequiredCheck(),
            updateTreatmentPerspective(),
            processLastOpenedNotificationCheck(),
            processDecoyRegisterAndStopKeys()
        ]

        logDebug("Background: starting refresh task")

        let disposible = Observable.from(sequence.compactMap { $0 })
            .merge(maxConcurrent: 1)
            .toArray()
            .subscribe { _ in
                // Note: We ignore the response
                self.logDebug("--- Finished Background Refresh ---")
                task?.setTaskCompleted(success: true)
            } onFailure: { error in
                self.logError("Background: Error completing sequence \(error.localizedDescription)")
                task?.setTaskCompleted(success: false)
            }

        disposible.disposed(by: disposeBag)

        // Handle running out of time
        if var task = task {
            task.expirationHandler = {
                self.logError("Background: refresh task expired")
                disposible.dispose()
            }
        }
    }

    private func scheduleRefresh() {
        let timeInterval = refreshInterval * 60
        let date = currentDate().addingTimeInterval(timeInterval)

        if #available(iOS 13, *) {
            schedule(identifier: .refresh, date: date)
        }
    }

    private func activateExposureController(inBackgroundMode: Bool) -> Completable {
        return self.exposureController.activate(inBackgroundMode: inBackgroundMode)
    }

    private func processUpdate() -> Completable {
        logDebug("Background: Process Update Function Called")
        return exposureController
            .updateAndProcessPendingUploads()
            .do { error in
                self.logError("Background: Process Update Failed. Reason: \(error)")
            } onCompleted: {
                self.logDebug("Background: Process Update Completed")
            }
    }

    private func processENStatusCheck() -> Completable {
        logDebug("Background: Exposure Notification Status Check Function Called")
        return exposureController
            .exposureNotificationStatusCheck()
            .do { error in
                self.logError("Background: Exposure Notification Status Check Failed. Reason: \(error)")
            } onCompleted: {
                self.logDebug("Background: Exposure Notification Status Check Completed")
            }
    }

    private func appUpdateRequiredCheck() -> Completable {
        logDebug("Background: App Update Required Check Function Called")
        return exposureController
            .sendNotificationIfAppShouldUpdate()
            .do { error in
                self.logError("Background: App Update Required Check Failed. Reason: \(error)")
            } onCompleted: {
                self.logDebug("Background: App Update Required Check Completed")
            }
    }

    private func updateTreatmentPerspective() -> Completable {
        logDebug("Background: Update Treatment Perspective Message Function Called")
        return self.exposureController
            .updateTreatmentPerspective()
            .do { error in
                self.logError("Background: Update Treatment Perspective Message Failed. Reason: \(error)")
            } onCompleted: {
                self.logDebug("Background: Update Treatment Perspective Message Completed")
            }
    }

    private func processLastOpenedNotificationCheck() -> Completable {
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
    private func processDecoyRegisterAndStopKeys() -> Completable {
        return .create { (observer) -> Disposable in

            guard self.isExposureManagerActive else {
                self.logDebug("ExposureManager inactive - Not handling processDecoyRegisterAndStopKeys")
                observer(.completed)
                return Disposables.create()
            }

            guard self.dataController.canProcessDecoySequence else {
                self.logDebug("Not running decoy `/register` Process already run today")
                observer(.completed)
                return Disposables.create()
            }

            let paddingUpperBoundDelay = Float(UIDevice.current.systemVersion) ?? 250 < 13 ? 30 : 250
            let decoyProbabilityUpperBoundDelay = Float(UIDevice.current.systemVersion) ?? 60 < 13 ? 30 : 60

            func processStopKeys() {
                self.exposureController
                    .getPadding()
                    .delay(.seconds(self.randomNumberGenerator.randomInt(in: 1 ... paddingUpperBoundDelay)), scheduler: MainScheduler.instance)
                    .flatMapCompletable { padding in
                        self.networkController
                            .stopKeys(padding: padding)
                            .subscribe(on: MainScheduler.instance)
                            .catch { error in
                                throw (error as? NetworkError)?.asExposureDataError ?? ExposureDataError.internalError
                            }
                    }
                    .subscribe(onCompleted: {
                        // Note: We ignore the response
                        self.logDebug("Decoy `/stopkeys` complete")
                        observer(.completed)
                    }, onError: { _ in
                        // Note: We ignore the response
                        self.logError("Decoy `/stopkeys` complete")
                        observer(.completed)
                        })
                    .disposed(by: self.disposeBag)
            }

            func processDecoyRegister(decoyProbability: Float) {

                let r = self.randomNumberGenerator.randomFloat(in: self.configuration.decoyProbabilityRange)
                guard r < decoyProbability else {
                    self.logDebug("Not running decoy `/register` \(r) >= \(decoyProbability)")
                    observer(.completed)
                    return
                }

                self.dataController.setLastDecoyProcessDate(currentDate())

                self.exposureController.requestLabConfirmationKey { _ in
                    self.logDebug("Decoy `/register` complete")
                    processStopKeys()
                }
            }

            self.exposureController
                .getDecoyProbability()
                .delay(.seconds(self.randomNumberGenerator.randomInt(in: 1 ... decoyProbabilityUpperBoundDelay)), scheduler: MainScheduler.instance)
                .subscribe(onSuccess: { decoyProbability in
                    processDecoyRegister(decoyProbability: decoyProbability)
                })
                .disposed(by: self.disposeBag)

            return Disposables.create()
        }
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

    @available(iOS 13, *)
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

    private var shouldShowPauseExpirationReminder: Bool {
        if let pauseEndDate = dataController.pauseEndDate,
            currentDate().timeIntervalSince(pauseEndDate) > .hours(1) {
            return true
        } else {
            return false
        }
    }

    private func sendBackgroundUpdateNotification() {

        if environmentController.isiOS13orHigher {
            logDebug("Not sending background update notification on iOS 13 and >")
            return
        }

        logDebug("Sending background update notification")

        let formatter = DateFormatter()
        formatter.timeStyle = .long
        let date = formatter.string(from: Date())

        let content = UNMutableNotificationContent()
        content.title = "Background update"
        content.body = "Performed at \(date)"
        content.sound = UNNotificationSound.default
        content.badge = 0

        let identifier = "background-update"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        userNotificationCenter.add(request, withCompletionHandler: { [weak self] error in
            if let error = error {
                self?.logError("Error sending notification: \(error.localizedDescription)")
            }
        })
    }

    private func sendNotification(content: UNNotificationContent, identifier: PushNotificationIdentifier, completion: @escaping (Bool) -> ()) {
        userNotificationCenter.getAuthorizationStatus { status in
            guard status == .authorized else {
                completion(false)
                return self.logError("Not authorized to post notifications")
            }

            let request = UNNotificationRequest(identifier: identifier.rawValue,
                                                content: content,
                                                trigger: nil)

            self.userNotificationCenter.add(request) { error in
                guard let error = error else {
                    completion(true)
                    return
                }
                self.logError("Error posting notification: \(identifier.rawValue) \(error.localizedDescription)")
                completion(false)
            }
        }
    }
}
