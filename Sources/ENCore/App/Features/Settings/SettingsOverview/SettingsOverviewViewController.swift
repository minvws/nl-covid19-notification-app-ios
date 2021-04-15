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
         pushNotificationStream: PushNotificationStreaming) {
        self.listener = listener
        self.exposureDataController = exposureDataController
        self.pauseController = pauseController
        self.pushNotificationStream = pushNotificationStream

        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = self.navigationController?.navigationItem.rightBarButtonItem

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
    private lazy var internalView: SettingsView = SettingsView(theme: self.theme, pauseController: pauseController)
    private let exposureDataController: ExposureDataControlling
    private let pauseController: PauseControlling
    private let pushNotificationStream: PushNotificationStreaming
    private var disposeBag = DisposeBag()
}

private final class SettingsView: View {

    private lazy var scrollableStackView = ScrollableStackView(theme: theme)
    private let pauseController: PauseControlling

    lazy var separatorView: View = {
        let view = View(theme: theme)
        view.backgroundColor = UIColor(red: 0.933, green: 0.933, blue: 0.933, alpha: 1)
        return view
    }()

    private lazy var pauseAppTitleLabel: Label = {
        let label = Label(frame: .zero)
        label.isUserInteractionEnabled = true
        label.font = theme.fonts.title3
        label.text = .moreInformationSettingsPauseTitle
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var pauseAppDescriptionLabel: Label = {
        let label = Label()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .moreInformationSettingsPauseDescriptionShort
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
        label.numberOfLines = 0
        label.accessibilityTraits = .header
        return label
    }()

    private lazy var mobileDataDescriptionLabel: Label = {
        let label = Label()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .moreInformationSettingsDescription
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

    // MARK: - Init

    init(theme: Theme,
         pauseController: PauseControlling) {
        self.pauseController = pauseController
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        addSubview(scrollableStackView)
        scrollableStackView.spacing = 21
        scrollableStackView.stackViewBottomMargin = 32
        scrollableStackView.addSections([
            pauseAppTitleLabel,
            pauseAppDescriptionLabel,
            pauseAppButton,
            appPausedView,
            separatorView,
            mobileDataTitleLabel,
            mobileDataDescriptionLabel,
            mobileDataButton
        ])
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollableStackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.top.bottom.equalToSuperview()
        }

        pauseAppButton.snp.makeConstraints { maker in
            maker.height.equalTo(48)
        }

        unpauseAppButton.snp.makeConstraints { maker in
            maker.height.equalTo(48)
        }

        separatorView.snp.makeConstraints { maker in
            maker.height.equalTo(1)
        }

        mobileDataButton.snp.makeConstraints { maker in
            maker.height.equalTo(48)
        }
    }
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
