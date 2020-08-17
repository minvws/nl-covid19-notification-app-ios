/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import SnapKit
import UIKit

/// @mockable
protocol InfectedRouting: Routing {
    func didUploadCodes(withKey key: ExposureConfirmationKey)
    func infectedWantsDismissal(shouldDismissViewController: Bool)
    func showInactiveCard()
    func removeInactiveCard()

    func showFAQ()
    func hideFAQ(shouldDismissViewController: Bool)
}

final class InfectedViewController: ViewController, InfectedViewControllable, UIAdaptivePresentationControllerDelegate, Logging {

    enum State {
        case loading
        case success(confirmationKey: ExposureConfirmationKey)
        case error
    }

    weak var router: InfectedRouting?

    var state: State = .loading {
        didSet {
            updateState()
        }
    }

    init(theme: Theme,
         exposureController: ExposureControlling,
         exposureStateStream: ExposureStateStreaming) {
        self.exposureController = exposureController
        self.exposureStateStream = exposureStateStream

        super.init(theme: theme)
    }

    deinit {
        disposeBag.forEach { $0.cancel() }
    }

    // MARK: - Overrides

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hasBottomMargin = true
        title = .moreInformationInfectedTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                            target: self,
                                                            action: #selector(didTapCloseButton(sender:)))

        internalView.infoView.actionHandler = { [weak self] in
            self?.uploadCodes()
        }

        internalView.contentView.linkHandler = { [weak self] link in
            guard link == "openFAQ" else { return }

            self?.router?.showFAQ()
        }

        exposureStateStream
            .exposureState
            .sink { state in
                self.update(exposureState: state)
            }
            .store(in: &disposeBag)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        router?.infectedWantsDismissal(shouldDismissViewController: false)
    }

    // MARK: - InfectedViewControllable

    func push(viewController: ViewControllable) {
        navigationController?.pushViewController(viewController.uiviewController, animated: true)
    }

    func present(viewController: ViewControllable) {
        present(viewController.uiviewController, animated: true, completion: nil)
    }

    func dismiss(viewController: ViewControllable) {
        viewController.uiviewController.dismiss(animated: true, completion: nil)
    }

    func thankYouWantsDismissal() {
        router?.infectedWantsDismissal(shouldDismissViewController: false)

        navigationController?.dismiss(animated: true, completion: nil)
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

    // MARK: - AboutListener

    func aboutRequestsDismissal(shouldHideViewController: Bool) {
        router?.hideFAQ(shouldDismissViewController: shouldHideViewController)
    }

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

    private lazy var internalView: InfectedView = InfectedView(theme: self.theme)
    private let exposureController: ExposureControlling
    private let exposureStateStream: ExposureStateStreaming
    private var disposeBag = Set<AnyCancellable>()

    private var cardViewController: ViewControllable?

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        router?.infectedWantsDismissal(shouldDismissViewController: true)
    }

    private func updateState() {
        switch state {
        case .loading:
            internalView.infoView.isActionButtonEnabled = false
            internalView.controlCode.set(state: .loading(.moreInformationInfectedLoading))
        case let .success(key):
            internalView.infoView.isActionButtonEnabled = true
            internalView.controlCode.set(state: .success(key.key))
        case .error:
            internalView.infoView.isActionButtonEnabled = false
            internalView.controlCode.set(state: .error(.moreInformationInfectedError) { [weak self] in
                self?.requestLabConfirmationKey()
            })
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

private final class InfectedView: View {

    fileprivate let infoView: InfoView

    private var content: NSAttributedString {
        let header = NSAttributedString(string: .moreInformationInfectedHeader,
                                        attributes: [
                                            NSAttributedString.Key.foregroundColor: UIColor.black,
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
                            stepImage: .moreInformationStep3)
    }()

    private lazy var cardContentView: View = View(theme: theme)

    // MARK: - Init

    override init(theme: Theme) {
        let config = InfoViewConfig(actionButtonTitle: .moreInformationInfectedUpload,
                                    headerImage: .infectedHeader)
        self.infoView = InfoView(theme: theme, config: config)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        infoView.addSections([
            contentView,
            controlCode,
            waitForTheGGD,
            shareYourCodes,
            cardContentView
        ])

        addSubview(infoView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        infoView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.bottom.leading.trailing.equalToSuperview()
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
