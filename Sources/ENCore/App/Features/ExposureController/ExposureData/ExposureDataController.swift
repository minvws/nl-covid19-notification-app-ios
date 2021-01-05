/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation
import RxSwift

enum Announcement: String, Codable {
    case interopAnnouncement
}

struct ExposureDataStorageKey {
    static let labConfirmationKey = CodableStorageKey<LabConfirmationKey>(name: "labConfirmationKey",
                                                                          storeType: .secure)
    static let appManifest = CodableStorageKey<ApplicationManifest>(name: "appManifest",
                                                                    storeType: .insecure(volatile: true))
    static let appConfiguration = CodableStorageKey<ApplicationConfiguration>(name: "appConfiguration",
                                                                              storeType: .insecure(volatile: true))
    static let appConfigurationSignature = CodableStorageKey<ApplicationConfiguration>(name: "appConfigurationSignature",
                                                                                       storeType: .secure)
    static let exposureKeySetsHolders = CodableStorageKey<[ExposureKeySetHolder]>(name: "exposureKeySetsHolders",
                                                                                  storeType: .insecure(volatile: false))
    static let lastExposureReport = CodableStorageKey<ExposureReport>(name: "exposureReport",
                                                                      storeType: .secure)
    static let lastExposureProcessingDate = CodableStorageKey<Date>(name: "lastExposureProcessingDate",
                                                                    storeType: .insecure(volatile: false))
    static let lastLocalNotificationExposureDate = CodableStorageKey<Date>(name: "lastLocalNotificationExposureDate",
                                                                           storeType: .insecure(volatile: false))
    static let lastENStatusCheck = CodableStorageKey<Date>(name: "lastENStatusCheck",
                                                           storeType: .insecure(volatile: false))
    static let lastAppLaunchDate = CodableStorageKey<Date>(name: "lastAppLaunchDate",
                                                           storeType: .insecure(volatile: false))
    static let exposureConfiguration = CodableStorageKey<ExposureRiskConfiguration>(name: "exposureConfiguration",
                                                                                    storeType: .insecure(volatile: false))
    static let pendingLabUploadRequests = CodableStorageKey<[PendingLabConfirmationUploadRequest]>(name: "pendingLabUploadRequests",
                                                                                                   storeType: .secure)
    static let firstRunIdentifier = CodableStorageKey<Bool>(name: "firstRunIdentifier",
                                                            storeType: .insecure(volatile: false))
    static let initialKeySetsIgnored = CodableStorageKey<Bool>(name: "initialKeySetsIgnored",
                                                               storeType: .insecure(volatile: false))
    static let exposureApiCallDates = CodableStorageKey<[Date]>(name: "exposureApiCalls",
                                                                storeType: .insecure(volatile: false))
    static let exposureApiBackgroundCallDates = CodableStorageKey<[Date]>(name: "exposureApiBackgroundCallDates",
                                                                          storeType: .insecure(volatile: false))
    static let onboardingCompleted = CodableStorageKey<Bool>(name: "onboardingCompleted",
                                                             storeType: .insecure(volatile: false))
    static let lastRanAppVersion = CodableStorageKey<String>(name: "lastRanAppVersion",
                                                             storeType: .insecure(volatile: false))
    static let treatmentPerspective = CodableStorageKey<TreatmentPerspective>(name: "treatmentPerspective",
                                                                              storeType: .insecure(volatile: false))
    static let lastUnseenExposureNotificationDate = CodableStorageKey<Date>(name: "lastUnseenExposureNotificationDate",
                                                                            storeType: .insecure(volatile: false))
    static let seenAnnouncements = CodableStorageKey<[Announcement]>(name: "seenAnnouncements",
                                                                     storeType: .insecure(volatile: false))
    static let lastDecoyProcessDate = CodableStorageKey<Date>(name: "lastDecoyProcessDate",
                                                              storeType: .insecure(volatile: false))
}

final class ExposureDataController: ExposureDataControlling, Logging {

