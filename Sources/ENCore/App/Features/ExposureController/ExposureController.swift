/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import Foundation
import UIKit

final class ExposureController: ExposureControlling {

    init(mutableStateStream: MutableExposureStateStreaming,
         exposureManager: ExposureManaging?,
         dataController: ExposureDataControlling) {
        self.mutableStateStream = mutableStateStream
        self.exposureManager = exposureManager
        self.dataController = dataController
    }

    deinit {
        disposeBag.forEach { $0.cancel() }
    }

    // MARK: - ExposureControlling

    func activate() {
        guard let exposureManager = exposureManager else {
            updateStatusStream()
            return
        }

        exposureManager.activate { _ in
            self.updateStatusStream()
        }
    }

    func refreshStatus() {
        updateStatusStream()
    }

    func updateWhenRequired() {
        guard case .active = mutableStateStream.currentExposureState?.activeState else { return }

        fetchAndProcessExposureKeySets {
            // done
        }
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

    func fetchAndProcessExposureKeySets(_ completion: @escaping () -> ()) {
        guard let exposureManager = exposureManager else {
            // no exposureManager, nothing to do
            completion()
            return
        }

        guard exposureKeyUpdateCancellable == nil else {
            // already fetching
            completion()
            return
        }

        exposureKeyUpdateCancellable = dataController
            .fetchAndProcessExposureKeySets(exposureManager: exposureManager)
            .sink(receiveCompletion: { [weak self] _ in
                self?.updateStatusStream()
                self?.exposureKeyUpdateCancellable = nil

                completion()
            },
            receiveValue: { _ in })
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

        let activeState: ExposureActiveState

        switch exposureManager.getExposureNotificationStatus() {
        case .active:
            activeState = .active
        case let .inactive(error) where error == .bluetoothOff:
            activeState = .inactive(.bluetoothOff)
        case let .inactive(error) where error == .disabled || error == .restricted:
            activeState = .inactive(.disabled)
        case let .inactive(error) where error == .notAuthorized:
            activeState = .notAuthorized
        case let .inactive(error) where error == .unknown:
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

    private let mutableStateStream: MutableExposureStateStreaming
    private let exposureManager: ExposureManaging?
    private let dataController: ExposureDataControlling
    private var disposeBag = Set<AnyCancellable>()
    private var exposureKeyUpdateCancellable: AnyCancellable?
}

extension LabConfirmationKey: ExposureConfirmationKey {
    var key: String {
        return identifier
    }

    var expiration: Date {
        return validUntil
    }
}
