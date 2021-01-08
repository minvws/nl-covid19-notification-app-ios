/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation
import RxCombine
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

    deinit {
        disposeBag.forEach { $0.cancel() }
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
    func activate(inBackgroundMode: Bool) -> AnyPublisher<(), Never> {
        logDebug("Request EN framework activation")

        guard isActivated == false else {
            logDebug("Already activated")
            // already activated, return success
            return Just(()).eraseToAnyPublisher()
        }

        return Future { resolve in
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
                        resolve(.success(()))
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
        }
        .eraseToAnyPublisher()
    }

    func deactivate() {
        exposureManager.deactivate()
    }

    func getAppVersionInformation(_ completion: @escaping (ExposureDataAppVersionInformation?) -> ()) {
        return dataController
            .getAppVersionInformation()
            .sink(
                receiveCompletion: { result in
                    guard case .failure = result else { return }

                    completion(nil)
                },
                receiveValue: completion)
            .store(in: &disposeBag)
    }

    func isAppDeactivated() -> AnyPublisher<Bool, ExposureDataError> {
        return dataController.isAppDectivated()
    }

    func getAppRefreshInterval() -> AnyPublisher<Int, ExposureDataError> {
        return dataController.getAppRefreshInterval()
    }

    func getDecoyProbability() -> AnyPublisher<Float, ExposureDataError> {
        return dataController.getDecoyProbability()
    }

    func getPadding() -> AnyPublisher<Padding, ExposureDataError> {
        return dataController.getPadding()
    }

    func refreshStatus() {
        updatePushNotificationState {
            self.updateStatusStream()
        }
    }

    func updateWhenRequired() -> AnyPublisher<(), ExposureDataError> {

        logDebug("Update when required started")

        if let updateStream = updateStream {
            // already updating
            logDebug("Already updating")
            return updateStream.share().eraseToAnyPublisher()
        }

        let updateStream = mutableStateStream
            .exposureState
            .first()
            .setFailureType(to: ExposureDataError.self)
            .flatMap { (state: ExposureState) -> AnyPublisher<(), ExposureDataError> in
                // update when active, or when inactive due to no recent updates
                guard [.active, .inactive(.noRecentNotificationUpdates), .inactive(.pushNotifications), .inactive(.bluetoothOff)].contains(state.activeState) else {
                    self.logDebug("Not updating as inactive")
                    return Just(())
                        .setFailureType(to: ExposureDataError.self)
                        .eraseToAnyPublisher()
                }

                self.logDebug("Going to fetch and process exposure keysets")
                return self.fetchAndProcessExposureKeySets()
            }
            .handleEvents(
                receiveCompletion: { _ in
                    self.updateStream = nil

                },
                receiveCancel: {
                    self.updateStream = nil
                }
            )
            .eraseToAnyPublisher()

        self.updateStream = updateStream
        return updateStream.share().eraseToAnyPublisher()
    }

    func processExpiredUploadRequests() -> AnyPublisher<(), ExposureDataError> {
        return dataController
            .processExpiredUploadRequests()
    }

    func processPendingUploadRequests() -> AnyPublisher<(), ExposureDataError> {
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

    func requestPushNotificationPermission(_ completion: @escaping (() -> ())) {
        func request() {
            userNotificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                DispatchQueue.main.async {
                    completion()
                }
            }
        }

        userNotificationCenter.getAuthorizationStatus { authorizationStatus in
            if authorizationStatus == .authorized {
                completion()
            } else {
                request()
            }
        }
    }

    func fetchAndProcessExposureKeySets() -> AnyPublisher<(), ExposureDataError> {
        logDebug("fetchAndProcessExposureKeySets started")
        if let exposureKeyUpdateStream = exposureKeyUpdateStream {
            logDebug("Already fetching")
            // already fetching
            return exposureKeyUpdateStream.eraseToAnyPublisher()
        }

        let stream = dataController
            .fetchAndProcessExposureKeySets(exposureManager: exposureManager)
            .handleEvents(
                receiveCompletion: { completion in

                    switch completion {
                    case .finished:
                        self.logDebug("fetchAndProcessExposureKeySets Completed successfuly")
                    case let .failure(error):
                        self.logDebug("fetchAndProcessExposureKeySets Completed with failure: \(error.localizedDescription)")
                    }

                    self.updateStatusStream()
                    self.exposureKeyUpdateStream = nil
                },
                receiveCancel: {
                    self.logDebug("fetchAndProcessExposureKeySets Cancelled")
                    self.updateStatusStream()
                    self.exposureKeyUpdateStream = nil
                })
            .eraseToAnyPublisher()

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
            .disposed(by: rxDisposeBag)
    }

    func requestLabConfirmationKey(completion: @escaping (Result<ExposureConfirmationKey, ExposureDataError>) -> ()) {
        dataController
            .requestLabConfirmationKey()
            .subscribe(on: MainScheduler.instance)
            .subscribe { labConfirmationKey in
                completion(.success(labConfirmationKey))
            } onError: { error in
                let convertedError = (error as? ExposureDataError) ?? ExposureDataError.internalError
                completion(.failure(convertedError))
            }.disposed(by: self.rxDisposeBag)
    }

    func requestUploadKeys(forLabConfirmationKey labConfirmationKey: ExposureConfirmationKey,
                           completion: @escaping (ExposureControllerUploadKeysResult) -> ()) {
        let receiveCompletion: (Subscribers.Completion<ExposureManagerError>) -> () = { result in
            if case let .failure(error) = result {
                let result: ExposureControllerUploadKeysResult
                switch error {
                case .notAuthorized:
                    result = .notAuthorized
                default:
                    result = .inactive
                }

                completion(result)
            }
        }

        guard let labConfirmationKey = labConfirmationKey as? LabConfirmationKey else {
            completion(.invalidConfirmationKey)
            return
        }

        let receiveValue: ([DiagnosisKey]) -> () = { keys in
            self.upload(diagnosisKeys: keys,
                        labConfirmationKey: labConfirmationKey,
                        completion: completion)
        }

        requestDiagnosisKeys()
            .sink(receiveCompletion: receiveCompletion,
                  receiveValue: receiveValue)
            .store(in: &disposeBag)
    }

    func updateLastLaunch() {
        dataController.setLastAppLaunchDate(Date())
    }

    func clearUnseenExposureNotificationDate() {
        dataController.clearLastUnseenExposureNotificationDate()
    }

    func updateAndProcessPendingUploads() -> AnyPublisher<(), ExposureDataError> {
        logDebug("Update and Process, authorisationStatus: \(exposureManager.authorizationStatus.rawValue)")

        guard exposureManager.authorizationStatus == .authorized else {
            return Fail(error: .notAuthorized).eraseToAnyPublisher()
        }

        logDebug("Current exposure notification status: \(String(describing: mutableStateStream.currentExposureState?.activeState)), activated before: \(isActivated)")

        let sequence: [() -> AnyPublisher<(), ExposureDataError>] = [
            self.processExpiredUploadRequests,
            self.processPendingUploadRequests,
            self.updateWhenRequired
        ]

        logDebug("Executing update sequence")

        // Combine all processes together, the sequence will be exectued in the order they are in the `sequence` array
        return Publishers.Sequence<[AnyPublisher<(), ExposureDataError>], ExposureDataError>(sequence: sequence.map { $0() })
            // execute them one by one
            .flatMap(maxPublishers: .max(1)) { $0 }
            // collect them
            .collect()
            // merge
            .compactMap { _ in () }
            // notify the user if required
            .handleEvents(receiveCompletion: { [weak self] result in
                switch result {
                case .finished:
                    self?.logDebug("--- Finished `updateAndProcessPendingUploads` ---")
                    self?.notifyUser24HoursNoCheckIfRequired()
                case let .failure(error):
                    self?.logError("Error completing sequence \(error.localizedDescription)")
                }
        }).eraseToAnyPublisher()
    }

    func exposureNotificationStatusCheck() -> AnyPublisher<(), Never> {
        return Deferred {
            Future { promise in
                self.logDebug("Exposure Notification Status Check Started")

                let now = Date()
                let status = self.exposureManager.getExposureNotificationStatus()

                guard status != .active else {
                    self.dataController.setLastENStatusCheckDate(now)
                    self.logDebug("`exposureNotificationStatusCheck` skipped as it is `active`")
                    return promise(.success(()))
                }

                guard let lastENStatusCheckDate = self.dataController.lastENStatusCheckDate else {
                    self.dataController.setLastENStatusCheckDate(now)
                    self.logDebug("No `lastENStatusCheck`, skipping")
                    return promise(.success(()))
                }

                let timeInterval = TimeInterval(60 * 60 * 24) // 24 hours

                guard lastENStatusCheckDate.advanced(by: timeInterval) < Date() else {
                    promise(.success(()))
                    return self.logDebug("`exposureNotificationStatusCheck` skipped as it hasn't been 24h")
                }

                self.logDebug("EN Status Check not active within 24h: \(status)")
                self.dataController.setLastENStatusCheckDate(now)

                let content = UNMutableNotificationContent()
                content.body = .notificationEnStatusNotActive
                content.sound = .default
                content.badge = 0

                self.sendNotification(content: content, identifier: .enStatusDisabled) { _ in
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }

    func appShouldUpdateCheck() -> AnyPublisher<AppUpdateInformation, ExposureDataError> {
        return Deferred {
            Future { promise in

                self.logDebug("appShouldUpdateCheck Started")

                self.shouldAppUpdate { updateInformation in
                    return promise(.success(updateInformation))
                }
            }
        }.eraseToAnyPublisher()
    }

    func sendNotificationIfAppShouldUpdate() -> AnyPublisher<(), Never> {
        return Deferred {
            Future { promise in

                self.logDebug("sendNotificationIfAppShouldUpdate Started")

                self.shouldAppUpdate { updateInformation in

                    guard updateInformation.shouldUpdate, let appVersionInformation = updateInformation.versionInformation else {
                        return promise(.success(()))
                    }

                    let message = appVersionInformation.minimumVersionMessage.isEmpty ? String.updateAppContent : appVersionInformation.minimumVersionMessage

                    let content = UNMutableNotificationContent()
                    content.body = message
                    content.sound = .default
                    content.badge = 0

                    self.sendNotification(content: content, identifier: .appUpdateRequired) { _ in
                        promise(.success(()))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }

    func updateTreatmentPerspective() -> AnyPublisher<TreatmentPerspective, ExposureDataError> {
        return self.dataController
            .requestTreatmentPerspective()
            .eraseToAnyPublisher()
    }

    func lastOpenedNotificationCheck() -> AnyPublisher<(), Never> {
        return Deferred {
            Future { promise in

                guard let lastAppLaunch = self.dataController.lastAppLaunchDate else {
                    self.logDebug("`lastOpenedNotificationCheck` skipped as there is no `lastAppLaunchDate`")
                    return promise(.success(()))
                }
                guard let lastExposure = self.dataController.lastExposure else {
                    self.logDebug("`lastOpenedNotificationCheck` skipped as there is no `lastExposureDate`")
                    return promise(.success(()))
                }

                guard let lastUnseenExposureNotificationDate = self.dataController.lastUnseenExposureNotificationDate else {
                    self.logDebug("`lastOpenedNotificationCheck` skipped as there is no `lastUnseenExposureNotificationDate`")
                    return promise(.success(()))
                }

                guard lastAppLaunch < lastUnseenExposureNotificationDate else {
                    self.logDebug("`lastOpenedNotificationCheck` skipped as the app has been opened after the notification")
                    return promise(.success(()))
                }

                let notificationThreshold = TimeInterval(60 * 60 * 3) // 3 hours

                guard lastUnseenExposureNotificationDate.advanced(by: notificationThreshold) < Date() else {
                    self.logDebug("`lastOpenedNotificationCheck` skipped as it hasn't been 3h after initial notification")
                    return promise(.success(()))
                }

                guard lastAppLaunch.advanced(by: notificationThreshold) < Date() else {
                    self.logDebug("`lastOpenedNotificationCheck` skipped as it hasn't been 3h")
                    return promise(.success(()))
                }

                self.logDebug("User has not opened the app in 3 hours.")

                let days = Date().days(sinceDate: lastExposure.date) ?? 0

                let content = UNMutableNotificationContent()
                content.body = .exposureNotificationReminder(.exposureNotificationUserExplanation(.statusNotifiedDaysAgo(days: days)))
                content.sound = .default
                content.badge = 0

                self.sendNotification(content: content, identifier: .exposure) { _ in
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
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
            let lastSuccessfulProcessingDate = dataController.lastSuccessfulProcessingDate,
            lastSuccessfulProcessingDate.advanced(by: timeInterval) < Date()
        else {
            return
        }
        guard let lastLocalNotificationExposureDate = dataController.lastLocalNotificationExposureDate else {
            // We haven't shown a notification to the user before so we should show one now
            return notifyUser()
        }
        guard lastLocalNotificationExposureDate.advanced(by: timeInterval) < Date() else {
            return
        }

        notifyUser()
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
            .flatMap { [weak self] (exposureState) -> AnyPublisher<Bool, Never> in
                let stateActive = [.active, .inactive(.noRecentNotificationUpdates), .inactive(.bluetoothOff)].contains(exposureState.activeState)
                    && (self?.networkStatusStream.networkReachable == true)
                return Just(stateActive).eraseToAnyPublisher()
            }
            .filter { $0 }
            .first()
            .handleEvents(receiveOutput: { [weak self] _ in self?.updateStatusStream() })
            .flatMap { [weak self] (_) -> AnyPublisher<(), Never> in
                return self?
                    .updateWhenRequired()
                    .replaceError(with: ())
                    .eraseToAnyPublisher() ?? Just(()).eraseToAnyPublisher()
            }
            .sink(receiveValue: { _ in })
            .store(in: &disposeBag)

        networkStatusStream
            .networkReachableStream
            .publisher
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.updateStatusStream()
            })
            .filter { $0 } // only update when internet is active
            .map { [weak self] (_) -> AnyPublisher<(), Never> in
                return self?
                    .updateWhenRequired()
                    .replaceError(with: ())
                    .eraseToAnyPublisher() ?? Just(()).eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &disposeBag)
    }

    private func updateStatusStream() {
        guard isActivated else {
            return logDebug("Not Updating Status Stream as not `isActivated`")
        }
        logDebug("Updating Status Stream")

        let noInternetIntervalForShowingWarning = TimeInterval(60 * 60 * 24) // 24 hours
        let hasBeenTooLongSinceLastUpdate: Bool

        if let lastSuccessfulProcessingDate = dataController.lastSuccessfulProcessingDate {
            hasBeenTooLongSinceLastUpdate = lastSuccessfulProcessingDate.advanced(by: noInternetIntervalForShowingWarning) < Date()
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

    private func requestDiagnosisKeys() -> AnyPublisher<[DiagnosisKey], ExposureManagerError> {
        return Future { promise in
            self.exposureManager.getDiagnosisKeys(completion: promise)
        }
        .share()
        .eraseToAnyPublisher()
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

        let receiveCompletion: (Subscribers.Completion<ExposureDataError>) -> () = { result in
            switch result {
            case let .failure(error):
                completion(mapExposureDataError(error))
            default:
                break
            }
        }

        self.dataController
            .upload(diagnosisKeys: keys, labConfirmationKey: labConfirmationKey)
            .map { _ in return ExposureControllerUploadKeysResult.success }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: receiveCompletion,
                  receiveValue: completion)
            .store(in: &disposeBag)
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
    private let exposureManager: ExposureManaging
    private let dataController: ExposureDataControlling
    private var disposeBag = Set<AnyCancellable>()
    private var rxDisposeBag = DisposeBag()
    private var exposureKeyUpdateStream: AnyPublisher<(), ExposureDataError>?
    private let networkStatusStream: NetworkStatusStreaming
    private var isActivated = false
    private var isPushNotificationsEnabled = false
    private let userNotificationCenter: UserNotificationCenter
    private var updateStream: AnyPublisher<(), ExposureDataError>?
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
