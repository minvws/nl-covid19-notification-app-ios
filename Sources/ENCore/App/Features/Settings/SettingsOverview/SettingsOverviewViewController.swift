/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import RxSwift
import UIKit

/// @mockable
protocol SettingsOverviewRouting: Routing {
    func routeToPauseConfirmation()
    func pauseConfirmationWantsDismissal(completion: (() -> ())?)
}

final class SettingsOverviewViewController: ViewController, SettingsOverviewViewControllable, Logging, PauseConfirmationListener {
    weak var router: SettingsOverviewRouting?

    // MARK: - Init

    init(listener: SettingsOverviewListener,
         theme: Theme,
         exposureDataController: ExposureDataControlling,
         pauseController: PauseControlling,
         pushNotificationStream: PushNotificationStreaming,
         storageController: StorageControlling) {
        self.listener = listener
        self.exposureDataController = exposureDataController
        self.pauseController = pauseController
        self.pushNotificationStream = pushNotificationStream
        self.storageController = storageController

        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        view = internalView
        view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = navigationController?.navigationItem.rightBarButtonItem

        internalView.mobileDataButton.action = { [weak self] in
            self?.listener?.settingsOverviewRequestsRoutingToMobileData()
        }

        internalView.pauseAppButton.action = { [weak self] in
            guard let strongSelf = self else { return }

            if strongSelf.exposureDataController.hidePauseInformation {
                let alertController = strongSelf.pauseController.getPauseTimeOptionsController()
                strongSelf.uiviewController.present(alertController, animated: true, completion: nil)

            } else {
                strongSelf.router?.routeToPauseConfirmation()
            }
        }

        internalView.unpauseAppButton.action = { [weak self] in
            self?.pauseController.unpauseApp()
        }

        exposureDataController.pauseEndDateObservable.subscribe(onNext: { [weak self] _ in
            self?.updatePausedState()
        })
            .disposed(by: disposeBag)

        pushNotificationStream.foregroundNotificationStream.subscribe(onNext: { [weak self] notification in
            guard let strongSelf = self else { return }
            if notification.requestIdentifier == PushNotificationIdentifier.pauseEnded.rawValue {
                self?.logDebug("Refreshing settings pause state due to pauseEnded notification")
                strongSelf.updatePausedState()
            }
        })
            .disposed(by: disposeBag)

        updatePausedState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = .moreInformationSettingsTitle

        updatePausedState()
    }

    private func updatePausedState() {
        let pauseEndDate = exposureDataController.pauseEndDate
        let isPaused = pauseEndDate != nil
        internalView.pauseCountdownView.countdownToDate = pauseEndDate
        internalView.pauseAppButton.isHidden = isPaused
        internalView.appPausedView.isHidden = !isPaused
    }

    func present(viewController: ViewControllable, animated: Bool, completion: (() -> ())?) {
        present(viewController.uiviewController,
                animated: animated,
                completion: completion)
    }

    func presentInNavigationController(viewController: ViewControllable) {
        let navigationController = NavigationController(rootViewController: viewController.uiviewController, theme: theme)

        if let presentationDelegate = viewController.uiviewController as? UIAdaptivePresentationControllerDelegate {
            navigationController.presentationController?.delegate = presentationDelegate
        }

        present(navigationController, animated: true, completion: nil)
    }

    func dismiss(viewController: ViewControllable, completion: (() -> ())?) {
        viewController.uiviewController.dismiss(animated: true, completion: completion)
    }

    func pauseConfirmationWantsDismissal(shouldDismissViewController: Bool) {
        router?.pauseConfirmationWantsDismissal(completion: nil)
    }

    func pauseConfirmationWantsPauseOptions() {
        router?.pauseConfirmationWantsDismissal(completion: { [weak self] in
            guard let strongSelf = self else { return }

            let alertController = strongSelf.pauseController.getPauseTimeOptionsController()
            strongSelf.uiviewController.present(alertController, animated: true, completion: nil)
        })
    }

    // MARK: - Private

