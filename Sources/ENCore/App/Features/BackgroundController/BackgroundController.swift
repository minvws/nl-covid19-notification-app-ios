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
    // Background tasks with this identifier get higher priority from iOS. Don't change the string without knowing what you're doing!
    case refresh = "exposure-notification"
}

struct BackgroundTaskConfiguration {
    let decoyProbabilityRange: Range<Float>
    let decoyHourRange: ClosedRange<Int>
    let decoyMinuteRange: ClosedRange<Int>
    let decoyDelayRangeLowerBound: ClosedRange<Int>
    let decoyDelayRangeUpperBound: ClosedRange<Int>
}

/// This class manages the scheduling and execution of the background task. This task performs work that is essential for the proper functioning of the app.
/// Such as downloading and processing keysets, triggering decoy traffic and updating configuration files coming from the API.
/// Some things to note:
/// - On iOS 12.5.x, we don't use the regular background task framework because it doesn't exist. Instead we use a handler in the EN Framework that we register in `func registerActivityHandle()`
/// - The app has a special entitlement that gives any scheduled background tasks extra priority. This entitlement is coupled to the `BackgroundTaskIdentifiers.refresh` identifier. Do not change this accidentally.
/// - See `func refresh(..)` for the main work that is executed during the background run
/// - To tests this background task implementation, run the application on device. Put a breakpoint at the `logDebug("Background: Scheduled `\(identifier)` ✅")` statement and background the application.
/// When the breakpoint is hit put this into the console `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"nl.rijksoverheid.en.exposure-notification"]`
/// and resume the application. The background task will be run.
final class BackgroundController: BackgroundControlling, Logging {
    // MARK: - Init

