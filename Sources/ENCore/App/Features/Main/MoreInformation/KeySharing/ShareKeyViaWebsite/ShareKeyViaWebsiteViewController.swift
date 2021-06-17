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
protocol ShareKeyViaWebsiteRouting: Routing {
    func didCompleteScreen(withKey key: ExposureConfirmationKey)
    func shareKeyViaWebsiteWantsDismissal(shouldDismissViewController: Bool)
    func showInactiveCard()
    func removeInactiveCard()
    
    func showFAQ()
    func hideFAQ(shouldDismissViewController: Bool)
}

enum ShareKeyViaWebsiteState {
    /// Busy loading the labconfirmation key
    case loading
    
    /// User is given the option to share the keys
    case uploadKeys(confirmationKey: ExposureConfirmationKey)
    
    /// Requesting the labconfirmation key  failed
    case loadingError
    
    /// The keys were shared, user is given the option to copy the lab confirmation key so he can enter it on the website
    case keysUploaded(confirmationKey: ExposureConfirmationKey)
}

final class ShareKeyViaWebsiteViewController: ViewController, ShareKeyViaWebsiteViewControllable, UIAdaptivePresentationControllerDelegate, Logging, ShareKeyViaWebsiteViewListener {
    
    weak var router: ShareKeyViaWebsiteRouting?
    
    private var disposeBag = DisposeBag()
    private let exposureController: ExposureControlling
    private let exposureStateStream: ExposureStateStreaming
    private let applicationController: ApplicationControlling
    private let interfaceOrientationStream: InterfaceOrientationStreaming
    private var cardViewController: ViewControllable?
    private let applicationLifecycleStream: ApplicationLifecycleStreaming
    
    private var exposureConfirmationKey: ExposureConfirmationKey?
    private var didSubscribeToStreams = false
    
    private lazy var internalView: ShareKeyViaWebsiteView = {
        let view = ShareKeyViaWebsiteView(theme: self.theme, showWebsiteLink: exposureController.getStoredShareKeyURL() != nil)
        return view
    }()
    
    var state: ShareKeyViaWebsiteState = .loading {
        didSet {
            internalView.update(state: state)
        }
    }
    
    init(theme: Theme,
         exposureController: ExposureControlling,
         exposureStateStream: ExposureStateStreaming,
         interfaceOrientationStream: InterfaceOrientationStreaming,
         applicationController: ApplicationControlling,
         applicationLifecycleStream: ApplicationLifecycleStreaming) {
        self.exposureController = exposureController
        self.exposureStateStream = exposureStateStream
        self.interfaceOrientationStream = interfaceOrientationStream
        self.applicationController = applicationController
        self.applicationLifecycleStream = applicationLifecycleStream
        
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
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(target: self, action: #selector(didTapCloseButton(sender:)))
        
        internalView.infoView.showHeader = !(interfaceOrientationStream.currentOrientationIsLandscape ?? false)
        
        internalView.listener = self
        
        internalView.infoView.actionHandler = { [weak self] in
            guard let state = self?.state, case let .keysUploaded(key) = state else {
                return
            }
            
            self?.router?.didCompleteScreen(withKey: key)
        }
        
        internalView.contentView.linkHandler = { [weak self] link in
            guard link == "openFAQ" else { return }
            
            self?.router?.showFAQ()
        }
        
        subscribeToStreams()
        
        internalView.update(state: state)
    }
    
    private func subscribeToStreams() {
        
        guard !didSubscribeToStreams else { return }
        
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
        
        applicationLifecycleStream
            .didBecomeActive
            .subscribe(onNext: { [weak self] _ in
                self?.checkKeyExpiration()
            })
            .disposed(by: disposeBag)
        
        didSubscribeToStreams = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setThemeNavigationBar(withTitle: .moreInformationInfectedTitle, topItem: navigationItem)
    }
    
    private func checkKeyExpiration() {
        guard let exposureConfirmationKey = exposureConfirmationKey else {
            return
        }
        
        if !exposureConfirmationKey.isValid {
            router?.shareKeyViaWebsiteWantsDismissal(shouldDismissViewController: true)
        }
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        router?.shareKeyViaWebsiteWantsDismissal(shouldDismissViewController: false)
    }
    
    // MARK: - ShareKeyViaWebsiteViewControllable
    
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
        router?.shareKeyViaWebsiteWantsDismissal(shouldDismissViewController: true)
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
    
    // MARK: - ShareKeyViaWebsiteViewListener
    
    func didRequestShareCodes() {
        uploadCodes()
    }
    
    func didRequestWebsiteOpen() {
        guard let urlString = exposureController.getStoredShareKeyURL(),
              let url = URL(string: urlString),
              applicationController.canOpenURL(url) else {
            return
        }
        applicationController.open(url)
    }
    
    func didRequestRequestConfirmationKey() {
        requestLabConfirmationKey()
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
        guard case let .uploadKeys(key) = state else {
            return logError("Error uploading keys: \(state)")
        }
        
        exposureController.requestUploadKeys(forLabConfirmationKey: key) { [weak self] result in
            self?.logDebug("`requestUploadKeys` \(result)")
            switch result {
            case .notAuthorized:
                () // The user did not allow uploading the keys so we do nothing.
            default:
                self?.state = .keysUploaded(confirmationKey: key)
            }
        }
    }
    
    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        router?.shareKeyViaWebsiteWantsDismissal(shouldDismissViewController: true)
    }
        