    private weak var listener: SettingsOverviewListener?
    private lazy var internalView: SettingsView = SettingsView(theme: self.theme, pauseController: pauseController, storageController: storageController)
    private let exposureDataController: ExposureDataControlling
    private let pauseController: PauseControlling
    private let pushNotificationStream: PushNotificationStreaming
    private let storageController: StorageControlling
    private var disposeBag = DisposeBag()
}

private final class SettingsView: View {
    private lazy var scrollableStackView = ScrollableStackView(theme: theme)
    private let pauseController: PauseControlling
    private let storageController: StorageControlling

    lazy var firstSeparatorView: View = {
        let view = View(theme: theme)
        view.backgroundColor = theme.colors.divider
        return view
    }()

    lazy var secondSeparatorView: View = {
        let view = View(theme: theme)
        view.backgroundColor = theme.colors.divider
        return view
    }()

    private lazy var pauseAppTitleLabel: Label = {
        let label = Label(frame: .zero)
        label.isUserInteractionEnabled = true
        label.font = theme.fonts.title3
        label.text = .moreInformationSettingsPauseTitle
        label.textColor = theme.colors.textPrimary
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var pauseAppDescriptionLabel: Label = {
        let label = Label()
        label.font = theme.fonts.body
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .moreInformationSettingsPauseDescriptionShort
        label.textColor = theme.colors.textSecondary
        return label
    }()

    lazy var pauseAppButton: Button = {
        let button = Button(theme: self.theme)
        button.titleEdgeInsets = UIEdgeInsets(top: 40, left: 41, bottom: 40, right: 41)
        button.layer.cornerRadius = 8
        button.setTitle(.moreInformationSettingsPauseButtonTitle, for: .normal)
        button.style = .secondary
        button.isHidden = true
        return button
    }()

    lazy var unpauseAppButton: Button = {
        let button = Button(theme: self.theme)
        button.titleEdgeInsets = UIEdgeInsets(top: 40, left: 41, bottom: 40, right: 41)
        button.layer.cornerRadius = 8
        button.setTitle(.moreInformationSettingsUnpauseTitle, for: .normal)
        button.style = .primary
        return button
    }()

    lazy var appPausedView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.addArrangedSubview(pauseCountdownView)
        stackView.addArrangedSubview(unpauseAppButton)
        stackView.isHidden = true
        return stackView
    }()

    private lazy var mobileDataTitleLabel: Label = {
        let label = Label(frame: .zero)
        label.isUserInteractionEnabled = true
        label.font = theme.fonts.title3
        label.text = .moreInformationSettingsMobileDataParagraphTitle
        label.textColor = theme.colors.textPrimary
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var mobileDataDescriptionLabel: Label = {
        let label = Label()
        label.font = theme.fonts.body
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .moreInformationSettingsDescription
        label.textColor = theme.colors.textSecondary
        return label
    }()

    lazy var mobileDataButton: Button = {
        let button = Button(theme: self.theme)
        button.titleEdgeInsets = UIEdgeInsets(top: 40, left: 41, bottom: 40, right: 41)
        button.layer.cornerRadius = 8
        button.setTitle(.moreInformationSettingsMobileDataButton, for: .normal)
        button.style = .secondary
        return button
    }()

    lazy var pauseCountdownView: PauseCountdownView = {
        let countdownView = PauseCountdownView(theme: theme, pauseController: pauseController)
        countdownView.layer.cornerRadius = 8
        countdownView.backgroundColor = theme.colors.tertiary
        return countdownView
    }()

    private lazy var showCoronaDashboardSwitchView: ShowCoronaDashboardSwitchView = {
        ShowCoronaDashboardSwitchView(theme: theme, storageController: storageController)
    }()

    private lazy var showCoronaDashboarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = .settingsCoronaDashboard
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var showCoronaDashboardDescriptionLabel: Label = {
        let label = Label()
        label.font = theme.fonts.body
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .moreInformationSettingsCoronadashboardContent
        label.textColor = theme.colors.textSecondary
        return label
    }()

    // MARK: - Init

    init(theme: Theme,
         pauseController: PauseControlling,
         storageController: StorageControlling) {
        self.pauseController = pauseController
        self.storageController = storageController
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        backgroundColor = theme.colors.viewControllerBackground

        addSubview(scrollableStackView)
        scrollableStackView.spacing = 21
        scrollableStackView.stackViewBottomMargin = 32
        scrollableStackView.addSections([
            pauseAppTitleLabel,
            pauseAppDescriptionLabel,
            pauseAppButton,
            appPausedView,
            firstSeparatorView,
            mobileDataTitleLabel,
            mobileDataDescriptionLabel,
            mobileDataButton,
            secondSeparatorView,
            showCoronaDashboardSwitchView,
            showCoronaDashboarImageView,
            showCoronaDashboardDescriptionLabel
        ])
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollableStackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.top.bottom.equalToSuperview()
        }

        pauseAppButton.snp.makeConstraints { maker in
            maker.height.greaterThanOrEqualTo(48)
        }

        unpauseAppButton.snp.makeConstraints { maker in
            maker.height.greaterThanOrEqualTo(48)
        }

        firstSeparatorView.snp.makeConstraints { maker in
            maker.height.equalTo(1)
        }

        secondSeparatorView.snp.makeConstraints { maker in
            maker.height.equalTo(1)
        }

        mobileDataButton.snp.makeConstraints { maker in
            maker.height.greaterThanOrEqualTo(48)
        }
    }
}

