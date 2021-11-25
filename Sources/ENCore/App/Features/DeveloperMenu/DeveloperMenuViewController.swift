/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import MessageUI
import RxSwift
import UIKit

/// @mockable
protocol DeveloperMenuViewControllable: ViewControllable {}

private struct DeveloperItem {
    let title: String
    let subtitle: String
    let action: () -> ()
    let deleteAction: (() -> ())?
    let deleteActionTitle: String?
    let enabled: Bool

    init(title: String, subtitle: String, action: @escaping () -> (), deleteAction: (() -> ())? = nil, deleteActionTitle: String? = nil, enabled: Bool = true) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.deleteAction = deleteAction
        self.deleteActionTitle = deleteActionTitle
        self.enabled = enabled
    }
}

final class DeveloperMenuViewController: TableViewController, DeveloperMenuViewControllable, UIGestureRecognizerDelegate, Logging {
    init(listener: DeveloperMenuListener,
         theme: Theme,
         mutableExposureStateStream: MutableExposureStateStreaming,
         mutableNetworkConfigurationStream: MutableNetworkConfigurationStreaming,
         exposureController: ExposureControlling,
         storageController: StorageControlling,
         featureFlagController: FeatureFlagControlling,
         userNotificationController: UserNotificationControlling) {
        self.listener = listener
        self.mutableExposureStateStream = mutableExposureStateStream
        self.mutableNetworkConfigurationStream = mutableNetworkConfigurationStream
        self.exposureController = exposureController
        self.storageController = storageController
        self.featureFlagController = featureFlagController
        self.userNotificationController = userNotificationController

        super.init(theme: theme)

        attach()
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        view = internalView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        internalView.tableView.delegate = self
        internalView.tableView.dataSource = self
        internalView.tableView.estimatedRowHeight = 44
        internalView.tableView.rowHeight = UITableView.automaticDimension

        view.backgroundColor = .clear
    }

    // MARK: - Internal

    func present(actionItems: [UIAlertAction], title: String, message: String? = nil) {
        let actionViewController = UIAlertController(title: title,
                                                     message: message,
                                                     preferredStyle: .alert)
        actionItems.forEach { actionItem in actionViewController.addAction(actionItem) }

        let cancelItem = UIAlertAction(title: "Cancel",
                                       style: .destructive,
                                       handler: { [weak actionViewController] _ in
                                           actionViewController?.dismiss(animated: true, completion: nil)
                                       })
        actionViewController.addAction(cancelItem)

        present(actionViewController, animated: true, completion: nil)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !isShown
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIndex: Int) -> Int {
        let section = sections[sectionIndex]

        return section.items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection sectionIndex: Int) -> String? {
        let section = sections[sectionIndex]

        return section.title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let cellIdentifier = "developerCell"

        if let aCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
            cell = aCell
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }

        let item = sections[indexPath.section].items[indexPath.row]

        cell.textLabel?.text = item.title
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = item.subtitle
        cell.detailTextLabel?.numberOfLines = 0

        if item.enabled == false {
            cell.detailTextLabel?.text = "Busy ... tap to cancel"
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = sections[indexPath.section].items[indexPath.row]

        item.action()
        reloadData()
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let item = sections[indexPath.section].items[indexPath.row]
        return item.deleteAction != nil
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let item = sections[indexPath.section].items[indexPath.row]
        return item.deleteAction != nil ? [.init(style: .destructive, title: item.deleteActionTitle, handler: { _, _ in item.deleteAction?() })] : nil
    }

    // MARK: - Sections

    private var sections: [(title: String, items: [DeveloperItem])] = []

