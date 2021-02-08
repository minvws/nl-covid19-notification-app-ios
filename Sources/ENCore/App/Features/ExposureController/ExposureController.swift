/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift
import UIKit

final class ExposureController: ExposureControlling, Logging {

    init(mutableStateStream: MutableExposureStateStreaming,
         exposureManager: ExposureManaging,
         dataController: ExposureDataControlling,
         networkStatusStream: NetworkStatusStreaming,
         userNotificationCenter: UserNotificationCenter,
         currentAppVersion: String) {
        self.mutableStateStream = mutableStateStream
        self.exposureManager = exposureManager
        self.dataController = dataController
        self.networkStatusStream = networkStatusStream
        self.userNotificationCenter = userNotificationCenter
        self.currentAppVersion = currentAppVersion
    }

    // MARK: - ExposureControlling

    var lastExposureDate: Date? {
        return dataController.lastExposure?.date
    }

    var isFirstRun: Bool {
        return dataController.isFirstRun
    }

    var didCompleteOnboarding: Bool {
        get {
            return dataController.didCompleteOnboarding
        }
        set {
            dataController.didCompleteOnboarding = newValue
        }
    }

    var seenAnnouncements: [Announcement] {
        get {
            return dataController.seenAnnouncements
        }
        set {
            dataController.seenAnnouncements = newValue
        }
    }

    @discardableResult
    func activate(inBackgroundMode: Bool) -> Completable {
        logDebug("Request EN framework activation")

        guard isActivated == false else {
            logDebug("Already activated")
            // already activated, return success
            return .empty()
        }

        // Don't activate EN if we're in a paused state, just update the status
        guard !dataController.isAppPaused else {
            updateStatusStream()
            return .empty()
        }

        return .create { (observer) -> Disposable in
            self.updatePushNotificationState {
                self.logDebug("EN framework activating")
                self.exposureManager.activate { _ in
                    self.isActivated = true
                    self.logDebug("EN framework activated `authorizationStatus`: \(self.exposureManager.authorizationStatus.rawValue) `isExposureNotificationEnabled`: \(self.exposureManager.isExposureNotificationEnabled())")

                    func postActivation() {
                        self.logDebug("started `postActivation`")
                        if inBackgroundMode == false {
                            self.postExposureManagerActivation()
                        }
                        self.updateStatusStream()
                        observer(.completed)
                    }

                    if self.exposureManager.authorizationStatus == .authorized, !self.exposureManager.isExposureNotificationEnabled(), self.didCompleteOnboarding {
                        self.logDebug("Calling `setExposureNotificationEnabled`")
                        self.exposureManager.setExposureNotificationEnabled(true) { result in
                            if case let .failure(error) = result {
                                self.logDebug("`setExposureNotificationEnabled` error: \(error.localizedDescription)")
                            } else {
                                self.logDebug("Returned from `setExposureNotificationEnabled` (success)")
                            }
                            postActivation()
                        }
                    } else {
                        postActivation()
                    }
                }
            }

            return Disposables.create()
        }
    }

    func deactivate() {
        exposureManager.deactivate()
    }

    func pause(untilDate date: Date) {
        exposureManager.setExposureNotificationEnabled(false) { [weak self] result in
            self?.dataController.pauseEndDate = date
            self?.updateStatusStream()
        }
    }

    func unpause() {

        exposureManager.setExposureNotificationEnabled(true) { [weak self] result in

            guard let strongSelf = self else {
                return
            }

            strongSelf.dataController.pauseEndDate = nil

            if strongSelf.isActivated == false {
                strongSelf.activate(inBackgroundMode: false)
                    .subscribe()
                    .disposed(by: strongSelf.disposeBag)
            } else {
                // Update the status (will remove the paused state from the UI)
                strongSelf.updateStatusStream()

                strongSelf.updateWhenRequired()
                    .subscribe()
                    .disposed(by: strongSelf.disposeBag)
            }
        }
    }

