/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

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
    static let pauseEndDate = CodableStorageKey<Date>(name: "pauseEndDate",
                                                      storeType: .insecure(volatile: false))
    static let hidePauseInformation = CodableStorageKey<Bool>(name: "hidePauseInformation",
                                                              storeType: .insecure(volatile: false))
}

final class ExposureDataController: ExposureDataControlling, Logging {

    private(set) var isFirstRun: Bool = false
    private lazy var pauseEndDateSubject = BehaviorSubject<Date?>(value: pauseEndDate)

    private lazy var lastExposureProcessingDateSubject = BehaviorSubject<Date?>(value: lastSuccessfulExposureProcessingDate)

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

    func updateTreatmentPerspective() -> Completable {
        requestApplicationManifest()
            .flatMapCompletable { _ in
                self.operationProvider
                    .updateTreatmentPerspectiveDataOperation
                    .execute()
            }
    }

    // MARK: - Exposure Detection

    func fetchAndProcessExposureKeySets(exposureManager: ExposureManaging) -> Completable {
        self.requestApplicationConfiguration()
            .flatMapCompletable { _ in
                self.fetchAndStoreExposureKeySets().catch { _ in
                    self.processStoredExposureKeySets(exposureManager: exposureManager)
                }
            }
            .andThen(processStoredExposureKeySets(exposureManager: exposureManager))
    }

