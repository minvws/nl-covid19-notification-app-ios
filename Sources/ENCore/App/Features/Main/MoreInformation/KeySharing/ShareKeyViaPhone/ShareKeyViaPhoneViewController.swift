/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import RxSwift
import SnapKit
import UIKit

/// @mockable
protocol ShareKeyViaPhoneRouting: Routing {
    func didUploadCodes(withKey key: ExposureConfirmationKey)
    func shareKeyViaPhoneWantsDismissal(shouldDismissViewController: Bool)
    func showInactiveCard()
    func removeInactiveCard()

    func showFAQ()
    func hideFAQ(shouldDismissViewController: Bool)
}

final class ShareKeyViaPhoneViewController: ViewController, ShareKeyViaPhoneViewControllable, UIAdaptivePresentationControllerDelegate, Logging {

    enum State {
        case loading
        case success(confirmationKey: ExposureConfirmationKey)
        case error
    }

    weak var router: ShareKeyViaPhoneRouting?

    var state: State = .loading {
        didSet {
            updateState()
        }
    }

    init(theme: Theme,
         exposureController: ExposureControlling,
         exposureStateStream: ExposureStateStreaming,
         interfaceOrientationStream: InterfaceOrientationStreaming,
         withBackButton: Bool) {
        self.exposureController = exposureController
        self.exposureStateStream = exposureStateStream
        self.interfaceOrientationStream = interfaceOrientationStream
        self.withBackButton = withBackButton
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hasBottomMargin = true

        setThemeNavigationBar(withTitle: .moreInformationInfectedTitle)

        navigationItem.hidesBackButton = !withBackButton
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(target: self, action: #selector(didTapCloseButton(sender:)))

        internalView.infoView.showHeader = !(interfaceOrientationStream.currentOrientationIsLandscape ?? false)

        internalView.infoView.actionHandler = { [weak self] in
            self?.uploadCodes()
        }

        internalView.contentView.linkHandler = { [weak self] link in
            guard link == "openFAQ" else { return }

            self?.router?.showFAQ()
        }

        exposureStateStream
            .exposureState
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.update(exposureState: state)
            })
            .disposed(by: disposeBag)

        interfaceOrientationStream
            .isLandscape
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] isLandscape in
                self?.internalView.infoView.showHeader = !isLandscape
            }.disposed(by: disposeBag)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        router?.shareKeyViaPhoneWantsDismissal(shouldDismissViewController: false)
    }

    // MARK: - ShareKeyViaPhoneViewControllable

    func push(viewController: ViewControllable) {
        navigationController?.pushViewController(viewController.uiviewController, animated: true)
    }

    func presentInNavigationController(viewController: ViewControllable) {
        let navigationController = NavigationController(rootViewController: viewController.uiviewController, theme: theme)

        if let presentationDelegate = viewController.uiviewController as? UIAdaptivePresentationControllerDelegate {
            navigationController.presentationController?.delegate = presentationDelegate
        }

        present(navigationController, animated: true, completion: nil)
    }

    func dismiss(viewController: ViewControllable) {
        if let navigationController = viewController.uiviewController.navigationController {
            navigationController.dismiss(animated: true, completion: nil)
        } else {
            viewController.uiviewController.dismiss(animated: true, completion: nil)
        }
    }

    func thankYouWantsDismissal() {
        router?.shareKeyViaPhoneWantsDismissal(shouldDismissViewController: true)
    }

    func set(cardViewController: ViewControllable?) {
        internalView.infoView.isActionButtonEnabled = cardViewController == nil

        if let current = self.cardViewController {
            current.uiviewController.willMove(toParent: nil)
            internalView.set(cardView: nil)
            current.uiviewController.removeFromParent()
        }

        if let cardViewController = cardViewController {
            addChild(cardViewController.uiviewController)
            internalView.set(cardView: cardViewController.uiviewController.view)
            cardViewController.uiviewController.didMove(toParent: self)

            self.cardViewController = cardViewController
        }
    }

    // MARK: - HelpDetailListener

    func helpDetailRequestsDismissal(shouldDismissViewController: Bool) {
        router?.hideFAQ(shouldDismissViewController: shouldDismissViewController)
    }

    func helpDetailDidTapEnableAppButton() {}

    func helpDetailRequestRedirect(to content: LinkedContent) {}

    // MARK: - Private

    private func update(exposureState: ExposureState) {
        switch exposureState.activeState {
        case .authorizationDenied, .notAuthorized, .inactive(.disabled):
            router?.showInactiveCard()
        default:
            requestLabConfirmationKey()
            router?.removeInactiveCard()
        }
    }

    private func uploadCodes() {
        guard case let .success(key) = state else {
            return logError("Error uploading keys: \(state)")
        }

        exposureController.requestUploadKeys(forLabConfirmationKey: key) { [weak self] result in
            self?.logDebug("`requestUploadKeys` \(result)")
            switch result {
            case .notAuthorized:
                () // The user did not allow uploading the keys so we do nothing.
            default:
                self?.router?.didUploadCodes(withKey: key)
            }
        }
    }

    private lazy var internalView: ShareKeyViaPhoneView = ShareKeyViaPhoneView(theme: self.theme)
    private let exposureController: ExposureControlling
    private let exposureStateStream: ExposureStateStreaming
    private let withBackButton: Bool
    private var disposeBag = DisposeBag()
    private let interfaceOrientationStream: InterfaceOrientationStreaming

    private var cardViewController: ViewControllable?

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        router?.shareKeyViaPhoneWantsDismissal(shouldDismissViewController: true)        
    }

    private func updateState() {
        DispatchQueue.main.async {
            switch self.state {
            case .loading:
                self.internalView.infoView.isActionButtonEnabled = false
                self.internalView.controlCode.set(state: .loading(.moreInformationInfectedLoading))
            case let .success(key):
                self.internalView.infoView.isActionButtonEnabled = true
                self.internalView.controlCode.set(state: .success(key.key))
            case .error:
                self.internalView.infoView.isActionButtonEnabled = false
                self.internalView.controlCode.set(state: .error(.moreInformationInfectedError) { [weak self] in
                    self?.requestLabConfirmationKey()
                })
            }
        }
    }

    private func requestLabConfirmationKey() {
        state = .loading
        exposureController.requestLabConfirmationKey { [weak self] result in
            switch result {
            case let .success(key):
                self?.state = .success(confirmationKey: key)
            case .failure:
                self?.state = .error
            }
        }
    }
}

