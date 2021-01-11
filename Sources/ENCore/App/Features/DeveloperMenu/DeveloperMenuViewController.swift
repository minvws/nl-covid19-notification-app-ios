/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import Foundation
import MessageUI
import UIKit

/// @mockable
protocol DeveloperMenuViewControllable: ViewControllable {}

private struct DeveloperItem {
    let title: String
    let subtitle: String
    let action: () -> ()
    let enabled: Bool

    init(title: String, subtitle: String, action: @escaping () -> (), enabled: Bool = true) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.enabled = enabled
    }
}

final class DeveloperMenuViewController: ViewController, DeveloperMenuViewControllable, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, Logging {

    init(listener: DeveloperMenuListener,
         theme: Theme,
         mutableExposureStateStream: MutableExposureStateStreaming,
         mutableNetworkConfigurationStream: MutableNetworkConfigurationStreaming,
         exposureController: ExposureControlling,
         storageController: StorageControlling) {
        self.listener = listener
        self.mutableExposureStateStream = mutableExposureStateStream
        self.mutableNetworkConfigurationStream = mutableNetworkConfigurationStream
        self.exposureController = exposureController
        self.storageController = storageController

        super.init(theme: theme)

        attach()
    }

    deinit {
        disposeBag.forEach { $0.cancel() }
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIndex: Int) -> Int {
        let section = sections[sectionIndex]

        return section.items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection sectionIndex: Int) -> String? {
        let section = sections[sectionIndex]

        return section.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        internalView.tableView.reloadData()
    }

    // MARK: - Sections