    var lastExposure: ExposureReport? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastExposureReport)
    }

    var lastLocalNotificationExposureDate: Date? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastLocalNotificationExposureDate)
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

    func removeLastExposure() -> Completable {
        return .create { observer in
            self.storageController.removeData(for: ExposureDataStorageKey.lastExposureReport) { _ in
                observer(.completed)
            }
            return Disposables.create()
        }
    }

    private func processStoredExposureKeySets(exposureManager: ExposureManaging) -> Completable {
        self.logDebug("ExposureDataController: processStoredExposureKeySets")
        return requestExposureRiskConfiguration()
            .flatMapCompletable { configuration in
                self.operationProvider
                    .processExposureKeySetsOperation(exposureManager: exposureManager, exposureDataController: self, configuration: configuration)
                    .execute()
            }
    }

    private func fetchAndStoreExposureKeySets() -> Completable {
        self.logDebug("ExposureDataController: fetchAndStoreExposureKeySets")
        return requestApplicationManifest()
            .map { (manifest: ApplicationManifest) -> [String] in
                manifest.exposureKeySetsIdentifiers
            }
            .flatMapCompletable { exposureKeySetsIdentifiers in
                self.operationProvider
                    .requestExposureKeySetsOperation(identifiers: exposureKeySetsIdentifiers)
                    .execute()
            }
    }

    // MARK: - LabFlow

    func processPendingUploadRequests() -> Completable {
        return getPadding()
            .flatMapCompletable { (padding: Padding) in
                return self.operationProvider
                    .processPendingLabConfirmationUploadRequestsOperation(padding: padding)
                    .execute()
            }
    }

    func processExpiredUploadRequests() -> Completable {
        return operationProvider
            .expiredLabConfirmationNotificationOperation()
            .execute()
    }

    func requestLabConfirmationKey() -> Single<LabConfirmationKey> {
        getPadding()
            .flatMap { (padding: Padding) in
                self.operationProvider
                    .requestLabConfirmationKeyOperation(padding: padding)
                    .execute()
            }
    }

    func upload(diagnosisKeys: [DiagnosisKey], labConfirmationKey: LabConfirmationKey) -> Completable {
        getPadding()
            .flatMapCompletable { padding in
                self.operationProvider
                    .uploadDiagnosisKeysOperation(diagnosisKeys: diagnosisKeys, labConfirmationKey: labConfirmationKey, padding: padding)
                    .execute()
            }
    }

    // MARK: - Misc

    func isAppDeactivated() -> Single<Bool> {
        requestApplicationConfiguration()
            .map { applicationConfiguration in
                return applicationConfiguration.decativated
            }
    }

    func getAppVersionInformation() -> Single<ExposureDataAppVersionInformation> {
        requestApplicationConfiguration()
            .map { applicationConfiguration in
                return ExposureDataAppVersionInformation(
                    minimumVersion: applicationConfiguration.minimumVersion,
                    minimumVersionMessage: applicationConfiguration.minimumVersionMessage,
                    appStoreURL: applicationConfiguration.appStoreURL
                )
            }
    }

    func getDecoyProbability() -> Single<Float> {
        requestApplicationConfiguration()
            .map { applicationConfiguration in
                return applicationConfiguration.decoyProbability
            }
    }

    func getPadding() -> Single<Padding> {
        requestApplicationConfiguration()
            .map { applicationConfiguration in
                return Padding(minimumRequestSize: applicationConfiguration.requestMinimumSize,
                               maximumRequestSize: applicationConfiguration.requestMaximumSize)
            }
    }

    var isAppPaused: Bool {
        pauseEndDate != nil
    }

    var pauseEndDateObservable: Observable<Date?> {
        return pauseEndDateSubject
            .distinctUntilChanged()
            .compactMap { $0 }
            .subscribe(on: MainScheduler.instance)
    }

    var pauseEndDate: Date? {
        get {
            return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.pauseEndDate)
        } set {

            if let newDate = newValue {
                self.storageController.requestExclusiveAccess { storageController in
                    storageController.store(
                        object: newDate,
                        identifiedBy: ExposureDataStorageKey.pauseEndDate,
                        completion: { _ in
                            self.pauseEndDateSubject.onNext(newDate)
                        }
                    )
                }
            } else {
                storageController.removeData(for: ExposureDataStorageKey.pauseEndDate, completion: { _ in
                    self.pauseEndDateSubject.onNext(newValue)
                })
            }
        }
    }

    var hidePauseInformation: Bool {
        get {
            return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.hidePauseInformation) ?? false
        } set {
            storageController.store(object: newValue,
                                    identifiedBy: ExposureDataStorageKey.hidePauseInformation,
                                    completion: { _ in })
        }
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

    func getAppointmentPhoneNumber() -> Single<String> {
        requestApplicationConfiguration()
            .map { applicationConfiguration in
                return applicationConfiguration.appointmentPhoneNumber
            }
    }

    var lastSuccessfulExposureProcessingDateObservable: Observable<Date?> {
        return lastExposureProcessingDateSubject
            .distinctUntilChanged()
            .compactMap { $0 }
            .subscribe(on: MainScheduler.instance)
    }

    var lastSuccessfulExposureProcessingDate: Date? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastExposureProcessingDate)
    }

    func updateLastSuccessfulExposureProcessingDate(_ date: Date) {

        storageController.requestExclusiveAccess { storageController in
            storageController.store(
                object: date,
                identifiedBy: ExposureDataStorageKey.lastExposureProcessingDate,
                completion: { _ in
                    self.lastExposureProcessingDateSubject.onNext(date)
                }
            )
        }
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

    private func requestApplicationConfiguration() -> Single<ApplicationConfiguration> {
        return self.requestApplicationManifest()
            .flatMap {
                self.operationProvider
                    .requestAppConfigurationOperation(identifier: $0.appConfigurationIdentifier)
                    .execute()
            }
    }

    private func requestApplicationManifest() -> Single<ApplicationManifest> {
        return operationProvider.requestManifestOperation.execute()
    }

    private func requestExposureRiskConfiguration() -> Single<ExposureConfiguration> {
        requestApplicationManifest()
            .map { (manifest: ApplicationManifest) in
                manifest.riskCalculationParametersIdentifier
            }
            .flatMap { identifier in
                self.operationProvider
                    .requestExposureConfigurationOperation(identifier: identifier)
                    .execute()
            }
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
    private let disposeBag = DisposeBag()
}
