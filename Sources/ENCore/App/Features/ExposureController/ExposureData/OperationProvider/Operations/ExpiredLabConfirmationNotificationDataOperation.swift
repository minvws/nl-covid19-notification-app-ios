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
import UserNotifications

protocol ExpiredLabConfirmationNotificationDataOperationProtocol {
    func execute() -> Observable<()>
}

final class ExpiredLabConfirmationNotificationDataOperation: ExpiredLabConfirmationNotificationDataOperationProtocol, Logging {

    init(storageController: StorageControlling,
         userNotificationCenter: UserNotificationCenter) {
        self.storageController = storageController
        self.userNotificationCenter = userNotificationCenter
    }

    // MARK: - ExposureDataOperation

    func execute() -> Observable<()> {
        let expiredRequests = getPendingRequests()
            .filter { $0.isExpired }

        if !expiredRequests.isEmpty {
            notifyUser()
        }

        logDebug("Expired requests: \(expiredRequests)")

        return removeExpiredRequestsFromStorage(expiredRequests: expiredRequests).share()
    }

    // MARK: - Private

    private func getPendingRequests() -> [PendingLabConfirmationUploadRequest] {
        return storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) ?? []
    }

    private func removeExpiredRequestsFromStorage(expiredRequests: [PendingLabConfirmationUploadRequest]) -> Observable<()> {
        return .create { [weak self] observer in

            guard let strongSelf = self else {
                observer.onError(ExposureDataError.internalError)
                return Disposables.create()
            }

            strongSelf.storageController.requestExclusiveAccess { storageController in

                // get stored pending requests
                let previousRequests = storageController
                    .retrieveObject(identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) ?? []

                let requestsToStore = previousRequests.filter { request in
                    expiredRequests.contains(request) == false
                }

                strongSelf.logDebug("Storing new pending requests: \(requestsToStore)")

                // store back
                storageController.store(object: requestsToStore, identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) { _ in
                    observer.onCompleted()
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
    private let rxDisposeBag = DisposeBag()
}

extension PendingLabConfirmationUploadRequest {
    var isExpired: Bool {
        return expiryDate < Date()
    }
}