    private func requestLabConfirmationKey() {
        state = .loading
        exposureController.requestLabConfirmationKey { [weak self] result in
            switch result {
            case let .success(key):
                self?.exposureConfirmationKey = key
                self?.state = .uploadKeys(confirmationKey: key)
            case .failure:
                self?.state = .loadingError
            }
        }
    }
}

private protocol ShareKeyViaWebsiteViewListener: AnyObject {
    func didRequestShareCodes()
    func didRequestRequestConfirmationKey()
    func didRequestWebsiteOpen()
}

private final class ShareKeyViaWebsiteView: View {
    
    weak var listener: ShareKeyViaWebsiteViewListener?
    
    fileprivate let infoView: InfoView
    
    private let showWebsiteLink: Bool
    
    private var content: NSAttributedString {
        let header = NSAttributedString(string: .moreInformationKeySharingCoronaTestTitle,
                                        attributes: [
                                            NSAttributedString.Key.foregroundColor: theme.colors.gray,
                                            NSAttributedString.Key.font: theme.fonts.body
                                        ])
        let howDoesItWork = NSAttributedString(string: .moreInformationKeySharingCoronaTestHowDoesItWork,
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
    
    private lazy var stepStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        return stackView
    }()
    
    fileprivate lazy var shareYourCodesLoading: InfoSectionStepView = {
        InfoSectionStepView(theme: theme,
                            title: .moreInformationKeySharingCoronaTestStep1Title,
                            stepImage: .moreInformationStep1,
                            loadingIndicatorTitle: .moreInformationInfectedLoading)
    }()
    
    fileprivate lazy var shareYourCodesError: InfoSectionStepView = {
        InfoSectionStepView(theme: theme,
                            title: .moreInformationKeySharingCoronaTestStep1Title,
                            description: .moreInformationInfectedError,
                            stepImage: .moreInformationStep1,
                            buttonTitle: .retry,
                            disabledButtonTitle: .retry,
                            buttonActionHandler: { [weak self] in
                                self?.listener?.didRequestRequestConfirmationKey()
                            })
    }()
    
    fileprivate lazy var shareYourCodes: InfoSectionStepView = {
        InfoSectionStepView(theme: theme,
                            title: .moreInformationKeySharingCoronaTestStep1Title,
                            stepImage: .moreInformationStep1,
                            buttonTitle: .moreInformationKeySharingCoronaTestStep1Button,
                            disabledButtonTitle: .moreInformationKeySharingCoronaTestStep1Done,
                            buttonActionHandler: { [weak self] in
                                self?.listener?.didRequestShareCodes()
                            })
    }()
    
    fileprivate lazy var shareYourCodesDone: InfoSectionStepView = {
        let view = InfoSectionStepView(theme: theme,
                            title: .moreInformationKeySharingCoronaTestStep1Title,
                            stepImage: .moreInformationStep1,
                            disabledStepImage: .moreInformationStep1Gray,
                            buttonTitle: .moreInformationKeySharingCoronaTestStep1Button,
                            disabledButtonTitle: .moreInformationKeySharingCoronaTestStep1Done,
                            buttonActionHandler: { [weak self] in
                                self?.listener?.didRequestShareCodes()
                            }, isDisabled: true)
        
        view.buttonEnabled = false
        return view
    }()
    
    
    fileprivate lazy var controlCode: InfoSectionDynamicCalloutView = {
        InfoSectionDynamicCalloutView(theme: theme,
                                      title: .moreInformationKeySharingCoronaTestStep2Title,
                                      stepImage: .moreInformationStep2,
                                      disabledStepImage: .moreInformationStep2Gray,
                                      initialState: .disabled)
    }()
    
    fileprivate func goToWebsite(disabled: Bool) -> InfoSectionStepView {
        let buttonTitle: String? = showWebsiteLink ? .moreInformationKeySharingCoronaTestStep3Button : nil
        let buttonActionHandler: (() ->())? = showWebsiteLink ? { [weak self] in self?.listener?.didRequestWebsiteOpen()} : nil
        
        return InfoSectionStepView(theme: theme,
                                   title: .moreInformationKeySharingCoronaTestStep3Title,
                                   stepImage: .moreInformationStep3,
                                   disabledStepImage: .moreInformationStep3Gray,
                                   buttonTitle: buttonTitle,
                                   buttonActionHandler: buttonActionHandler,
                                   isDisabled: disabled)
    }
    
    fileprivate func youAreDone(disabled: Bool) -> InfoSectionStepView {
        InfoSectionStepView(theme: theme,
                            title: .moreInformationKeySharingCoronaTestStep4Title,
                            description: .moreInformationKeySharingCoronaTestStep4Content,
                            stepImage: .moreInformationStep4,
                            disabledStepImage: .moreInformationStep4Gray,
                            isLastStep: true,
                            isDisabled: disabled)
    }
    
    private lazy var cardContentView: View = View(theme: theme)
    
    // MARK: - Init
    
    init(theme: Theme, showWebsiteLink: Bool) {
        let config = InfoViewConfig(actionButtonTitle: .moreInformationKeySharingCoronaTestComplete,
                                    headerImage: .infectedHeader,
                                    stickyButtons: true)
        self.showWebsiteLink = showWebsiteLink
        self.infoView = InfoView(theme: theme, config: config, itemSpacing: 24)
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
    
    // MARK: - Public
    
    func update(state: ShareKeyViaWebsiteState) {
        
        DispatchQueue.main.async { [weak self] in
            
            guard let self = self else { return }
            
            var websiteButtonSectionDisabled = true
            var completionSectionDisabled = true
            var actionButtonEnabled = false
            
            self.stepStackView.arrangedSubviews.forEach({ $0.removeFromSuperview()})
            
            switch state {
            
            case .loading:
                self.stepStackView.addArrangedSubview(self.shareYourCodesLoading)
                self.controlCode.set(state: .disabled)
            case .loadingError:
                self.stepStackView.addArrangedSubview(self.shareYourCodesError)
                self.controlCode.set(state: .disabled)
            case .uploadKeys(_):
                self.stepStackView.addArrangedSubview(self.shareYourCodes)
                self.controlCode.set(state: .disabled)
            case .keysUploaded(let key):
                self.stepStackView.addArrangedSubview(self.shareYourCodesDone)
                self.controlCode.set(state: .success(key.key))
                
                websiteButtonSectionDisabled = false
                completionSectionDisabled = false
                actionButtonEnabled = true
            }
            
            self.stepStackView.addArrangedSubview(self.controlCode)
            self.stepStackView.addArrangedSubview(self.goToWebsite(disabled: websiteButtonSectionDisabled))
            self.stepStackView.addArrangedSubview(self.youAreDone(disabled: completionSectionDisabled))
            
            self.infoView.isActionButtonEnabled = actionButtonEnabled
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