    private func reloadData() {
        let featureFlagOptions = Feature
            .allCases
            .map { feature in
                DeveloperItem(title: feature.developerMenuDisplayName,
                              subtitle: "Feature Enabled: \(featureFlagController.isFeatureFlagEnabled(feature: feature) ? "Yes" : "No")",
                              action: { [weak self] in self?.toggleFeatureFlag(forFeature: feature) },
                              deleteAction: { [weak self] in self?.resetFeatureFlag(forFeature: feature) },
                              deleteActionTitle: "Reset"
                )
            }

        sections = [
            ("Feature Flags (swipe to reset)", featureFlagOptions),
            ("Show Screens", [
                DeveloperItem(title: "Show Onboarding",
                              subtitle: "Launches Onboarding",
                              action: { [weak self] in self?.launchOnboarding() }),
                DeveloperItem(title: "Show OS Update Screen",
                              subtitle: "Show screen informing user the operating system needs to be updated to support Exposure Notification",
                              action: { [weak self] in self?.listener?.developerMenuRequestUpdateOperatingSystem() }),
                DeveloperItem(title: "Show App Update Screen",
                              subtitle: "Show screen informing user he needs to update the app to keep it working correctly",
                              action: { [weak self] in self?.listener?.developerMenuRequestUpdateApp(appStoreURL: "https://apps.apple.com/nl/app/id1517652429", minimumVersionMessage: nil) })
            ]),
            ("Exposure", [
                DeveloperItem(title: "Change Exposure State",
                              subtitle: "Current: \(mutableExposureStateStream.currentExposureState.activeState.asString)",
                              action: { [weak self] in self?.changeExposureState() }),
                DeveloperItem(title: "Trigger Exposure",
                              subtitle: "Currently exposed: \(mutableExposureStateStream.currentExposureState.notifiedState.asString)",
                              action: { [weak self] in self?.triggerExposure() }),

                DeveloperItem(title: "Trigger Exposure and Schedule Message Flow",
                              subtitle: "Currently exposed: \(mutableExposureStateStream.currentExposureState.notifiedState.asString)",
                              action: { [weak self] in self?.triggerExposureAndScheduleMessage() }),
                DeveloperItem(title: "Upload Exposure Keys",
                              subtitle: "Upload keys after giving permission",
                              action: { [weak self] in self?.uploadKeys() }),
                DeveloperItem(title: "Remove Stored LabConfirmationKey",
                              subtitle: "Last: \(getLastStoredConfirmationKey())",
                              action: { [weak self] in self?.removeStoredConfirmationKey() }),
                DeveloperItem(title: "Remove Last Exposure",
                              subtitle: "Last: \(getLastExposureString())",
                              action: { [weak self] in self?.removeLastExposure() }),
                DeveloperItem(title: "Previously Known Exposure Date",
                              subtitle: "Last: \(getPreviousExposureDate())",
                              action: {}),
                DeveloperItem(title: "Remove Processed KeySets",
                              subtitle: "Will redownload them next time",
                              action: { [weak self] in self?.removeAllExposureKeySets() }),
                DeveloperItem(title: "Download and Process New KeySets",
                              subtitle: "Last time: \(getLastExposureFetchString()), total processed last 24h: \(getNumberOfProcessedKeySetsInLast24Hours()), total unprocessed left: \(getNumberOfUnprocessedKeySets())",
                              action: { [weak self] in self?.fetchAndProcessKeySets() },
                              enabled: !isFetchingKeys),
                DeveloperItem(title: "Retry Pending Upload Requests",
                              subtitle: "Pending Unexpired Requests: \(getPendingUploadRequests())",
                              action: { [weak self] in self?.processPendingUploadRequests() }),
                DeveloperItem(title: "Expire all pending upload requests",
                              subtitle: "Pending Unexpired Requests: \(getPendingUploadRequests())",
                              action: { [weak self] in self?.expirePendingUploadRequests() }),
                DeveloperItem(title: "Process Expired Upload Requests",
                              subtitle: "Expired Requests: \(getExpiredUploadRequests())",
                              action: { [weak self] in self?.processExpiredUploadRequests() }),
                DeveloperItem(title: "Ignore 24h limit of 15 keysets/API calls",
                              subtitle: "Only works with test entitlements, currently set: \(getDailyLimit()), API calls made in last 24h: \(getNumberOfAPICallsInLast24Hours())",
                              action: { [weak self] in self?.toggleDailyLimit() }),
                DeveloperItem(title: "Fetch TEKs using Test function",
                              subtitle: "Only works with test entitlements, currently set: \(getUseTestDiagnosisKeys())",
                              action: { [weak self] in self?.toggleGetTestDiagnosisKeys() }),
                DeveloperItem(title: "Schedule pause time in minutes instead of hours",
                              subtitle: "Currently set to: \(getPauseUnit())",
                              action: { [weak self] in self?.togglePauseTimeUnit() }),
                DeveloperItem(title: "Force use of bundled treatment perspective",
                              subtitle: "Current preference: \(getForceBundledTreatmentPerspective() ? "Bundled" : "Downloaded")",
                              action: { [weak self] in self?.toggleForceBundledTreatmentPerspective() }),
                DeveloperItem(title: "Download latest Treatment Perspective",
                              subtitle: "",
                              action: { [weak self] in self?.downloadLatestTreatmentPerspective() })
            ]),
            ("Storage", [
                DeveloperItem(title: "Erase Local Storage",
                              subtitle: "Deletes all stored local data (excludes data generated by EN framework)",
                              action: { [weak self] in self?.eraseCompleteStorage() }),
                DeveloperItem(title: "Erase App Manifest",
                              subtitle: "Deletes the stored app manifest",
                              action: { [weak self] in self?.eraseAppManifest() })
            ]),
            ("Networking", [
                DeveloperItem(title: "Network Configuration",
                              subtitle: "Current: \(mutableNetworkConfigurationStream.configuration.name)",
                              action: { [weak self] in self?.changeNetworkConfiguration() })
            ]),
            ("Notifications", [
                DeveloperItem(title: "Schedule Exposure Notification",
                              subtitle: "Schedules a push notification. to be sent in 5 seconds.",
                              action: { [weak self] in self?.wantsScheduleNotification(identifier: PushNotificationIdentifier.exposure.rawValue) }),
                DeveloperItem(title: "Schedule Upload Failed Flow",
                              subtitle: "Schedules a push notification. to be sent in 5 seconds",
                              action: { [weak self] in self?.wantsScheduleNotification(identifier: PushNotificationIdentifier.uploadFailed.rawValue) }),
                DeveloperItem(title: "Schedule Pause Expiration Notification",
                              subtitle: "Schedules a pause expiration notification. to be sent in 5 seconds",
                              action: { [weak self] in self?.userNotificationController.schedulePauseExpirationNotification(pauseEndDate: Date().addingTimeInterval(5)) }),
                DeveloperItem(title: "Schedule Not Active Notification",
                              subtitle: "Schedules a notification informing the user the app is not active. to be sent in 5 seconds",
                              action: {
                                  DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                                      self?.userNotificationController.displayNotActiveNotification(completion: { _ in })
                                  }
                              }),
                DeveloperItem(title: "Schedule App Update Required Notification",
                              subtitle: "Schedules a notification informing the user the app should be updated. to be sent in 5 seconds",
                              action: {
                                  DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                                      self?.userNotificationController.displayAppUpdateRequiredNotification(withUpdateMessage: .updateAppContent, completion: { _ in })
                                  }
                              }),
                DeveloperItem(title: "Schedule Exposure Notification",
                              subtitle: "Schedules a notification informing the user of an exposure. to be sent in 5 seconds",
                              action: {
                                  DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                                      self?.userNotificationController.displayExposureNotification(daysSinceLastExposure: 3, completion: { _ in })
                                  }
                              }),
                DeveloperItem(title: "Schedule Exposure Reminder Notification",
                              subtitle: "Schedules a notification reminding the user of an exposure. to be sent in 5 seconds",
                              action: {
                                  DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                                      self?.userNotificationController.displayExposureReminderNotification(daysSinceLastExposure: 3, completion: { _ in })
                                  }
                              }),
                DeveloperItem(title: "Schedule 24H No Activity Notification",
                              subtitle: "Schedules a notification informing the user of a potentially broken app. to be sent in 5 seconds",
                              action: {
                                  DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                                      self?.userNotificationController.display24HoursNoActivityNotification(completion: { _ in })
                                  }
                              }),
                DeveloperItem(title: "Schedule Upload Failed Notification",
                              subtitle: "Schedules a notification informing the user the GGD Key upload failed. Only works between 08:00 - 20:00. To be sent in 5 seconds",
                              action: {
                                  DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                                      self?.userNotificationController.displayUploadFailedNotification()
                                  }
                              }),
                DeveloperItem(title: "Schedule Main AppConfig Local Notification",
                              subtitle: "Schedules a loccal notification triggerd by the AppConfig routing to Main to screen, to ben send in 1 minute.",
                              action: {
                                  self.scheduleRemoteNotification(toScreen: "main")
                              }),
                DeveloperItem(title: "Schedule Share AppConfig Local Notification",
                              subtitle: "Schedules a loccal notification triggerd by the AppConfig routing to Share screen, to ben send in 1 minute.",
                              action: {
                                  self.scheduleRemoteNotification(toScreen: "share")
                              })

            ]),
            ("Logging", [
                DeveloperItem(title: "Log Files",
                              subtitle: "Share the log files",
                              action: { [weak self] in self?.emailLogFiles() })
            ])
        ]

        DispatchQueue.main.async {
            self.internalView.tableView.reloadData()
        }
    }

    // MARK: - Actions

    private func toggleFeatureFlag(forFeature feature: Feature) {
        featureFlagController.toggleFeatureFlag(forFeature: feature)
        internalView.tableView.reloadData()
    }

    private func resetFeatureFlag(forFeature feature: Feature) {
        featureFlagController.resetFeatureFlag(forFeature: feature)
        internalView.tableView.reloadData()
    }

    private func launchOnboarding() {
        hide()

        listener?.developerMenuRequestsOnboardingFlow()
    }

    private func changeExposureState() {
        let options: [ExposureActiveState] = [
            .active,
            .restricted,
            .authorizationDenied,
            .inactive(.bluetoothOff),
            .inactive(.disabled),
            .inactive(.noRecentNotificationUpdates),
            .inactive(.noRecentNotificationUpdatesInternetOff)
        ]

        let actionItems = options.map { (option) -> UIAlertAction in
            let actionHandler: (UIAlertAction) -> () = { [weak self] _ in self?.updateExposureState(to: option) }

            return UIAlertAction(title: option.asString,
                                 style: .default,
                                 handler: actionHandler)
        }

        present(actionItems: actionItems, title: "Update Exposure State")
    }

    private func updateExposureState(to: ExposureActiveState) {
        let exposureState: ExposureState

        let current = mutableExposureStateStream.currentExposureState
        exposureState = .init(notifiedState: current.notifiedState, activeState: to)

        mutableExposureStateStream.update(state: exposureState)
        reloadData()
    }

    private func triggerExposure() {
        let dayOptions = [-15, -14, -13, -6, -5, -4, -3, -2, -1, 0]
        let actionItems = dayOptions.reversed().map { (day) -> UIAlertAction in
            let actionHandler: (UIAlertAction) -> () = { [weak self] _ in
                let exposureDate = Date().addingTimeInterval(.days(Double(day))).startOfDay!
                let exposureReport = ExposureReport(date: exposureDate)

                self?.storageController.store(object: exposureReport, identifiedBy: ExposureDataStorageKey.lastExposureReport) { _ in
                    self?.exposureController.updateExposureFirstNotificationReceivedDate(Date())
                    self?.storageController.store(object: exposureDate, identifiedBy: ExposureDataStorageKey.previousExposureDate) { _ in
                        self?.exposureController.refreshStatus(completion: nil)
                    }
                }
            }

            var title = ""
            if day < 0 {
                title = "\(abs(day)) days ago"
            } else if day == 0 {
                title = "Today"
            }

            return UIAlertAction(title: title,
                                 style: .default,
                                 handler: actionHandler)
        }

        present(actionItems: actionItems, title: "Select exposure date")
    }

    private func triggerExposureAndScheduleMessage() {
        let dayOptions = [-15, -14, -13, -6, -5, -4, -3, -2, -1, 0]
        let actionItems = dayOptions.reversed().map { (day) -> UIAlertAction in
            let actionHandler: (UIAlertAction) -> () = { [weak self] _ in
                let exposureDate = Date().addingTimeInterval(.days(Double(day))).startOfDay!
                let exposureReport = ExposureReport(date: exposureDate)

                self?.storageController.store(object: exposureReport, identifiedBy: ExposureDataStorageKey.lastExposureReport) { _ in
                    self?.exposureController.updateExposureFirstNotificationReceivedDate(Date())
                    self?.storageController.store(object: exposureDate, identifiedBy: ExposureDataStorageKey.previousExposureDate) { _ in
                        self?.exposureController.refreshStatus(completion: nil)
                        self?.wantsScheduleNotification(identifier: PushNotificationIdentifier.exposure.rawValue)
                    }
                }
            }

            var title = ""
            if day < 0 {
                title = "\(abs(day)) days ago"
            } else if day == 0 {
                title = "Today"
            }

            return UIAlertAction(title: title,
                                 style: .default,
                                 handler: actionHandler)
        }

        present(actionItems: actionItems, title: "Select exposure date")
    }

    private func changeNetworkConfiguration() {
        let configurations: [NetworkConfiguration] = [.development, .test, .acceptance, .production]

        let actionItems = configurations.map { (configuration) -> UIAlertAction in
            let actionHandler: (UIAlertAction) -> () = { [weak self] _ in
                self?.mutableNetworkConfigurationStream.update(configuration: configuration)
                self?.eraseCompleteStorage()

                self?.exposureController.refreshStatus(completion: {
                    self?.reloadData()
                })
            }

            return UIAlertAction(title: configuration.name,
                                 style: .default,
                                 handler: actionHandler)
        }

        present(actionItems: actionItems, title: "Update Network Configuration")
    }

    private func downloadLatestTreatmentPerspective() {
        exposureController
            .updateTreatmentPerspective()
            .subscribe(onCompleted: { [weak self] in
                self?.reloadData()
            })
            .disposed(by: disposeBag)
    }

    private func getForceBundledTreatmentPerspective() -> Bool {
        #if DEBUG || USE_DEVELOPER_MENU
            return MessageManagerOverrides.forceBundledTreatmentPerspective
        #else
            return false
        #endif
    }

    private func toggleForceBundledTreatmentPerspective() {
        #if DEBUG || USE_DEVELOPER_MENU
            MessageManagerOverrides.forceBundledTreatmentPerspective.toggle()
        #endif
    }

    private func eraseCompleteStorage() {
        removeLastExposure()
        removeAllExposureKeySets()
        removeStoredConfirmationKey()
        storageController.removeData(for: ExposureDataStorageKey.appManifest, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.appConfiguration, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.labConfirmationKey, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.exposureConfiguration, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.exposureKeySetsHolders, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.lastExposureProcessingDate, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.lastExposureReport, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.lastDecoyProcessDate, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.previousExposureDate, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.ignoreFirstV2Exposure, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.pendingLabUploadRequests, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.seenAnnouncements, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.treatmentPerspective, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.hidePauseInformation, completion: { _ in })
    }

    private func eraseAppManifest() {
        storageController.removeData(for: ExposureDataStorageKey.appManifest, completion: { _ in })
    }

    private func uploadKeys() {
        exposureController.requestLabConfirmationKey { result in
            let actionTitle: String
            let actionItems: [UIAlertAction]

            switch result {
            case let .success(key):
                actionTitle = "Proceed? If yes, don't press any other button after pressing Upload"
                actionItems = [
                    UIAlertAction(title: "Upload using \(key.key)",
                                  style: .default,
                                  handler: { [weak self] _ in self?.continueUploadKey(with: key) })
                ]
            case let .failure(error):
                actionTitle = "Failure: \(error)"
                actionItems = []
            }

            self.present(actionItems: actionItems, title: actionTitle)
        }
    }

    private func continueUploadKey(with key: ExposureConfirmationKey) {
        exposureController.requestUploadKeys(forLabConfirmationKey: key) { result in
            let title = "Result: \(result)"

            self.present(actionItems: [], title: title)
        }
    }

    private func removeStoredConfirmationKey() {
        storageController.removeData(for: ExposureDataStorageKey.labConfirmationKey, completion: { _ in })

        exposureController.refreshStatus {
            self.reloadData()
        }
    }

    private func removeLastExposure() {
        storageController.removeData(for: ExposureDataStorageKey.lastExposureReport, completion: { _ in })

        exposureController.refreshStatus {
            self.reloadData()
        }
    }

    private func removeAllExposureKeySets() {
        storageController.removeData(for: ExposureDataStorageKey.exposureKeySetsHolders, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.lastExposureProcessingDate, completion: { _ in })

        if let folder = LocalPathProvider(fileManager: FileManager.default).path(for: .exposureKeySets) {
            try? FileManager.default.removeItem(at: folder)
        }

        exposureController.refreshStatus {
            self.reloadData()
        }
    }

    private func emailLogFiles() {
        let activityViewController = UIActivityViewController(activityItems: LogHandler.logFiles(),
                                                              applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }

    private var fetchAndProcessDisposable: Disposable?

    private func fetchAndProcessKeySets() {
        guard fetchAndProcessDisposable == nil else {
            fetchAndProcessDisposable?.dispose()
            fetchAndProcessDisposable = nil
            return
        }

        reloadData()

        fetchAndProcessDisposable = exposureController
            .fetchAndProcessExposureKeySets().subscribe { _ in

                self.fetchAndProcessDisposable?.dispose()
                self.fetchAndProcessDisposable = nil

                self.reloadData()
            }
    }

    private func processPendingUploadRequests() {
        exposureController
            .processPendingUploadRequests().subscribe { _ in
                self.reloadData()
            }.disposed(by: disposeBag)
    }

    private func processExpiredUploadRequests() {
        exposureController
            .processExpiredUploadRequests().subscribe { _ in
                self.reloadData()
            }.disposed(by: disposeBag)
    }

    private func expirePendingUploadRequests() {
        guard var pendingRequests = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) else {
            return
        }

        for (index, _) in pendingRequests.enumerated() { pendingRequests[index].expiryDate = Date() }

        storageController.requestExclusiveAccess { storageController in
            storageController.store(object: pendingRequests, identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) { _ in }
        }
    }

    private func toggleDailyLimit() {
        #if DEBUG || USE_DEVELOPER_MENU
            ProcessExposureKeySetsDataOperationOverrides.respectMaximumDailyKeySets.toggle()
        #endif
    }

    private func toggleGetTestDiagnosisKeys() {
        #if DEBUG || USE_DEVELOPER_MENU
            if let useTestDiagnosisKeys = ExposureManagerOverrides.useTestDiagnosisKeys {
                ExposureManagerOverrides.useTestDiagnosisKeys = !useTestDiagnosisKeys
            }

            ExposureManagerOverrides.useTestDiagnosisKeys = false
        #endif
    }

    private func togglePauseTimeUnit() {
        #if DEBUG || USE_DEVELOPER_MENU
            PauseOverrides.useMinutesInsteadOfHours.toggle()
        #endif
    }

    // MARK: - Private

    private func getUseTestDiagnosisKeys() -> String {
        #if DEBUG || USE_DEVELOPER_MENU
            if let useTestDiagnosisKeys = ExposureManagerOverrides.useTestDiagnosisKeys {
                return useTestDiagnosisKeys ? "Yes" : "No"
            }

            return "Yes"
        #else
            return "No"
        #endif
    }

    private func getDailyLimit() -> String {
        #if DEBUG || USE_DEVELOPER_MENU
            return ProcessExposureKeySetsDataOperationOverrides.respectMaximumDailyKeySets ? "15" : "unlimited"
        #else
            return "None"
        #endif
    }

    private func getPauseUnit() -> String {
        #if DEBUG || USE_DEVELOPER_MENU
            return PauseOverrides.useMinutesInsteadOfHours ? "minutes" : "hours"
        #else
            return "hours"
        #endif
    }

    private func getNumberOfAPICallsInLast24Hours() -> Int {
        let apiCalls = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureApiCallDates) ?? []

        guard let cutOffDate = Calendar.current.date(byAdding: .hour, value: -24, to: Date()) else {
            return 0
        }

        let wasProcessedInLast24h: (Date) -> Bool = { date in
            date > cutOffDate
        }

        return apiCalls
            .filter(wasProcessedInLast24h)
            .count
    }

    private func getNumberOfProcessedKeySetsInLast24Hours() -> Int {
        guard let cutOffDate = Calendar.current.date(byAdding: .hour, value: -24, to: Date()) else {
            return 0
        }

        let wasProcessedInLast24h: (ExposureKeySetHolder) -> Bool = { keySetHolder in
            guard let processDate = keySetHolder.processDate else {
                return false
            }

            return processDate > cutOffDate
        }

        return (storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? [])
            .filter(wasProcessedInLast24h)
            .count
    }

    private func getNumberOfUnprocessedKeySets() -> Int {
        return (storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureKeySetsHolders) ?? [])
            .filter { $0.processed == false }
            .count
    }

    private func getPendingUploadRequests() -> String {
        guard let pendingRequests = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) else {
            return "None"
        }

        return "\(pendingRequests.filter { !$0.isExpired }.count)"
    }

    private func getExpiredUploadRequests() -> String {
        guard let pendingRequests = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) else {
            return "None"
        }

        return "\(pendingRequests.filter { $0.isExpired }.count)"
    }

    private func getLastStoredConfirmationKey() -> String {
        storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.labConfirmationKey)?.identifier ?? "None"
    }

    private func getLastExposureString() -> String {
        guard let last = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastExposureReport) else {
            return "None"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        return "\(dateFormatter.string(from: last.date))"
    }

    private func getLastExposureFetchString() -> String {
        guard let last = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.lastExposureProcessingDate) else {
            return "None"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return "\(dateFormatter.string(from: last))"
    }

    private func getPreviousExposureDate() -> String {
        guard let last = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.previousExposureDate) else {
            return "None"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        return "\(dateFormatter.string(from: last))"
    }

    private func wantsScheduleNotification(identifier: String) {
        let unc = UNUserNotificationCenter.current()
        unc.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized {
                    self?.scheduleNotification(identifier: identifier)
                } else {
                    self?.displayNotificationError()
                }
            }
        }
    }

    private func displayNotificationError() {
        let alertController = UIAlertController(title: "Push Notification Error",
                                                message: "Push Notifications are not enabled, please go through the Onboarding Flow and enable push notifcations",
                                                preferredStyle: .alert)
        let cancelItem = UIAlertAction(title: "Close",
                                       style: .destructive,
                                       handler: { [weak alertController] _ in
                                           alertController?.dismiss(animated: true, completion: nil)
                                       })
        alertController.addAction(cancelItem)
        present(alertController, animated: true, completion: nil)
    }

    private func scheduleNotification(identifier: String) {
        let content = UNMutableNotificationContent()
        content.sound = UNNotificationSound.default
        content.badge = 0

        switch identifier {
        case PushNotificationIdentifier.inactive.rawValue:
            return
        case PushNotificationIdentifier.uploadFailed.rawValue:
            content.body = .notificationUploadFailedNotification
        case PushNotificationIdentifier.enStatusDisabled.rawValue:
            return
        default:
            content.title = .messageDefaultTitle
            content.body = .messageDefaultBody
        }

        let date = Date(timeIntervalSinceNow: 5)
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        let unc = UNUserNotificationCenter.current()
        unc.add(request) { error in
            if let error = error {
                self.logError("\(error.localizedDescription)")
            }
        }
        hide()
    }

    private func show() {
        guard let window = window else { return }

        view.frame = window.bounds
        window.addSubview(view)

        reloadData()

        internalView.showContentView()
        internalView.showBackgroundView()

        isShown = true
    }

    private func hide() {
        internalView.hideContentView()
        internalView.hideBackgroundView { _ in
            self.view.removeFromSuperview()
        }

        isShown = false
    }

    @objc
    private func didSwipe(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .ended where !isShown:
            show()
        default:
            break
        }
    }

    @objc
    private func didTapBackground() {
        hide()
    }

    private func attach() {
        guard let window = window else { return }

        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(gestureRecognizer:)))
        gestureRecognizer.numberOfTouchesRequired = 2
        gestureRecognizer.direction = .left
        gestureRecognizer.delegate = self

        window.addGestureRecognizer(gestureRecognizer)

        internalView.tapGestureRecognizer.addTarget(self, action: #selector(didTapBackground))
    }

    private func scheduleRemoteNotification(toScreen screen: String) {
        let scheduledDateComponents = Calendar.current.dateComponents([
            .year,
            .month,
            .day,
            .hour,
            .minute,
            .timeZone
        ],
        from: Date())

        var date = DateComponents()
        date.year = scheduledDateComponents.year
        date.month = scheduledDateComponents.month
        date.day = scheduledDateComponents.day
        date.hour = scheduledDateComponents.hour
        date.minute = scheduledDateComponents.minute
        date.timeZone = scheduledDateComponents.timeZone

        if let minute = date.minute { date.minute = minute + 2 }

        let actionTitle = "Scheduling AppConfig Local Notification in: \(date) routing to screen: \(screen)"
        let actionItems = [
            UIAlertAction(title: "Ok",
                          style: .default,
                          handler: { [weak self] _ in

                              guard var appConfiguration = self?.storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.appConfiguration) else {
                                  return
                              }

                              appConfiguration.scheduledNotification = ApplicationConfiguration.ScheduledNotification(scheduledDateTime: "Can be ignored while testing",
                                                                                                                      title: "Scheduled Remote Notification",
                                                                                                                      body: "Routing to \(screen)",
                                                                                                                      targetScreen: screen)

                              self?.storageController.store(object: appConfiguration, identifiedBy: ExposureDataStorageKey.appConfiguration) { _ in }
                              self?.userNotificationController.scheduleRemoteNotification(title: appConfiguration.scheduledNotification?.title ?? "",
                                                                                          body: appConfiguration.scheduledNotification?.body ?? "",
                                                                                          date: date,
                                                                                          targetScreen: appConfiguration.scheduledNotification?.targetScreen ?? "")
                          })
        ]

        present(actionItems: actionItems, title: actionTitle)
    }

    private lazy var internalView: DeveloperMenuView = DeveloperMenuView(theme: self.theme)
    private var isShown: Bool = false
    private weak var listener: DeveloperMenuListener?
    private let mutableExposureStateStream: MutableExposureStateStreaming
    private let mutableNetworkConfigurationStream: MutableNetworkConfigurationStreaming
    private let exposureController: ExposureControlling
    private let storageController: StorageControlling
    private let featureFlagController: FeatureFlagControlling
    private let userNotificationController: UserNotificationControlling
    private var disposeBag = DisposeBag()

    private var isFetchingKeys: Bool {
        return fetchAndProcessDisposable != nil
    }

    private var window: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.filter { $0.isKeyWindow }.first
        } else {
            return UIApplication.shared.keyWindow
        }
    }

    private var rootViewController: UIViewController? {
        return window?.rootViewController
    }
}

