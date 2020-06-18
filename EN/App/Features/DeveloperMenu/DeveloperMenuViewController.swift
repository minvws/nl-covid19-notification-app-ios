/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

/// @mockable
protocol DeveloperMenuViewControllable: ViewControllable {}

private struct DeveloperItem {
    let title: String
    let subtitle: String
    let action: () -> ()
}

final class DeveloperMenuViewController: ViewController, DeveloperMenuViewControllable, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource {

    init(listener: DeveloperMenuListener,
         theme: Theme,
         mutableExposureStateStream: MutableExposureStateStreaming) {
        self.listener = listener
        self.mutableExposureStateStream = mutableExposureStateStream

        super.init(theme: theme)

        attach()
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        internalView.tableView.delegate = self
        internalView.tableView.dataSource = self

        view.backgroundColor = .clear
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
        cell.detailTextLabel?.text = item.subtitle

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
            ("Exposure State", [
                DeveloperItem(title: "Change Exposure State",
                              subtitle: "Current: \(self.mutableExposureStateStream.currentExposureState?.activeState.asString ?? "None")",
                              action: { [weak self] in self?.changeExposureState() }),
                DeveloperItem(title: "Change Notified",
                              subtitle: "Current: \(self.mutableExposureStateStream.currentExposureState?.notifiedState.asString ?? "No")",
                              action: { [weak self] in self?.changeNotified() })
            ])
        ]
    }

    // MARK: - Actions

    private func launchOnboarding() {
        listener?.developerMenuRequestsOnboardingFlow()

        hide()
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

        let actionViewController = UIAlertController(title: "Update Exposure State",
                                                     message: nil,
                                                     preferredStyle: .actionSheet)
        actionItems.forEach { actionItem in actionViewController.addAction(actionItem) }

        let cancelItem = UIAlertAction(title: "Cancel",
                                       style: .destructive,
                                       handler: { [weak actionViewController] _ in
                                           actionViewController?.dismiss(animated: true, completion: nil)
        })
        actionViewController.addAction(cancelItem)

        present(actionViewController, animated: true, completion: nil)
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

    // MARK: - Private

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

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !isShown
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

    private var window: UIWindow? {
        UIApplication.shared.keyWindow
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

        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: [.beginFromCurrentState, .curveEaseIn],
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
            case .noRecentNotificationUpdates:
                return "Inactive - No Recent Updates"
            case .paused:
                return "Inactive - Paused"
            case .requiresOSUpdate:
                return "Inactive - Requires OS Update"
            case .airplaneMode:
                return "Inactive - Airplane Mode"
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