    init(exposureController: ExposureControlling,
         networkController: NetworkControlling,
         configuration: BackgroundTaskConfiguration,
         exposureManager: ExposureManaging,
         dataController: ExposureDataControlling,
         userNotificationController: UserNotificationControlling,
         taskScheduler: TaskScheduling,
         bundleIdentifier: String,
         randomNumberGenerator: RandomNumberGenerating,
         environmentController: EnvironmentControlling) {
        self.exposureController = exposureController
        self.configuration = configuration
        self.networkController = networkController
        self.exposureManager = exposureManager
        self.dataController = dataController
        self.userNotificationController = userNotificationController
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
                        self.disableApp()
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
    func handle(task: BackgroundTask) {
        guard task.isBackgroundProcessingTask else {
            return logError("Background: Task is not of type `BGProcessingTask`")
        }
        guard let identifier = BackgroundTaskIdentifiers(rawValue: task.identifier.replacingOccurrences(of: bundleIdentifier + ".", with: "")) else {
            return logError("Background: No Handler for: \(task.identifier)")
        }
        logDebug("Background: Handling task \(identifier)")

        let handleTask: () -> () = {
            self.refresh(task: task)
            self.scheduleRefresh()
        }

        operationQueue.async(execute: handleTask)
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

        exposureManager.setLaunchActivityHandler { [weak self] activityFlags in

            guard let strongSelf = self else { return }

            strongSelf.logDebug("BackgroundController.registerActivityHandle() setLaunchActivityHandler: \(activityFlags)")

            if activityFlags.contains(.periodicRun) {
                strongSelf.logInfo("Periodic activity callback called (iOS 12.5)")
                strongSelf.refresh(task: nil)
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
    private let userNotificationController: UserNotificationControlling
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
    ///        Schedule the ‘stopkeys’ decoy’ sequence rand(5-30) seconds later
    ///
    ///     Ensure only 1 decoy per day
    ///     x = the time it typically takes a slow, real user to go from app startup to the ggd code screen.
    func performDecoySequenceIfNeeded() {
        logDebug("performDecoySequenceIfNeeded()")

        guard isExposureManagerActive else {
            logDebug("ExposureManager inactive - Not handling performDecoySequenceIfNeeded")
            return
        }

        guard dataController.canProcessDecoySequence else {
            return logDebug("Not running decoy `/register` Process already run today")
        }

        func execute(decoyProbability: Float) {
            // Extra check to see if the decoy sequence has already been performed today.
            // Because this call is called with a delay, once we reach this point the register
            // call might already have been performed somewhere else
            guard dataController.canProcessDecoySequence else {
                return logDebug("Not running decoy `/register` Process already run today")
            }

            let r = randomNumberGenerator.randomFloat(in: configuration.decoyProbabilityRange)
            guard r < decoyProbability else {
                return logDebug("Not running decoy `/register` \(r) >= \(decoyProbability)")
            }

            dataController.setLastDecoyProcessDate(currentDate())

            exposureController.requestLabConfirmationKey { _ in

                self.logDebug("Decoy `/register` complete")

                let decoyDelay = self.randomNumberGenerator.randomInt(in: 5 ... 30)

                self.logDebug("Scheduling asynchronous stopKeys call \(decoyDelay) seconds from now")

                DispatchQueue.global(qos: .utility)
                    .asyncAfter(deadline: DispatchTime.now() + .seconds(decoyDelay)) {
                        self.handleDecoyStopkeys()
                    }
            }
        }

        exposureController
            .getDecoyProbability()
            .delay(.seconds(randomNumberGenerator.randomInt(in: 1 ... 60)), scheduler: MainScheduler.instance) // random number between 1 and 60 seconds
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .utility))
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

        let sequence: [Completable]

        if dataController.isAppPaused {
            // When the app is paused we only perform a limited set of actions in the background

            sequence = [
                removePreviousExposureDateIfNeeded(),
                displayPauseExpirationReminderIfNeeded(),
                scheduleRemoteNotificationCompletable()
            ]

        } else {
            sequence = [
                removePreviousExposureDateIfNeeded(),
                updateStatusStream(),
                fetchAndProcessKeysets(),
                processPendingUploads(),
                sendInactiveFrameworkNotificationIfNeeded(),
                sendNotificationIfAppShouldUpdate(),
                updateTreatmentPerspective(),
                sendExposureReminderNotificationIfNeeded(),
                processDecoyRegisterAndStopKeys(),
                scheduleRemoteNotificationCompletable()
            ]
        }

        logDebug("Background: starting refresh task")

        // Checks if we are allowed to run background work at all at the moment
        // or wether the app should be deactivated right now
        performPrecheckActions(task: task) { [weak self] in
            guard let self = self else { return }

            guard !self.appShouldBeDeactivated else {
                return
            }

            let disposible = Completable.concat(sequence)
                .subscribe {
                    // Note: We ignore the response
                    self.logDebug("--- Finished Background Refresh ---")
                    task?.setTaskCompleted(success: true)
                } onError: { error in
                    self.logError("Background: Error completing sequence \(error.localizedDescription)")
                    task?.setTaskCompleted(success: false)
                }

            disposible.disposed(by: self.disposeBag)

            // Handle running out of time
            if let task = task {
                task.expirationHandler = {
                    self.logError("Background: refresh task expired")
                    disposible.dispose()
                }
            }
        }
    }

    private func performPrecheckActions(task: BackgroundTask?, completion: @escaping () -> ()) {
        // List of work that need to be done before we start the real refresh tasks
        let precheckSequence = [
            activateExposureController(), // Needed to perform any actions related to the framework
            updateAppConfiguration(), // Gets the latest app config
            disableAppIfNeededCompletable() // reads app config and disables app if the config says it should be disabled
        ]

        logDebug("Background: starting precheck actions")

        let precheckDisposable = Completable.concat(precheckSequence)
            .subscribe { _ in
                completion()
            }

        precheckDisposable.disposed(by: self.disposeBag)

        // Handle running out of time
        if let task = task {
            task.expirationHandler = {
                self.logError("Background: refresh task expired")
                precheckDisposable.dispose()
            }
        }
    }

    private func handleDecoyStopkeys() {
        guard isExposureManagerActive else {
            logDebug("ExposureManager inactive - Not handling handleDecoyStopkeys()")
            return
        }

        logDebug("Decoy `/stopkeys` started")
        exposureController
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
            }, onError: { _ in
                self.logError("Decoy `/stopkeys` complete")
            }).disposed(by: disposeBag)
    }