    func getAppVersionInformation(_ completion: @escaping (ExposureDataAppVersionInformation?) -> ()) {
        return dataController
            .getAppVersionInformation()
            .subscribe(onSuccess: { exposureDataAppVersionInformation in
                completion(exposureDataAppVersionInformation)
            }, onFailure: { _ in
                completion(nil)
            })
            .disposed(by: disposeBag)
    }

    func isAppDeactivated() -> Single<Bool> {
        return dataController.isAppDeactivated()
    }

    func getDecoyProbability() -> Single<Float> {
        return dataController.getDecoyProbability()
    }

    func getPadding() -> Single<Padding> {
        return dataController
            .getPadding()
    }

    func refreshStatus() {
        updatePushNotificationState {
            self.updateStatusStream()
        }
    }

    func updateWhenRequired() -> Completable {

        logDebug("Update when required started")

        if let updateStream = updateStream {
            // already updating
            logDebug("Already updating")
            return updateStream
        }

        let updateStream = mutableStateStream
            .exposureState
            .take(1)
            .flatMap { (state: ExposureState) -> Completable in
                // update when active, or when inactive due to no recent updates
                guard [.active, .inactive(.noRecentNotificationUpdates), .inactive(.pushNotifications), .inactive(.bluetoothOff)].contains(state.activeState) else {
                    self.logDebug("Not updating as inactive")
                    return .empty()
                }

                self.logDebug("Going to fetch and process exposure keysets")
                return .create { observer -> Disposable in
                    self.fetchAndProcessExposureKeySets().subscribe { _ in
                        return observer(.completed)
                    }
                }
            }
            .do(onError: { [weak self] _ in
                self?.updateStream = nil
            }, onCompleted: { [weak self] in
                self?.updateStream = nil
            })
            .share()
            .asCompletable()

        self.updateStream = updateStream
        return updateStream
    }

    func processExpiredUploadRequests() -> Completable {
        return dataController
            .processExpiredUploadRequests()
    }

    func processPendingUploadRequests() -> Completable {
        return dataController
            .processPendingUploadRequests()
    }

