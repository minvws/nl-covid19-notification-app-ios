/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation
import UIKit

final class ExposureController: ExposureControlling, Logging {

    init(mutableStateStream: MutableExposureStateStreaming,
         exposureManager: ExposureManaging?,
         dataController: ExposureDataControlling,
         networkStatusStream: NetworkStatusStreaming) {
        self.mutableStateStream = mutableStateStream
        self.exposureManager = exposureManager
        self.dataController = dataController
        self.networkStatusStream = networkStatusStream
    }

    deinit {
        disposeBag.forEach { $0.cancel() }
    }

    // MARK: - ExposureControlling

    func activate() {
        guard isActivated == false else {
            assertionFailure("Should only activate ExposureController once")
            return
        }

        isActivated = true

        guard let exposureManager = exposureManager else {
            updateStatusStream()
            return
        }

        exposureManager.activate { _ in
            self.updateStatusStream()
        }

        mutableStateStream
            .exposureState
            .combineLatest(networkStatusStream.networkStatusStream) { (exposureState, networkState) -> Bool in
                return [.active, .inactive(.noRecentNotificationUpdates)].contains(exposureState.activeState)
                    && networkState
            }
            .filter { $0 }
            .first()
            .handleEvents(receiveOutput: { [weak self] _ in self?.updateStatusStream() })
            .flatMap { [weak self] _ in
                self?
                    .updateWhenRequired()
                    .replaceError(with: ())
                    .eraseToAnyPublisher() ?? Just(()).eraseToAnyPublisher()
            }
            .sink(receiveValue: { _ in })
            .store(in: &disposeBag)

        networkStatusStream
            .networkStatusStream
            .handleEvents(receiveOutput: { [weak self] _ in self?.updateStatusStream() })
            .flatMap { [weak self] _ in
                self?
                    .updateWhenRequired()
                    .replaceError(with: ())
                    .eraseToAnyPublisher() ?? Just(()).eraseToAnyPublisher()
            }
            .sink(receiveValue: { _ in })
            .store(in: &disposeBag)
    }

    func getMinimumiOSVersion(_ completion: @escaping (String?) -> ()) {
        return dataController
            .getMinimumiOSVersion()
            .sink(receiveCompletion: { result in
                guard case .failure = result else { return }

                completion(nil)
            },
            receiveValue: completion)
            .store(in: &disposeBag)
    }

    func getAppStoreURL(_ completion: @escaping (String?) -> ()) {
        return dataController
            .getAppStoreURL()
            .sink(receiveCompletion: { result in
                guard case .failure = result else { return }

                completion(nil)
            },
            receiveValue: completion)
            .store(in: &disposeBag)
    }

    func getMinimumVersionMessage(_ completion: @escaping (String?) -> ()) {
        return dataController
            .getMinimumVersionMessage()
            .sink(receiveCompletion: { result in
                guard case .failure = result else { return }

                completion(nil)
            },
            receiveValue: completion)
            .store(in: &disposeBag)
    }

    func refreshStatus() {
        updateStatusStream()
    }

    func updateWhenRequired() -> AnyPublisher<(), ExposureDataError> {
        // update when active, or when inactive due to no recent updates
        guard [.active, .inactive(.noRecentNotificationUpdates)].contains(mutableStateStream.currentExposureState?.activeState) else {
            return Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }
        return fetchAndProcessExposureKeySets()
    }

    func processPendingUploadRequests() -> AnyPublisher<(), ExposureDataError> {
        return dataController
            .processPendingUploadRequests()
    }

    func notifiyUserIfRequired() {
        let timeInterval = TimeInterval(60 * 60 * 24) // 24 hours
        guard dataController.lastSuccessfulFetchDate.advanced(by: timeInterval) < Date() else {
            return
        }
        guard let lastLocalNotificationExposureDate = dataController.lastLocalNotificationExposureDate else {
            // We haven't shown a notification to the user before so we should show one now
            return notifyUserAppNeedsUpdate()
        }
        guard lastLocalNotificationExposureDate.advanced(by: timeInterval) < Date() else {
            return
        }
        notifyUserAppNeedsUpdate()
    }

    func requestExposureNotificationPermission() {
        exposureManager?.setExposureNotificationEnabled(true) { _ in
            self.updateStatusStream()
        }
    }