private final class ShareKeyViaPhoneView: View {

    fileprivate let infoView: InfoView

    private var content: NSAttributedString {
        let header = NSAttributedString(string: .moreInformationInfectedHeader,
                                        attributes: [
                                            NSAttributedString.Key.foregroundColor: theme.colors.gray,
                                            NSAttributedString.Key.font: theme.fonts.body
                                        ])
        let howDoesItWork = NSAttributedString(string: .moreInformationInfectedHowDoesItWork,
                                               attributes: [
                                                   NSAttributedString.Key.foregroundColor: theme.colors.primary,
                                                   NSAttributedString.Key.font: theme.fonts.bodyBold,
                                                   NSAttributedString.Key.link: "openFAQ",
                                                   NSAttributedString.Key.underlineColor: UIColor.clear
                                               ])

        let content = NSMutableAttributedString()
        content.append(header)
        content.append(NSAttributedString(string: " "))
        content.append(howDoesItWork)
        return content
    }

    fileprivate lazy var contentView: InfoSectionContentView = {
        return InfoSectionContentView(theme: theme, content: content)
    }()

    private lazy var stepStackView: UIView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2

        stackView.addArrangedSubview(controlCode)
        stackView.addArrangedSubview(waitForTheGGD)
        stackView.addArrangedSubview(shareYourCodes)
        return stackView
    }()

    fileprivate lazy var controlCode: InfoSectionDynamicCalloutView = {
        InfoSectionDynamicCalloutView(theme: theme,
                                      title: .moreInformationInfectedStep1,
                                      stepImage: .moreInformationStep1)
    }()

    private lazy var waitForTheGGD: View = {
        InfoSectionStepView(theme: theme,
                            title: .moreInformationInfectedStep2,
                            stepImage: .moreInformationStep2)
    }()

    private lazy var shareYourCodes: View = {
        InfoSectionStepView(theme: theme,
                            title: .moreInformationInfectedStep3,
                            stepImage: .moreInformationStep3,
                            isLastStep: true)
    }()

    private lazy var cardContentView: View = View(theme: theme)

    // MARK: - Init

    override init(theme: Theme) {
        let config = InfoViewConfig(actionButtonTitle: .moreInformationInfectedUpload,
                                    headerImage: .infectedHeader,
                                    stickyButtons: true)
        self.infoView = InfoView(theme: theme, config: config)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        infoView.addSections([
            contentView,
            stepStackView,
            cardContentView
        ])

        addSubview(infoView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        infoView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.top.bottom.equalToSuperview()
        }
    }

    // MARK: - Private

    fileprivate func set(cardView: UIView?) {
        cardContentView.subviews.forEach { $0.removeFromSuperview() }

        if let cardView = cardView {
            cardContentView.addSubview(cardView)

            cardView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.trailing.leading.equalToSuperview().inset(16)
            }
        }
    }
}