    func requestExposureNotificationPermission(_ completion: ((ExposureManagerError?) -> ())?) {
        logDebug("`requestExposureNotificationPermission` started")

        exposureManager.setExposureNotificationEnabled(true) { result in
            self.logDebug("`requestExposureNotificationPermission` returned result \(result)")

            // wait for 0.2s, there seems to be a glitch in the framework
            // where after successful activation it returns '.disabled' for a
            // split second
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if case let .failure(error) = result {
                    completion?(error)
                } else {
                    completion?(nil)
                }

                self.updateStatusStream()
            }
        }
    }

    func fetchAndProcessExposureKeySets() -> Completable {
        logDebug("fetchAndProcessExposureKeySets started")
        if let exposureKeyUpdateStream = exposureKeyUpdateStream {
            logDebug("Already fetching")
            // already fetching
            return exposureKeyUpdateStream
        }

        let stream = dataController
            .fetchAndProcessExposureKeySets(exposureManager: exposureManager)

        stream.subscribe(onCompleted: {
            self.logDebug("fetchAndProcessExposureKeySets Completed successfuly")
            self.updateStatusStream()
            self.exposureKeyUpdateStream = nil
        }, onError: { error in
            self.logDebug("fetchAndProcessExposureKeySets Completed with failure: \(error.localizedDescription)")
            self.updateStatusStream()
            self.exposureKeyUpdateStream = nil
        })
            .disposed(by: disposeBag)

        exposureKeyUpdateStream = stream

        return stream
    }

    func confirmExposureNotification() {
        dataController
            .removeLastExposure()
            .subscribe(onCompleted: { [weak self] in
                self?.updateStatusStream()
            }, onError: { [weak self] _ in
                self?.updateStatusStream()
            })
            .disposed(by: disposeBag)
    }

    func requestLabConfirmationKey(completion: @escaping (Result<ExposureConfirmationKey, ExposureDataError>) -> ()) {
        dataController
            .requestLabConfirmationKey()
            .subscribe(on: MainScheduler.instance)
            .subscribe(onSuccess: { labConfirmationKey in
                completion(.success(labConfirmationKey))
            }, onFailure: { error in
                let convertedError = (error as? ExposureDataError) ?? ExposureDataError.internalError
                completion(.failure(convertedError))
            }).disposed(by: self.disposeBag)
    }

    func requestUploadKeys(forLabConfirmationKey labConfirmationKey: ExposureConfirmationKey,
                           completion: @escaping (ExposureControllerUploadKeysResult) -> ()) {

        guard let labConfirmationKey = labConfirmationKey as? LabConfirmationKey else {
            completion(.invalidConfirmationKey)
            return
        }

        requestDiagnosisKeys()
            .subscribe(onSuccess: { keys in
                self.upload(diagnosisKeys: keys,
                            labConfirmationKey: labConfirmationKey,
                            completion: completion)
            }, onFailure: { error in

                let exposureManagerError = error.asExposureManagerError
                switch exposureManagerError {
                case .notAuthorized:
                    completion(.notAuthorized)
                default:
                    completion(.inactive)
                }
            })
            .disposed(by: disposeBag)
    }

    func updateLastLaunch() {
        dataController.setLastAppLaunchDate(Date())
    }

    func clearUnseenExposureNotificationDate() {
        dataController.clearLastUnseenExposureNotificationDate()
    }

    func updateAndProcessPendingUploads() -> Completable {
        logDebug("Update and Process, authorisationStatus: \(exposureManager.authorizationStatus.rawValue)")

        guard exposureManager.authorizationStatus == .authorized else {
            return .error(ExposureDataError.notAuthorized)
        }

        logDebug("Current exposure notification status: \(String(describing: mutableStateStream.currentExposureState?.activeState)), activated before: \(isActivated)")

        let sequence: [Completable] = [
            self.processExpiredUploadRequests(),
            self.processPendingUploadRequests()
        ]

        logDebug("Executing update sequence")

        // Combine all processes together, the sequence will be exectued in the order they are in the `sequence` array
        return Observable.from(sequence.compactMap { $0 })
            // execute one at the same time
            .merge(maxConcurrent: 1)
            // collect them
            .toArray()
            .asCompletable()
            .do(onError: { [weak self] error in
                self?.logError("Error completing sequence \(error.localizedDescription)")
            }, onCompleted: { [weak self] in
                // notify the user if required
                self?.logDebug("--- Finished `updateAndProcessPendingUploads` ---")
                self?.notifyUser24HoursNoCheckIfRequired()
            })
    }

    func exposureNotificationStatusCheck() -> Completable {
        return .create { (observer) -> Disposable in
            self.logDebug("Exposure Notification Status Check Started")

            let now = Date()
            let status = self.exposureManager.getExposureNotificationStatus()

            guard status != .active else {
                self.dataController.setLastENStatusCheckDate(now)
                self.logDebug("`exposureNotificationStatusCheck` skipped as it is `active`")
                observer(.completed)
                return Disposables.create()
            }

            guard let lastENStatusCheckDate = self.dataController.lastENStatusCheckDate else {
                self.dataController.setLastENStatusCheckDate(now)
                self.logDebug("No `lastENStatusCheck`, skipping")
                observer(.completed)
                return Disposables.create()
            }

            let timeInterval = TimeInterval(60 * 60 * 24) // 24 hours

            guard lastENStatusCheckDate.addingTimeInterval(timeInterval) < Date() else {
                self.logDebug("`exposureNotificationStatusCheck` skipped as it hasn't been 24h")
                observer(.completed)
                return Disposables.create()
            }

            self.logDebug("EN Status Check not active within 24h: \(status)")
            self.dataController.setLastENStatusCheckDate(now)

            let content = UNMutableNotificationContent()
            content.body = .notificationEnStatusNotActive
            content.sound = .default
            content.badge = 0

            self.sendNotification(content: content, identifier: .enStatusDisabled) { didSend in
                self.logDebug("Did send local notification `\(content)`: \(didSend)")
                observer(.completed)
            }

            return Disposables.create()
        }
    }

    func appShouldUpdateCheck() -> Single<AppUpdateInformation> {
        return .create { observer in

            self.logDebug("appShouldUpdateCheck Started")

            self.shouldAppUpdate { updateInformation in
                observer(.success(updateInformation))
            }

            return Disposables.create()
        }
    }

    func sendNotificationIfAppShouldUpdate() -> Completable {
        return .create { (observer) -> Disposable in

            self.logDebug("sendNotificationIfAppShouldUpdate Started")

            self.shouldAppUpdate { updateInformation in

                guard updateInformation.shouldUpdate, let appVersionInformation = updateInformation.versionInformation else {
                    observer(.completed)
                    return
                }

                let message = appVersionInformation.minimumVersionMessage.isEmpty ? String.updateAppContent : appVersionInformation.minimumVersionMessage

                let content = UNMutableNotificationContent()
                content.body = message
                content.sound = .default
                content.badge = 0

                self.sendNotification(content: content, identifier: .appUpdateRequired) { didSend in
                    self.logDebug("Did send local notification `\(content)`: \(didSend)")
                    observer(.completed)
                }
            }

            return Disposables.create()
        }
    }

    func updateTreatmentPerspective() -> Completable {
        dataController.updateTreatmentPerspective()
    }

    func lastOpenedNotificationCheck() -> Completable {
        return .create { (observer) -> Disposable in

            guard let lastAppLaunch = self.dataController.lastAppLaunchDate else {
                self.logDebug("`lastOpenedNotificationCheck` skipped as there is no `lastAppLaunchDate`")
                observer(.completed)
                return Disposables.create()
            }
            guard let lastExposure = self.dataController.lastExposure else {
                self.logDebug("`lastOpenedNotificationCheck` skipped as there is no `lastExposureDate`")
                observer(.completed)
                return Disposables.create()
            }

            guard let lastUnseenExposureNotificationDate = self.dataController.lastUnseenExposureNotificationDate else {
                self.logDebug("`lastOpenedNotificationCheck` skipped as there is no `lastUnseenExposureNotificationDate`")
                observer(.completed)
                return Disposables.create()
            }

            guard lastAppLaunch < lastUnseenExposureNotificationDate else {
                self.logDebug("`lastOpenedNotificationCheck` skipped as the app has been opened after the notification")
                observer(.completed)
                return Disposables.create()
            }

            let notificationThreshold = TimeInterval(60 * 60 * 3) // 3 hours

            guard lastUnseenExposureNotificationDate.addingTimeInterval(notificationThreshold) < Date() else {
                self.logDebug("`lastOpenedNotificationCheck` skipped as it hasn't been 3h after initial notification")
                observer(.completed)
                return Disposables.create()
            }

            guard lastAppLaunch.addingTimeInterval(notificationThreshold) < Date() else {
                self.logDebug("`lastOpenedNotificationCheck` skipped as it hasn't been 3h")
                observer(.completed)
                return Disposables.create()
            }

            self.logDebug("User has not opened the app in 3 hours.")

            let days = Date().days(sinceDate: lastExposure.date) ?? 0

            let content = UNMutableNotificationContent()
            content.body = .exposureNotificationReminder(.exposureNotificationUserExplanation(.statusNotifiedDaysAgo(days: days)))
            content.sound = .default
            content.badge = 0

            self.sendNotification(content: content, identifier: .exposure) { didSend in
                self.logDebug("Did send local notification `\(content)`: \(didSend)")
                observer(.completed)
            }

            return Disposables.create()
        }
    }

    func notifyUser24HoursNoCheckIfRequired() {

        func notifyUser() {

            let content = UNMutableNotificationContent()
            content.title = .statusAppStateInactiveTitle
            content.body = String(format: .statusAppStateInactiveNotification)
            content.sound = UNNotificationSound.default
            content.badge = 0

            let identifier = PushNotificationIdentifier.inactive.rawValue
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

            userNotificationCenter.add(request, withCompletionHandler: { [weak self] error in
                if let error = error {
                    self?.logError("\(error.localizedDescription)")
                } else {
                    self?.dataController.updateLastLocalNotificationExposureDate(Date())
                }
            })
        }

        let timeInterval = TimeInterval(60 * 60 * 24) // 24 hours
        guard
            let lastSuccessfulProcessingDate = dataController.lastSuccessfulExposureProcessingDate,
            lastSuccessfulProcessingDate.addingTimeInterval(timeInterval) < Date()
        else {
            return
        }
        guard let lastLocalNotificationExposureDate = dataController.lastLocalNotificationExposureDate else {
            // We haven't shown a notification to the user before so we should show one now
            return notifyUser()
        }
        guard lastLocalNotificationExposureDate.addingTimeInterval(timeInterval) < Date() else {
            return
        }

        notifyUser()
    }

    func lastTEKProcessingDate() -> Observable<Date?> {
        return dataController.lastSuccessfulExposureProcessingDateObservable
    }

    // MARK: - Private

    private func shouldAppUpdate(completion: @escaping (AppUpdateInformation) -> ()) {
        getAppVersionInformation { appVersionInformation in

            guard let appVersionInformation = appVersionInformation else {
                self.logError("Error retrieving app version information")
                return completion(AppUpdateInformation(shouldUpdate: false, versionInformation: nil))
            }

            let shouldUpdate = appVersionInformation.minimumVersion.compare(self.currentAppVersion, options: .numeric) == .orderedDescending

            completion(AppUpdateInformation(shouldUpdate: shouldUpdate, versionInformation: appVersionInformation))
        }
    }

    private func postExposureManagerActivation() {
        logDebug("`postExposureManagerActivation`")

        mutableStateStream
            .exposureState
            .flatMap { [weak self] (exposureState) -> Single<Bool> in
                let stateActive = [.active, .inactive(.noRecentNotificationUpdates), .inactive(.bluetoothOff)].contains(exposureState.activeState)
                    && (self?.networkStatusStream.networkReachable == true)
                return .just(stateActive)
            }
            .filter { $0 }
            .take(1)
            .do(onNext: { [weak self] _ in
                self?.updateStatusStream()
            }, onError: { [weak self] _ in
                self?.updateStatusStream()
            })
            .flatMap { [weak self] (_) -> Completable in
                return self?
                    .updateWhenRequired() ?? .empty()
            }
            .subscribe(onNext: { _ in })
            .disposed(by: disposeBag)

        networkStatusStream
            .networkReachableStream
            .do(onNext: { [weak self] _ in
                self?.updateStatusStream()
            }, onError: { [weak self] _ in
                self?.updateStatusStream()
            })
            .filter { $0 } // only update when internet is active
            .map { [weak self] (_) -> Completable in
                return self?
                    .updateWhenRequired() ?? .empty()
            }
            .subscribe(onNext: { _ in })
            .disposed(by: disposeBag)
    }

    private func updateStatusStream() {

        if let pauseEndDate = dataController.pauseEndDate {
            mutableStateStream.update(state: .init(notifiedState: notifiedState, activeState: .inactive(.paused(pauseEndDate))))
            return
        }

        guard isActivated else {
            return logDebug("Not Updating Status Stream as not `isActivated`")
        }

        logDebug("Updating Status Stream")

        let noInternetIntervalForShowingWarning = TimeInterval(60 * 60 * 24) // 24 hours
        let hasBeenTooLongSinceLastUpdate: Bool

        if let lastSuccessfulExposureProcessingDate = dataController.lastSuccessfulExposureProcessingDate {
            hasBeenTooLongSinceLastUpdate = lastSuccessfulExposureProcessingDate.addingTimeInterval(noInternetIntervalForShowingWarning) < Date()
        } else {
            hasBeenTooLongSinceLastUpdate = false
        }

        let activeState: ExposureActiveState
        let exposureManagerStatus = exposureManager.getExposureNotificationStatus()

        switch exposureManagerStatus {
        case .active where hasBeenTooLongSinceLastUpdate:
            activeState = .inactive(.noRecentNotificationUpdates)
        case .active where !isPushNotificationsEnabled:
            activeState = .inactive(.pushNotifications)
        case .active:
            activeState = .active
        case .inactive(_) where hasBeenTooLongSinceLastUpdate:
            activeState = .inactive(.noRecentNotificationUpdates)
        case let .inactive(error) where error == .bluetoothOff:
            activeState = .inactive(.bluetoothOff)
        case let .inactive(error) where error == .disabled || error == .restricted:
            activeState = .inactive(.disabled)
        case let .inactive(error) where error == .notAuthorized:
            activeState = .notAuthorized
        case let .inactive(error) where error == .unknown:
            // Unknown can happen when iOS cannot retrieve the status correctly at this moment.
            // This can happen when the user just switched from the bluetooth settings screen.
            // Don't propagate this state as it only leads to confusion, just maintain the current state
            return self.logDebug("No Update Status Stream as not `.inactive(.unknown)` returned")
        case let .inactive(error) where error == .internalTypeMismatch:
            activeState = .inactive(.disabled)
        case .inactive where !isPushNotificationsEnabled:
            activeState = .inactive(.pushNotifications)
        case .inactive:
            activeState = .inactive(.disabled)
        case .notAuthorized:
            activeState = .notAuthorized
        case .authorizationDenied:
            activeState = .authorizationDenied
        }

        mutableStateStream.update(state: .init(notifiedState: notifiedState, activeState: activeState))
    }

    private var notifiedState: ExposureNotificationState {
        guard let exposureReport = dataController.lastExposure else {
            return .notNotified
        }

        return .notified(exposureReport.date)
    }

    private func requestDiagnosisKeys() -> Single<[DiagnosisKey]> {
        return .create { observer in
            self.exposureManager.getDiagnosisKeys { result in
                switch result {

                case let .success(diagnosisKeys):
                    observer(.success(diagnosisKeys))
                case let .failure(error):
                    observer(.failure(error))
                }
            }
            return Disposables.create()
        }
    }

    private func upload(diagnosisKeys keys: [DiagnosisKey],
                        labConfirmationKey: LabConfirmationKey,
                        completion: @escaping (ExposureControllerUploadKeysResult) -> ()) {
        let mapExposureDataError: (ExposureDataError) -> ExposureControllerUploadKeysResult = { error in
            switch error {
            case .internalError, .networkUnreachable, .serverError:
                // No network request is done (yet), these errors can only mean
                // an internal error
                return .internalError
            case .inactive, .signatureValidationFailed:
                return .inactive
            case .notAuthorized:
                return .notAuthorized
            case .responseCached:
                return .responseCached
            }
        }

        self.dataController
            .upload(diagnosisKeys: keys, labConfirmationKey: labConfirmationKey)
            .subscribe(on: MainScheduler.instance)
            .subscribe(onCompleted: {
                completion(.success)
            }, onError: { error in
                let exposureDataError = error.asExposureDataError
                completion(mapExposureDataError(exposureDataError))
            })
            .disposed(by: disposeBag)
    }

    private func updatePushNotificationState(completition: @escaping () -> ()) {
        userNotificationCenter.getAuthorizationStatus { authorizationStatus in
            self.isPushNotificationsEnabled = authorizationStatus == .authorized
            completition()
        }
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

    private let mutableStateStream: MutableExposureStateStreaming
    var exposureManager: ExposureManaging
    private let dataController: ExposureDataControlling
    private var disposeBag = DisposeBag()
    private var exposureKeyUpdateStream: Completable?
    private let networkStatusStream: NetworkStatusStreaming
    private var isActivated = false
    private var isPushNotificationsEnabled = false
    private let userNotificationCenter: UserNotificationCenter
    private var updateStream: Completable?
    private let currentAppVersion: String
}

extension LabConfirmationKey: ExposureConfirmationKey {
    var key: String {
        return identifier
    }

    var expiration: Date {
        return validUntil
    }
}