    func requestPushNotificationPermission(_ completion: @escaping (() -> ())) {
        let uncc = UNUserNotificationCenter.current()

        uncc.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }

        uncc.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func fetchAndProcessExposureKeySets() -> AnyPublisher<(), ExposureDataError> {
        guard let exposureManager = exposureManager else {
            // no exposureManager, nothing to do
            return Just(()).setFailureType(to: ExposureDataError.self).eraseToAnyPublisher()
        }

        if let exposureKeyUpdateStream = exposureKeyUpdateStream {
            // already fetching
            return exposureKeyUpdateStream.share().eraseToAnyPublisher()
        }

        let stream = dataController
            .fetchAndProcessExposureKeySets(exposureManager: exposureManager)
            .handleEvents(
                receiveCompletion: { completion in
                    self.updateStatusStream()
                    self.exposureKeyUpdateStream = nil
                },
                receiveCancel: {
                    self.updateStatusStream()
                    self.exposureKeyUpdateStream = nil
            })
            .eraseToAnyPublisher()

        exposureKeyUpdateStream = stream

        return stream.share().eraseToAnyPublisher()
    }

    func confirmExposureNotification() {
        dataController
            .removeLastExposure()
            .sink { [weak self] _ in
                self?.updateStatusStream()
            }
            .store(in: &disposeBag)
    }

    func requestLabConfirmationKey(completion: @escaping (Result<ExposureConfirmationKey, ExposureDataError>) -> ()) {
        let receiveCompletion: (Subscribers.Completion<ExposureDataError>) -> () = { result in
            if case let .failure(error) = result {
                completion(.failure(error))
            }
        }

        let receiveValue: (ExposureConfirmationKey) -> () = { key in
            completion(.success(key))
        }

        dataController
            .requestLabConfirmationKey()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
            .store(in: &disposeBag)
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

    private func updateStatusStream() {
        guard let exposureManager = exposureManager else {
            mutableStateStream.update(state: .init(notifiedState: notifiedState,
                                                   activeState: .inactive(.requiresOSUpdate)))
            return
        }

        let noInternetIntervalForShowingWarning = TimeInterval(60 * 60 * 24) // 24 hours
        let hasBeenTooLongSinceLastUpdate = dataController.lastSuccessfulFetchDate.advanced(by: noInternetIntervalForShowingWarning) < Date()

        let activeState: ExposureActiveState
        let exposureManagerStatus = exposureManager.getExposureNotificationStatus()

        switch exposureManagerStatus {
        case .active where hasBeenTooLongSinceLastUpdate:
            activeState = .inactive(.noRecentNotificationUpdates)
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
        case let .inactive(error) where error == .unknown || error == .internalTypeMismatch:
            // Most likely due to code signing issues
            activeState = .inactive(.disabled)
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
            guard let exposureManager = self.exposureManager else {
                // ExposureController not activated, mark flow as failure
                promise(.failure(.unknown))
                return
            }

            exposureManager.getDiagnonisKeys(completion: promise)
        }
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
            case .inactive:
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

    private func notifyUserAppNeedsUpdate() {
        let unc = UNUserNotificationCenter.current()
        unc.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                return
            }
            let content = UNMutableNotificationContent()
            content.title = Localization.string(for: "status.appState.inactive.title")
            content.body = Localization.string(for: "status.appState.inactive.description", ["CoronaMelder"])
            content.sound = UNNotificationSound.default
            content.badge = 0

            let identifier = "nl.rijksoverheid.en.inactive"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

            unc.add(request) { [weak self] error in
                if let error = error {
                    self?.logError("\(error.localizedDescription)")
                } else {
                    self?.dataController.updateLastLocalNotificationExposureDate(Date())
                }
            }
        }
    }

    private let mutableStateStream: MutableExposureStateStreaming
    private let exposureManager: ExposureManaging?
    private let dataController: ExposureDataControlling
    private var disposeBag = Set<AnyCancellable>()
    private var exposureKeyUpdateStream: AnyPublisher<(), ExposureDataError>?
    private let networkStatusStream: NetworkStatusStreaming
    private var isActivated = false
}

extension LabConfirmationKey: ExposureConfirmationKey {
    var key: String {
        return identifier
    }

    var expiration: Date {
        return validUntil
    }
}
