/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift
import UserNotifications

protocol ExpiredLabConfirmationNotificationDataOperationProtocol {
    func execute() -> Completable
}

final class ExpiredLabConfirmationNotificationDataOperation: ExpiredLabConfirmationNotificationDataOperationProtocol, Logging {

    init(storageController: StorageControlling,
         userNotificationCenter: UserNotificationCenter) {
        self.storageController = storageController
        self.userNotificationCenter = userNotificationCenter
    }

    // MARK: - ExposureDataOperation

    func execute() -> Completable {

        logDebug("--- START REMOVING EXPIRED LAB CONFIRMATION REQUESTS ---")

        let expiredRequests = getPendingRequests()
            .filter { $0.isExpired }

        if !expiredRequests.isEmpty {
            logDebug("Expired requests: \(expiredRequests.count) Expiration dates: \(expiredRequests.map { String(describing: $0.expiryDate) }.joined(separator: "\n"))")
            notifyUser()
        }

        return removeExpiredRequestsFromStorage(expiredRequests: expiredRequests)
            .do(onCompleted: {
                self.logDebug("--- END REMOVING EXPIRED LAB CONFIRMATION REQUESTS ---")
            })
    }

    // MARK: - Private

    private func getPendingRequests() -> [PendingLabConfirmationUploadRequest] {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) ?? []
    }

    private func removeExpiredRequestsFromStorage(expiredRequests: [PendingLabConfirmationUploadRequest]) -> Completable {

        logDebug("Start storage removal for expired lab confirmation requests")

        return .create { [weak self] observer in

            guard let strongSelf = self else {
                observer(.error(ExposureDataError.internalError))
                return Disposables.create()
            }

            if expiredRequests.isEmpty {
                self?.logDebug("There are no expired lab confirmation requests")
                observer(.completed)
                return Disposables.create()
            }

            self?.logDebug("Removing lab confirmations: \(expiredRequests.count) Expiration dates: \(expiredRequests.map { String(describing: $0.expiryDate) }.joined(separator: "\n"))")

            strongSelf.storageController.requestExclusiveAccess { storageController in

                // get stored pending requests
                let previousRequests = storageController
                    .retrieveObject(identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) ?? []

                let requestsToStore = previousRequests.filter { request in
                    expiredRequests.contains(request) == false
                }

                strongSelf.logDebug("Storing new pending lab confirmation requests: \(requestsToStore)")

                // store back
                storageController.store(object: requestsToStore, identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) { _ in
                    strongSelf.logDebug("Successfully stored new pending lab confirmation requests: \(requestsToStore)")
                    observer(.completed)
                }
            }
            return Disposables.create()
        }
    }

    private func notifyUser() {
        func notify() {
            let content = UNMutableNotificationContent()
            content.sound = UNNotificationSound.default
            content.body = .notificationUploadFailedNotification
            content.badge = 0

            let request = UNNotificationRequest(identifier: PushNotificationIdentifier.uploadFailed.rawValue,
                                                content: content,
                                                trigger: getCalendarTriggerForGGDOpeningHourIfNeeded())

            userNotificationCenter.add(request) { error in
                if let error = error {
                    self.logError("\(error.localizedDescription)")
                }
            }
        }

        userNotificationCenter.getAuthorizationStatus { status in
            guard status == .authorized else {
                self.logError("Cannot notify user `authorizationStatus`: \(status)")
                return
            }
            notify()
        }
    }

    /// Generates a UNCalendarNotificationTrigger if the current time is outside the GGD working hours
    func getCalendarTriggerForGGDOpeningHourIfNeeded() -> UNCalendarNotificationTrigger? {

        let date = currentDate()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        if hour > 20 || hour < 8 {

            var dateComponents = DateComponents()
            dateComponents.hour = 8
            dateComponents.minute = 0
            dateComponents.timeZone = TimeZone(identifier: "Europe/Amsterdam")
            return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        }

        return nil
    }

    private let storageController: StorageControlling
    private let userNotificationCenter: UserNotificationCenter
    private let disposeBag = DisposeBag()
}

extension PendingLabConfirmationUploadRequest {
    var isExpired: Bool {
        return expiryDate < Date()
    }
}