private final class ShowCoronaDashboardSwitchView: View, Logging {
    private lazy var showCoronaDashboardTitleLabel: Label = {
        let label = Label(frame: .zero)
        label.isUserInteractionEnabled = true
        label.font = theme.fonts.title3
        label.text = .moreInformationSettingsCoronadashboardTitle
        label.textColor = theme.colors.textPrimary
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var showCoronaDashboardSwitch: UISwitch = {
        let uiSwitch = UISwitch()
        uiSwitch.translatesAutoresizingMaskIntoConstraints = false
        uiSwitch.isOn = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.showCoronaDashboard) ?? true
        uiSwitch.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        return uiSwitch
    }()

    init(theme: Theme, storageController: StorageControlling) {
        self.storageController = storageController
        super.init(theme: theme)
    }

    override func build() {
        super.build()

        addSubview(showCoronaDashboardTitleLabel)
        addSubview(showCoronaDashboardSwitch)
    }

    override func setupConstraints() {
        super.setupConstraints()

        showCoronaDashboardTitleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.left.equalToSuperview().offset(10)
            maker.right.equalTo(showCoronaDashboardSwitch.snp.left).offset(-10)
            maker.bottom.equalTo(-10)
        }

        showCoronaDashboardSwitch.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.right.equalToSuperview().offset(-20)
        }
    }

    @objc private func valueChanged() {
        storageController.store(object: showCoronaDashboardSwitch.isOn, identifiedBy: ExposureDataStorageKey.showCoronaDashboard, completion: { error in
            guard let error = error else { return }
            self.logWarning("SettingsOverviewViewController - Couldn't store new `showCoronaDashboard` value \(self.showCoronaDashboardSwitch.isOn) - Error: \(error.localizedDescription)")
        })
    }

    private let storageController: StorageControlling
}

private final class PauseCountdownView: View {
    private var timer: Timer?
    private let pauseController: PauseControlling

    var countdownToDate: Date? {
        didSet {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: .minutes(1), repeats: true) { [weak self] _ in
                self?.updateTimerText()
            }

            updateTimerText()
        }
    }

    private func updateTimerText() {
        label.attributedText = pauseController.getPauseCountdownString(theme: theme, emphasizeTime: true)
    }

    lazy var label: Label = {
        let label = Label(frame: .zero)
        label.font = theme.fonts.body
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()

    lazy var icon: UIImageView = {
        let image = UIImageView(image: .about)
        return image
    }()

    // MARK: - Init

    init(theme: Theme,
         pauseController: PauseControlling) {
        self.pauseController = pauseController
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        addSubview(icon)
        addSubview(label)
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    override func setupConstraints() {
        super.setupConstraints()

        icon.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(20)
            maker.size.equalTo(20)
            maker.centerY.equalToSuperview()
        }

        label.snp.makeConstraints { maker in
            maker.leading.equalTo(icon.snp.trailing).offset(10)
            maker.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.top.bottom.equalToSuperview().inset(16)
        }
    }
}