private final class DeveloperMenuView: View {
    private let backgroundView = UIView()
    private let contentView = UIView()
    fileprivate let tableView = UITableView()
    fileprivate let tapGestureRecognizer = UITapGestureRecognizer()

    // MARK: - Init

    override init(theme: Theme) {
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        backgroundColor = .clear

        addSubview(backgroundView)
        addSubview(contentView)
        contentView.addSubview(tableView)

        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        contentView.backgroundColor = .orange

        backgroundView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func setupConstraints() {
        super.setupConstraints()

        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),

            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: contentView.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    fileprivate func showBackgroundView() {
        backgroundView.alpha = 0.0

        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: .beginFromCurrentState,
                       animations: { self.backgroundView.alpha = 1.0 },
                       completion: nil)
    }

    fileprivate func showContentView() {
        contentView.transform = CGAffineTransform(translationX: bounds.width * 0.7, y: 0)

        UIView.animate(withDuration: 0.2,
                       delay: 0.0,
                       options: [.beginFromCurrentState, .curveEaseOut],
                       animations: { self.contentView.transform = .identity },
                       completion: nil)
    }

    fileprivate func hideContentView() {
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: .beginFromCurrentState,
                       animations: { self.backgroundView.alpha = 0.0 },
                       completion: nil)
    }

    fileprivate func hideBackgroundView(completion: @escaping (Bool) -> ()) {
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: [.beginFromCurrentState, .curveEaseIn],
                       animations: { self.contentView.transform = CGAffineTransform(translationX: self.bounds.width * 0.7, y: 0) },
                       completion: completion)
    }
}

private extension ExposureActiveState {
    var asString: String {
        switch self {
        case .active:
            return "Active"
        case .authorizationDenied:
            return "Authorisation Denied"
        case .notAuthorized:
            return "Not Authorised"
        case .restricted:
            return "Restricted"
        case let .inactive(inactiveState):
            switch inactiveState {
            case .paused:
                return "Inactive - Paused"
            case .bluetoothOff:
                return "Inactive - Bluetooth off"
            case .disabled:
                return "Inactive - Disabled"
            case .pushNotifications:
                return "Inactive - Push Notifications"
            case .noRecentNotificationUpdates:
                return "Inactive - No Recent Updates"
            case .noRecentNotificationUpdatesInternetOff:
                return "Inactive - No Recent Updates Due To Internet"
            }
        }
    }
}

private extension ExposureNotificationState {
    var asString: String {
        switch self {
        case let .notified(date):
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            return "Yes - On \(dateFormatter.string(for: date) ?? "?")"
        case .notNotified:
            return "No"
        }
    }

    var toggled: ExposureNotificationState {
        switch self {
        case .notified:
            return .notNotified
        case .notNotified:
            return .notified(Date())
        }
    }
}