    private var sections: [(title: String, items: [DeveloperItem])] {
        return [
            ("Onboarding", [
                DeveloperItem(title: "Show Onboarding",
                              subtitle: "Launches Onboarding",
                              action: { [weak self] in self?.launchOnboarding() })
            ]),
            ("Exposure", [
                DeveloperItem(title: "Change Exposure State",
                              subtitle: "Current: \(self.mutableExposureStateStream.currentExposureState?.activeState.asString ?? "None")",
                              action: { [weak self] in self?.changeExposureState() }),
                DeveloperItem(title: "Change Notified",
                              subtitle: "Current: \(self.mutableExposureStateStream.currentExposureState?.notifiedState.asString ?? "No")",
                              action: { [weak self] in self?.changeNotified() }),
                DeveloperItem(title: "Upload Exposure Keys",
                              subtitle: "Upload keys after giving permission",
                              action: { [weak self] in self?.uploadKeys() }),
                DeveloperItem(title: "Remove Stored LabConfirmationKey",
                              subtitle: "Last: \(getLastStoredConfirmationKey())",
                              action: { [weak self] in self?.removeStoredConfirmationKey() }),
                DeveloperItem(title: "Remove Last Exposure",
                              subtitle: "Last: \(getLastExposureString())",
                              action: { [weak self] in self?.removeLastExposure() }),
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
                              action: { [weak self] in self?.toggleGetTestDiagnosisKeys() })
            ]),
            ("Storage", [
                DeveloperItem(title: "Erase Local Storage",
                              subtitle: "Deletes all stored local data (excludes data generated by EN framework)",
                              action: { [weak self] in self?.eraseCompleteStorage() })
            ]),
            ("Networking", [
                DeveloperItem(title: "Network Configuration",
                              subtitle: "Current: \(self.mutableNetworkConfigurationStream.configuration.name)",
                              action: { [weak self] in self?.changeNetworkConfiguration() })
            ]),
            ("Push Notifications", [
                DeveloperItem(title: "Launch Message Flow",
                              subtitle: "Launches the message flow as would be done from a exposure push notification with today's date",
                              action: { [weak self] in self?.listener?.developerMenuRequestMessage(exposureDate: Date()); self?.hide() }),
                DeveloperItem(title: "Schedule Message Flow",
                              subtitle: "Schedules a push notification to be sent in 5 seconds",
                              action: { [weak self] in self?.wantsScheduleNotification(identifier: "com.apple.en.mock") }),
                DeveloperItem(title: "Schedule Upload Failed Flow",
                              subtitle: "Schedules a push notifiction to be sent in 5 seconds",
                              action: { [weak self] in self?.wantsScheduleNotification(identifier: PushNotificationIdentifier.uploadFailed.rawValue) })
            ]),
            ("Logging", [
                DeveloperItem(title: "Log Files",
                              subtitle: "Share the log files",
                              action: { [weak self] in self?.emailLogFiles() })
            ])
        ]
    }

    // MARK: - Actions

    private func launchOnboarding() {
        hide()

        listener?.developerMenuRequestsOnboardingFlow()
    }

    private func changeExposureState() {
        let options: [ExposureActiveState] = [
            .active,
            .authorizationDenied,
            .inactive(.bluetoothOff),
            .inactive(.disabled),
            .inactive(.noRecentNotificationUpdates)
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

        if let current = mutableExposureStateStream.currentExposureState {
            exposureState = .init(notifiedState: current.notifiedState, activeState: to)
        } else {
            exposureState = .init(notifiedState: .notNotified, activeState: to)
        }

        mutableExposureStateStream.update(state: exposureState)
        internalView.tableView.reloadData()
    }

    private func changeNotified() {
        let exposureState: ExposureState

        if let current = mutableExposureStateStream.currentExposureState {
            exposureState = .init(notifiedState: current.notifiedState.toggled, activeState: current.activeState)
        } else {
            exposureState = .init(notifiedState: .notified(Date()), activeState: .active)
        }

        mutableExposureStateStream.update(state: exposureState)
    }

    private func changeNetworkConfiguration() {
        let configurations: [NetworkConfiguration] = [.development, .test, .acceptance, .production]

        let actionItems = configurations.map { (configuration) -> UIAlertAction in
            let actionHandler: (UIAlertAction) -> () = { [weak self] _ in
                self?.mutableNetworkConfigurationStream.update(configuration: configuration)
                self?.eraseCompleteStorage()

                self?.exposureController.refreshStatus()
                self?.internalView.tableView.reloadData()
            }

            return UIAlertAction(title: configuration.name,
                                 style: .default,
                                 handler: actionHandler)
        }

        present(actionItems: actionItems, title: "Update Network Configuration")
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
        storageController.removeData(for: ExposureDataStorageKey.pendingLabUploadRequests, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.seenAnnouncements, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.treatmentPerspective, completion: { _ in })
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
        self.exposureController.requestUploadKeys(forLabConfirmationKey: key) { result in
            let title = "Result: \(result)"

            self.present(actionItems: [], title: title)
        }
    }

    private func removeStoredConfirmationKey() {
        storageController.removeData(for: ExposureDataStorageKey.labConfirmationKey, completion: { _ in })

        exposureController.refreshStatus()
        internalView.tableView.reloadData()
    }

    private func removeLastExposure() {
        storageController.removeData(for: ExposureDataStorageKey.lastExposureReport, completion: { _ in })

        exposureController.refreshStatus()
        internalView.tableView.reloadData()
    }

    private func removeAllExposureKeySets() {
        storageController.removeData(for: ExposureDataStorageKey.exposureKeySetsHolders, completion: { _ in })
        storageController.removeData(for: ExposureDataStorageKey.lastExposureProcessingDate, completion: { _ in })

        if let folder = LocalPathProvider().path(for: .exposureKeySets) {
            try? FileManager.default.removeItem(at: folder)
        }

        exposureController.refreshStatus()
        internalView.tableView.reloadData()
    }

    private func emailLogFiles() {
        let activityViewController = UIActivityViewController(activityItems: LogHandler.logFiles(),
                                                              applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }

    private var fetchAndProcessCancellable: AnyCancellable?

    private func fetchAndProcessKeySets() {
        guard fetchAndProcessCancellable == nil else {
            fetchAndProcessCancellable?.cancel()
            fetchAndProcessCancellable = nil

            return
        }

        internalView.tableView.reloadData()

        fetchAndProcessCancellable = exposureController
            .fetchAndProcessExposureKeySets()
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.fetchAndProcessCancellable = nil

                    assert(Thread.isMainThread)
                    self?.internalView.tableView.reloadData()
                },
                receiveValue: { _ in })
    }

    private func processPendingUploadRequests() {
        exposureController
            .processPendingUploadRequests()
            .sink(receiveCompletion: { [weak self] _ in self?.internalView.tableView.reloadData() },
                  receiveValue: { _ in })
            .store(in: &disposeBag)
    }

    private func processExpiredUploadRequests() {
        exposureController
            .processExpiredUploadRequests()
            .sink(receiveCompletion: { [weak self] _ in self?.internalView.tableView.reloadData() },
                  receiveValue: { _ in })
            .store(in: &disposeBag)
    }

    private func expirePendingUploadRequests() {
        guard var pendingRequests = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.pendingLabUploadRequests) else {
            return
        }

        for (index, _) in pendingRequests.enumerated() { pendingRequests[index].expiryDate = Date() }

        self.storageController.requestExclusiveAccess { storageController in
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

    private func getNumberOfAPICallsInLast24Hours() -> Int {
        let apiCalls = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.exposureApiCallDates) ?? []

        guard let cutOffDate = Calendar.current.date(byAdding: .hour, value: -24, to: Date()) else {
            return 0
        }

        let wasProcessedInLast24h: (Date) -> Bool = { date in
            return date > cutOffDate
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
        return "\(dateFormatter.string(from: last.date))) seconds"
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

        internalView.tableView.reloadData()

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

    private lazy var internalView: DeveloperMenuView = DeveloperMenuView(theme: self.theme)
    private var isShown: Bool = false
    private weak var listener: DeveloperMenuListener?
    private let mutableExposureStateStream: MutableExposureStateStreaming
    private let mutableNetworkConfigurationStream: MutableNetworkConfigurationStreaming
    private let exposureController: ExposureControlling
    private let storageController: StorageControlling
    private var disposeBag = Set<AnyCancellable>()

    private var isFetchingKeys: Bool {
        return fetchAndProcessCancellable != nil
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
        case let .inactive(inactiveState):
            switch inactiveState {
            case .bluetoothOff:
                return "Inactive - Bluetooth off"
            case .disabled:
                return "Inactive - Disabled"
            case .pushNotifications:
                return "Inactive - Push Notifications"
            case .noRecentNotificationUpdates:
                return "Inactive - No Recent Updates"
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