    private(set) var isFirstRun: Bool = false

    init(operationProvider: ExposureDataOperationProvider,
         storageController: StorageControlling,
         environmentController: EnvironmentControlling) {
        self.operationProvider = operationProvider
        self.storageController = storageController
        self.environmentController = environmentController

        detectFirstRunAndEraseKeychainIfRequired()
        compareAndUpdateLastRanAppVersion(isFirstRun: isFirstRun)
    }

    // MARK: - ExposureDataControlling

    func requestTreatmentPerspective() -> AnyPublisher<TreatmentPerspective, ExposureDataError> {
        return Deferred {
            Future { promise in
                self.rxRequestApplicationManifest()
                    .flatMap { _ in
                        self.operationProvider
                            .requestTreatmentPerspectiveDataOperation
                            .execute()
                    }
                    .subscribe(onNext: { treatmentPerspective in
                        promise(.success(treatmentPerspective))
                    }, onError: { error in
                        let convertedError = (error as? ExposureDataError) ?? ExposureDataError.internalError
                        return promise(.failure(convertedError))
                    })
                    .disposed(by: self.rxDisposeBag)
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Exposure Detection

    func fetchAndProcessExposureKeySets(exposureManager: ExposureManaging) -> AnyPublisher<(), ExposureDataError> {
        return requestApplicationConfiguration()
            .flatMap { _ in
                self.fetchAndStoreExposureKeySets().catch { _ in
                    self.processStoredExposureKeySets(exposureManager: exposureManager)
                }
            }
            .flatMap { _ in
                self.processStoredExposureKeySets(exposureManager: exposureManager)
            }
            .share()
            .eraseToAnyPublisher()
    }

    var lastExposure: ExposureReport? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastExposureReport)
    }

    var lastLocalNotificationExposureDate: Date? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastLocalNotificationExposureDate)
    }

    var lastSuccessfulProcessingDate: Date? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastExposureProcessingDate)
    }

    var lastENStatusCheckDate: Date? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastENStatusCheck)
    }

    var lastAppLaunchDate: Date? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastAppLaunchDate)
    }

    func setLastENStatusCheckDate(_ date: Date) {
        storageController.store(object: date, identifiedBy: ExposureDataStorageKey.lastENStatusCheck, completion: { _ in })
    }

    func setLastAppLaunchDate(_ date: Date) {
        storageController.store(object: date, identifiedBy: ExposureDataStorageKey.lastAppLaunchDate, completion: { _ in })
    }

    func clearLastUnseenExposureNotificationDate() {
        storageController.removeData(for: ExposureDataStorageKey.lastUnseenExposureNotificationDate, completion: { _ in })
    }

    var lastUnseenExposureNotificationDate: Date? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastUnseenExposureNotificationDate)
    }

    func setLastDecoyProcessDate(_ date: Date) {
        storageController.store(object: date, identifiedBy: ExposureDataStorageKey.lastDecoyProcessDate, completion: { _ in })
    }

    var canProcessDecoySequence: Bool {
        guard let date = lastDecoyProcessDate else {
            return true
        }
        return !Calendar.current.isDateInToday(date)
    }

    func removeLastExposure() -> AnyPublisher<(), Never> {
        return Future { promise in
            self.storageController.removeData(for: ExposureDataStorageKey.lastExposureReport) { _ in
                promise(.success(()))
            }
        }
        .share()
        .eraseToAnyPublisher()
    }

    private func processStoredExposureKeySets(exposureManager: ExposureManaging) -> AnyPublisher<(), ExposureDataError> {
        self.logDebug("ExposureDataController: processStoredExposureKeySets")
        return requestExposureRiskConfiguration()
            .flatMap { (configuration) -> AnyPublisher<(), ExposureDataError> in
                guard let operation = self.operationProvider
                    .processExposureKeySetsOperation(exposureManager: exposureManager,
                                                     configuration: configuration) else {
                    self.logDebug("ExposureDataController: Failed to create processExposureKeySetsOperation")
                    return Fail(error: ExposureDataError.internalError).eraseToAnyPublisher()
                }

                return Deferred {
                    Future { promise in

                        return operation
                            .execute()
                            .subscribe { result in
                                return promise(.success(result))
                            } onError: { error in
                                let convertedError = (error as? ExposureDataError) ?? ExposureDataError.internalError
                                return promise(.failure(convertedError))
                            }.disposed(by: self.rxDisposeBag)
                    }
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func fetchAndStoreExposureKeySets() -> AnyPublisher<(), ExposureDataError> {
        self.logDebug("ExposureDataController: fetchAndStoreExposureKeySets")
        return requestApplicationManifest()
            .map { (manifest: ApplicationManifest) -> [String] in manifest.exposureKeySetsIdentifiers }
            .flatMap { exposureKeySetsIdentifiers in
                self.operationProvider
                    .requestExposureKeySetsOperation(identifiers: exposureKeySetsIdentifiers)
                    .execute()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - LabFlow

    func processPendingUploadRequests() -> AnyPublisher<(), ExposureDataError> {
        return Deferred {
            Future { promise in
                self.rxRequestApplicationConfiguration()
                    .map { (configuration: ApplicationConfiguration) in
                        Padding(minimumRequestSize: configuration.requestMinimumSize, maximumRequestSize: configuration.requestMaximumSize)
                    }.flatMap { (padding: Padding) in
                        return self.operationProvider
                            .processPendingLabConfirmationUploadRequestsOperation(padding: padding)
                            .execute()
                    }
                    .subscribe { result in
                        return promise(.success(result))
                    } onError: { error in
                        let convertedError = (error as? ExposureDataError) ?? ExposureDataError.internalError
                        return promise(.failure(convertedError))
                    }.disposed(by: self.rxDisposeBag)
            }
        }.eraseToAnyPublisher()
    }

    func processExpiredUploadRequests() -> AnyPublisher<(), ExposureDataError> {
        return Deferred {
            Future { promise in
                self.operationProvider
                    .expiredLabConfirmationNotificationOperation()
                    .execute()
                    .subscribe { manifest in
                        return promise(.success(manifest))
                    } onError: { error in
                        let convertedError = (error as? ExposureDataError) ?? ExposureDataError.internalError
                        return promise(.failure(convertedError))
                    }.disposed(by: self.rxDisposeBag)
            }
        }.eraseToAnyPublisher()
    }

    func requestLabConfirmationKey() -> AnyPublisher<LabConfirmationKey, ExposureDataError> {
        return Deferred {
            Future { promise in
                self.rxRequestApplicationConfiguration()
                    .map { (configuration: ApplicationConfiguration) in
                        return Padding(minimumRequestSize: configuration.requestMinimumSize,
                                       maximumRequestSize: configuration.requestMaximumSize)
                    }
                    .flatMap { (padding: Padding) in
                        self.operationProvider
                            .requestLabConfirmationKeyOperation(padding: padding)
                            .execute()
                    }
                    .subscribe { labConfirmationKey in
                        return promise(.success(labConfirmationKey))
                    } onError: { error in
                        let convertedError = (error as? ExposureDataError) ?? ExposureDataError.internalError
                        return promise(.failure(convertedError))
                    }.disposed(by: self.rxDisposeBag)
            }
        }.eraseToAnyPublisher()
    }

    func upload(diagnosisKeys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey) -> AnyPublisher<(), ExposureDataError> {
        return requestApplicationConfiguration()
            .map { (configuration: ApplicationConfiguration) in
                Padding(minimumRequestSize: configuration.requestMinimumSize,
                        maximumRequestSize: configuration.requestMaximumSize)
            }
            .flatMap { padding in
                return Deferred {
                    Future { promise in
                        self.operationProvider
                            .uploadDiagnosisKeysOperation(diagnosisKeys: diagnosisKeys, labConfirmationKey: labConfirmationKey, padding: padding)
                            .execute()
                            .subscribe { _ in
                                return promise(.success(()))
                            } onError: { error in
                                let convertedError = (error as? ExposureDataError) ?? ExposureDataError.internalError
                                return promise(.failure(convertedError))
                            }.disposed(by: self.rxDisposeBag)
                    }
                }.eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Misc

    func isAppDectivated() -> AnyPublisher<Bool, ExposureDataError> {
        requestApplicationConfiguration()
            .map { applicationConfiguration in
                return applicationConfiguration.decativated
            }
            .eraseToAnyPublisher()
    }

    func getAppVersionInformation() -> AnyPublisher<ExposureDataAppVersionInformation?, ExposureDataError> {
        requestApplicationConfiguration()
            .map { applicationConfiguration in
                return ExposureDataAppVersionInformation(minimumVersion: applicationConfiguration.minimumVersion,
                                                         minimumVersionMessage: applicationConfiguration.minimumVersionMessage,
                                                         appStoreURL: applicationConfiguration.appStoreURL)
            }
            .eraseToAnyPublisher()
    }

    func getAppRefreshInterval() -> AnyPublisher<Int, ExposureDataError> {
        requestApplicationConfiguration()
            .map { applicationConfiguration in
                return applicationConfiguration.manifestRefreshFrequency
            }
            .eraseToAnyPublisher()
    }

    func getDecoyProbability() -> AnyPublisher<Float, ExposureDataError> {
        requestApplicationConfiguration()
            .map { applicationConfiguration in
                return applicationConfiguration.decoyProbability
            }
            .eraseToAnyPublisher()
    }

    func getPadding() -> AnyPublisher<Padding, ExposureDataError> {
        requestApplicationConfiguration()
            .map { applicationConfiguration in
                return Padding(minimumRequestSize: applicationConfiguration.requestMinimumSize,
                               maximumRequestSize: applicationConfiguration.requestMaximumSize)
            }
            .eraseToAnyPublisher()
    }

    func updateLastLocalNotificationExposureDate(_ date: Date) {
        storageController.store(object: date, identifiedBy: ExposureDataStorageKey.lastLocalNotificationExposureDate, completion: { _ in })
    }

    var didCompleteOnboarding: Bool {
        get {
            return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.onboardingCompleted) ?? false
        }
        set {
            storageController.store(object: newValue,
                                    identifiedBy: ExposureDataStorageKey.onboardingCompleted,
                                    completion: { _ in })
        }
    }

    var seenAnnouncements: [Announcement] {
        get {
            return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.seenAnnouncements) ?? []
        }
        set {
            storageController.store(object: newValue,
                                    identifiedBy: ExposureDataStorageKey.seenAnnouncements,
                                    completion: { _ in })
        }
    }

    func getAppointmentPhoneNumber() -> AnyPublisher<String, ExposureDataError> {
        requestApplicationConfiguration()
            .map { applicationConfiguration in
                return applicationConfiguration.appointmentPhoneNumber
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private var lastDecoyProcessDate: Date? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastDecoyProcessDate)
    }

    private func detectFirstRunAndEraseKeychainIfRequired() {
        guard storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.firstRunIdentifier) == nil else {
            // nothing to do, not the first run
            return
        }

        isFirstRun = true

        // clear all secure entries
        storageController.removeData(for: ExposureDataStorageKey.labConfirmationKey, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.lastExposureReport, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.pendingLabUploadRequests, completion: { _ in })

        // mark as successful first run
        storageController.store(object: true, identifiedBy: ExposureDataStorageKey.firstRunIdentifier, completion: { _ in })
    }

    private func requestApplicationConfiguration() -> AnyPublisher<ApplicationConfiguration, ExposureDataError> {
        return Deferred {
            Future { promise in
                self.rxRequestApplicationManifest()
                    .flatMap {
                        self.operationProvider
                            .requestAppConfigurationOperation(identifier: $0.appConfigurationIdentifier)
                            .execute()
                    }
                    .subscribe(onNext: { appConfiguration in
                        promise(.success(appConfiguration))
                    }, onError: { error in
                        let convertedError = (error as? ExposureDataError) ?? ExposureDataError.internalError
                        return promise(.failure(convertedError))
                    })
                    .disposed(by: self.rxDisposeBag)
            }
        }
        .eraseToAnyPublisher()
    }

    private func rxRequestApplicationConfiguration() -> Observable<ApplicationConfiguration> {
        return self.rxRequestApplicationManifest()
            .flatMap {
                self.operationProvider
                    .requestAppConfigurationOperation(identifier: $0.appConfigurationIdentifier)
                    .execute()
            }
    }

    private func requestApplicationManifest() -> AnyPublisher<ApplicationManifest, ExposureDataError> {
        return Deferred {
            Future { promise in
                self.operationProvider
                    .requestManifestOperation
                    .execute()
                    .subscribe { manifest in
                        return promise(.success(manifest))
                    } onError: { error in
                        let convertedError = (error as? ExposureDataError) ?? ExposureDataError.internalError
                        return promise(.failure(convertedError))
                    }.disposed(by: self.rxDisposeBag)
            }
        }.eraseToAnyPublisher()
    }

    private func rxRequestApplicationManifest() -> Observable<ApplicationManifest> {
        return operationProvider.requestManifestOperation.execute()
    }

    private func requestExposureRiskConfiguration() -> AnyPublisher<ExposureConfiguration, ExposureDataError> {
        return Deferred {
            Future { promise in
                self.rxRequestApplicationManifest()
                    .map { (manifest: ApplicationManifest) in manifest.riskCalculationParametersIdentifier }
                    .flatMap { identifier in
                        self.operationProvider
                            .requestExposureConfigurationOperation(identifier: identifier)
                            .execute()
                    }
                    .subscribe(onNext: { riskConfiguration in
                        promise(.success(riskConfiguration))
                    }, onError: { error in
                        let convertedError = (error as? ExposureDataError) ?? ExposureDataError.internalError
                        return promise(.failure(convertedError))
                    })
                    .disposed(by: self.rxDisposeBag)
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Version Management

    private func compareAndUpdateLastRanAppVersion(isFirstRun: Bool) {
        guard let appVersion = environmentController.appVersion else {
            return
        }

        let lastRanVersion = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastRanAppVersion) ?? "1.0.0"

        if appVersion.compare(lastRanVersion, options: .numeric) == .orderedDescending, !isFirstRun {
            executeUpdate(from: lastRanVersion, to: appVersion)
        }

        storageController.store(object: appVersion,
                                identifiedBy: ExposureDataStorageKey.lastRanAppVersion,
                                completion: { _ in })
    }

    private func executeUpdate(from fromVersion: String, to toVersion: String) {

        // Always clear the app manifest on update to prevent stale settings from being used
        // Especially when switching to a new API version, manifest info like the resource bundle ID
        // from the old manifest might not be appropriate for the new API version
        storageController.removeData(for: ExposureDataStorageKey.appManifest, completion: { _ in })

        if toVersion == "1.0.6" {
            // for people updating, mark onboarding as completed. OnboardingCompleted is a new
            // variable to keep track whether people have completed onboarding. For people who update
            // this variable is not set, even though they most likely completed onboarding. Those users
            // will be treated as onboarding completed to prevent everyone who is updating to go through
            // onboarding again
            storageController.store(object: true,
                                    identifiedBy: ExposureDataStorageKey.onboardingCompleted,
                                    completion: { _ in })
        }
    }

    private let operationProvider: ExposureDataOperationProvider
    private let storageController: StorageControlling
    private let environmentController: EnvironmentControlling
    private let rxDisposeBag = DisposeBag()
    private var disposeBag = Set<AnyCancellable>()
}