    private func scheduleRefresh() {

        guard !appShouldBeDeactivated else {
            disableApp()
            logDebug("Not scheduling refresh task since app is deactivated")
            return
        }

        let timeInterval = refreshInterval * 60
        let date = currentDate().addingTimeInterval(timeInterval)

        if #available(iOS 13, *) {
            schedule(identifier: .refresh, date: date)
        }
    }

    private func activateExposureController() -> Completable {
        logDebug("BackgroundTask: Activate Exposure Controller Called")
        return exposureController.activate()
            .do { error in
                self.logError("BackgroundTask: Activate Exposure Controller Failed. Reason: \(error)")
            } onCompleted: {
                self.logDebug("BackgroundTask: Activate Exposure Controller Completed")
            } onSubscribe: {
                self.logDebug("BackgroundTask: Activate Exposure Controller Subscribe")
            }
    }

    private func updateStatusStream() -> Completable {
        logDebug("BackgroundTask: Update Status Stream Called")

        // even though exposureController.updateStatusStream() is a synchronous call,
        // we still wrap it in a completable to make it possible to schedule the work in the refresh sequence
        return .create { (observer) -> Disposable in
            self.exposureController.refreshStatus {
                observer(.completed)
            }
            return Disposables.create()
        }
    }

    private func displayPauseExpirationReminderIfNeeded() -> Completable {
        logDebug("BackgroundTask: displayPauseExpirationReminderIfNeeded")

        return .create { (observer) -> Disposable in

            if self.shouldShowPauseExpirationReminder {
                self.userNotificationController.displayPauseExpirationReminder { success in
                    if success {
                        observer(.completed)
                    } else {
                        observer(.error(ExposureDataError.internalError))
                    }
                }
            } else {
                observer(.completed)
            }

            return Disposables.create()
        }
    }

    private func fetchAndProcessKeysets() -> Completable {
        logDebug("BackgroundTask: Fetch And Process Keysets Called")
        return exposureController.updateWhenRequired()
            .do { error in
                self.logError("BackgroundTask: Fetch And Process Keysets Failed. Reason: \(error)")
            } onCompleted: {
                self.logDebug("BackgroundTask: Fetch And Process Keysets Completed")
            } onSubscribe: {
                self.logDebug("BackgroundTask: Fetch And Process Keysets Subscribe")
            }
    }

    private func processPendingUploads() -> Completable {
        logDebug("BackgroundTask: Process Update Function Called")
        return exposureController
            .updateAndProcessPendingUploads()
            .do { error in
                self.logError("BackgroundTask: Process Update Failed. Reason: \(error)")
            } onCompleted: {
                self.logDebug("BackgroundTask: Process Update Completed")
            } onSubscribe: {
                self.logDebug("BackgroundTask: Process Update Subscribe")
            }
    }

    private func sendInactiveFrameworkNotificationIfNeeded() -> Completable {
        logDebug("BackgroundTask: Exposure Notification Status Check Function Called")
        return exposureController
            .exposureNotificationStatusCheck()
            .do { error in
                self.logError("BackgroundTask: Exposure Notification Status Check Failed. Reason: \(error)")
            } onCompleted: {
                self.logDebug("BackgroundTask: Exposure Notification Status Check Completed")
            } onSubscribe: {
                self.logDebug("BackgroundTask: Exposure Notification Status Check Subscribe")
            }
    }

    private func sendNotificationIfAppShouldUpdate() -> Completable {
        logDebug("BackgroundTask: App Update Required Check Function Called")
        return exposureController
            .sendNotificationIfAppShouldUpdate()
            .do { error in
                self.logError("BackgroundTask: App Update Required Check Failed. Reason: \(error)")
            } onCompleted: {
                self.logDebug("BackgroundTask: App Update Required Check Completed")
            } onSubscribe: {
                self.logDebug("BackgroundTask: App Update Required Check Subscribe")
            }
    }

    private func updateTreatmentPerspective() -> Completable {
        logDebug("BackgroundTask: Update Treatment Perspective Message Function Called")
        return exposureController
            .updateTreatmentPerspective()
            .do { error in
                self.logError("BackgroundTask: Update Treatment Perspective Message Failed. Reason: \(error)")
            } onCompleted: {
                self.logDebug("BackgroundTask: Update Treatment Perspective Message Completed")
            } onSubscribe: {
                self.logDebug("BackgroundTask: Update Treatment Perspective Message Subscribe")
            }
    }

    private func sendExposureReminderNotificationIfNeeded() -> Completable {
        logDebug("BackgroundTask: Process Last Opened Notification Check Called")
        return exposureController.lastOpenedNotificationCheck()
            .do { error in
                self.logError("BackgroundTask: Process Last Opened Notification Check Failed. Reason: \(error)")
            } onCompleted: {
                self.logDebug("BackgroundTask: Process Last Opened Notification Check Completed")
            } onSubscribe: {
                self.logDebug("BackgroundTask:  Process Last Opened Notification Check Subscribe")
            }
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
        logDebug("Background: processDecoyRegisterAndStopKeys()")

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
                // Extra check to see if the decoy sequence has already been performed today.
                // Because this call is called with a delay, once we reach this point the register
                // call might already have been performed somewhere else
                guard self.dataController.canProcessDecoySequence else {
                    self.logDebug("Not running decoy `/register` Process already run today")
                    observer(.completed)
                    return
                }

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

    /// updates manifest and appconfiguration
    private func updateAppConfiguration() -> Completable {
        logDebug("Background: updateAppConfiguration()")
        return dataController.updateAppConfiguration()
    }
    /// Disables app entirely if needed
    private func disableAppIfNeededCompletable() -> Completable {
        logDebug("Background: disableAppIfNeededCompletable()")

        return .create { (observer) -> Disposable in
            if self.appShouldBeDeactivated {
                self.disableApp()
            }
            observer(.completed)
            return Disposables.create()
        }
    }

    /// Removes stored previous exposure date in case it is longer than 14 days ago
    private func removePreviousExposureDateIfNeeded() -> Completable {
        logDebug("Background: removePreviousExposureDate()")
        return dataController.removePreviousExposureDateIfNeeded()
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

    private func scheduleRemoteNotificationCompletable() -> Completable {
        logDebug("Background: scheduleRemoteNotification()")

        return .create { (observer) -> Disposable in
            self.scheduleRemoteNotification()
            observer(.completed)
            return Disposables.create()
        }
    }

    func scheduleRemoteNotification() {
        userNotificationController.removeScheduledRemoteNotification()

        guard let notification = exposureController.getScheduledNotificaton() else {
            logDebug("Remote Notification: No remote notification to schedule")
            return
        }

        logDebug("Remote Notification: start scheduling notification with title: \(notification.title), body: \(notification.body), scheduledDateTime: \(notification.scheduledDateTime), targetScreen: \(notification.targetScreen),  probability: \(String(describing: notification.probability))")

        guard let scheduledDate = notification.scheduledDateTimeComponents() else {
            logError("Remote Notification: Could not schedule remote notification: no scheduledDateTimeComponents()")
            return
        }

        if let notificationProbability = notification.probability {
            let randomProbabilityComparator = randomNumberGenerator.randomFloat(in: 0 ..< 1)

            guard randomProbabilityComparator <= notificationProbability else {
                logDebug("Remote Notification: Not scheduling remote notification, probability: \(notificationProbability) random comparator: \(randomProbabilityComparator)")
                return
            }

            logDebug("Remote Notification: Going to scheduling remote notification, probability: \(notificationProbability) random comparator: \(randomProbabilityComparator)")
        }

        userNotificationController.scheduleRemoteNotification(title: notification.title,
                                                              body: notification.body,
                                                              dateComponents: scheduledDate,
                                                              targetScreen: notification.targetScreen)

        logDebug("Scheduled remote notification: `\(notification.title) - \(notification.body) at \(notification.scheduledDateTime)` ✅")
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

    private var appShouldBeDeactivated: Bool {
        exposureController.getStoredAppDeactivated()
    }

    private func disableApp() {
        // Activation is needed to call functions on the framework (and to disable it)
        exposureController
            .activate()
            .subscribe { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .completed:
                    self.logDebug("Disable app (remove exposure, removing bg tasks, deactivate exposure controller")
                    self.removePreviousExposureDateIfNeeded().subscribe().disposed(by: self.disposeBag)
                    self.removeAllTasks()
                    self.exposureController.deactivate()
                case .error:
                    self.logDebug("Disabling app failed because EN framework could not be activated")
                }
            }.disposed(by: disposeBag)
    }
}
