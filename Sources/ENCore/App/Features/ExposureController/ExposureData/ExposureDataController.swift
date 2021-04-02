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

    @available(*, deprecated)
    // Leaving this in place because the enum needs a case and we might want to know in the future what kind of announcements we could have stored before
    case interopAnnouncement
}

struct PreviousExposureDate: Codable {
    /// A sha256 hash of a timestamp string
    let exposureDateHash: String
    let addDate: Date
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
    static let previousExposureDates = CodableStorageKey<[PreviousExposureDate]>(name: "previousExposureDates",
                                                                    storeType: .secure)
    static let exposureFirstNotificationReceivedDate = CodableStorageKey<Date>(name: "exposureNotificationReceivedDate",
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
         environmentController: EnvironmentControlling,
         randomNumberGenerator: RandomNumberGenerating) {
        self.operationProvider = operationProvider
        self.storageController = storageController
        self.environmentController = environmentController
        self.randomNumberGenerator = randomNumberGenerator

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
    
    /// The date on which a notification was first sent to the user for the current / latest exposure
    var exposureFirstNotificationReceivedDate: Date? {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureFirstNotificationReceivedDate)
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
    
    func removeFirstNotificationReceivedDate() -> Completable {
        return .create { observer in
            self.storageController.removeData(for: ExposureDataStorageKey.exposureFirstNotificationReceivedDate) { _ in
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
    
    func isKnownPreviousExposureDate(_ exposureDate: Date) -> Bool {
        let startOfDayHash = createPreviousExposureDateHash(exposureDate)
        return previousExposureDates.contains(where: { $0.exposureDateHash == startOfDayHash })
    }
    
    func addPreviousExposureDate(_ exposureDate: Date) -> Completable {
        return storePreviousExposureDate(exposureDate)
    }
    
    func addDummyPreviousExposureDate() -> Completable {
        // dummy exposure dates are a random date between 1/1/1970 and 1/1/2000
        let minimumDateTimestamp: Double = 0
        guard let maximumDateTimeStamp = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1))?.timeIntervalSince1970 else {
            return .error(ExposureDataError.internalError)
        }
        
        let dummyTimeStamp = randomNumberGenerator.randomDouble(in: minimumDateTimestamp ..< Double(maximumDateTimeStamp))
        return storePreviousExposureDate(Date(timeIntervalSince1970: dummyTimeStamp))
    }
    
    /// Removes all previously known exposure dates for which the notification date was longer than 14 days ago
    func purgePreviousExposureDates() -> Completable {
        let newDates = previousExposureDates.filter { (date) -> Bool in
            let age = currentDate().days(sinceDate: date.addDate)
            return (age ?? 0) <= 14
        }
        
        return .create { observer in
            self.storageController.requestExclusiveAccess { storageController in
                storageController.store( object: newDates, identifiedBy: ExposureDataStorageKey.previousExposureDates) { error in
                    if let error = error {
                        observer(.error(error))
                    } else {
                        observer(.completed)
                    }
                }
            }
            return Disposables.create()
        }
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
    
    func updateExposureFirstNotificationReceivedDate(_ date: Date) {

        storageController.requestExclusiveAccess { storageController in
            storageController.store(
                object: date,
                identifiedBy: ExposureDataStorageKey.exposureFirstNotificationReceivedDate,
                completion: { _ in }
            )
        }
    }

    // MARK: - Private

    private var previousExposureDates: [PreviousExposureDate] {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.previousExposureDates) ?? []
    }
    
    func createPreviousExposureDateHash(_ date: Date) -> String? {
        let startOfDay = Calendar(identifier: .gregorian).startOfDay(for: date).timeIntervalSince1970
        return "\(startOfDay)".data(using: .utf8)?.sha256String
    }
    
    private func storePreviousExposureDate(_ exposureDate: Date) -> Completable {
        guard let startOfDayHash = createPreviousExposureDateHash(exposureDate) else {
            return .error(ExposureDataError.internalError)
        }
        
        let newDates = previousExposureDates + [.init(exposureDateHash: startOfDayHash, addDate: currentDate())]
        
        return .create { observer in
            self.storageController.requestExclusiveAccess { storageController in
                storageController.store(
                    object: newDates,
                    identifiedBy: ExposureDataStorageKey.previousExposureDates,
                    completion: { error in
                        if let error = error {
                            observer(.error(error))
                        } else {
                            observer(.completed)
                        }
                    }
                )
            }
            return Disposables.create()
        }
    }
    
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
    private let randomNumberGenerator: RandomNumberGenerating
    private let disposeBag = DisposeBag()
}
