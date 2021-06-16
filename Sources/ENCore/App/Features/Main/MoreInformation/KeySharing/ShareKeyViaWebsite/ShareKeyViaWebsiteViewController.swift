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

final class ShareKeyViaWebsiteViewController: ViewController, ShareKeyViaWebsiteViewControllable, UIAdaptivePresentationControllerDelegate, Logging, ShareKeyViaWebsiteViewListener {
    
    enum State {
        /// Busy loading the labconfirmation key from the EN API
        case loading
        
        /// User is given the option to share the keys
        case uploadKeys(confirmationKey: ExposureConfirmationKey)
        
        /// Requesting the labconfirmation key from the EN API failed
        case loadingError
        
        /// the keys were shared, user is given the option to copy the lab confirmation key so he can enter it on the website
        case keysUploaded(confirmationKey: ExposureConfirmationKey)
    }
    
    weak var router: ShareKeyViaWebsiteRouting?
    
    private var disposeBag = DisposeBag()
    private let exposureController: ExposureControlling
    private let exposureStateStream: ExposureStateStreaming
    private let applicationController: ApplicationControlling
    private let interfaceOrientationStream: InterfaceOrientationStreaming
    private var cardViewController: ViewControllable?
    
    private lazy var internalView: ShareKeyViaWebsiteView = {
        let view = ShareKeyViaWebsiteView(theme: self.theme, showWebsiteLink: exposureController.getStoredShareKeyURL() != nil)
        return view
    }()
    
    var state: State = .loading {
        didSet {
            updateState()
        }
    }
    
    init(theme: Theme,
         exposureController: ExposureControlling,
         exposureStateStream: ExposureStateStreaming,
         interfaceOrientationStream: InterfaceOrientationStreaming,
         applicationController: ApplicationControlling) {
        self.exposureController = exposureController
        self.exposureStateStream = exposureStateStream
        self.interfaceOrientationStream = interfaceOrientationStream
        self.applicationController = applicationController
        
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
        
        updateState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setThemeNavigationBar(withTitle: .moreInformationInfectedTitle, topItem: navigationItem)
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
    
    private func updateState() {
        DispatchQueue.main.async {
            switch self.state {
            case .loading:
                self.internalView.infoView.isActionButtonEnabled = false
                self.internalView.controlCode.set(state: .disabled)
                self.internalView.shareYourCodes.buttonEnabled = false
            case .uploadKeys:
                self.internalView.infoView.isActionButtonEnabled = false
                self.internalView.shareYourCodes.buttonEnabled = true
                self.internalView.controlCode.set(state: .disabled)
            case let .keysUploaded(key):
                self.internalView.controlCode.set(state: .success(key.key))
                
                self.internalView.infoView.isActionButtonEnabled = true
                self.internalView.shareYourCodes.buttonEnabled = false
                self.internalView.goToWebsite.isDisabled = false
                self.internalView.youAreDone.isDisabled = false
                
            case .loadingError:
                self.internalView.infoView.isActionButtonEnabled = false
                
                // "retry" action should move to the 1st step of this flow
//                self.internalView.controlCode.set(state: .error(.moreInformationInfectedError) { [weak self] in
//                    self?.requestLabConfirmationKey()
//                })
            }
        }
    }
    
    private func requestLabConfirmationKey() {
        state = .loading
        exposureController.requestLabConfirmationKey { [weak self] result in
            switch result {
            case let .success(key):
                self?.state = .uploadKeys(confirmationKey: key)
            case .failure:
                self?.state = .loadingError
            }
        }
    }
}

private protocol ShareKeyViaWebsiteViewListener: AnyObject {
    func didRequestShareCodes()
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
    
    private lazy var stepStackView: UIView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        
        stackView.addArrangedSubview(shareYourCodes)
        stackView.addArrangedSubview(controlCode)
        stackView.addArrangedSubview(goToWebsite)
        stackView.addArrangedSubview(youAreDone)
        return stackView
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
    
    fileprivate lazy var controlCode: InfoSectionDynamicCalloutView = {
        InfoSectionDynamicCalloutView(theme: theme,
                                      title: .moreInformationKeySharingCoronaTestStep2Title,
                                      stepImage: .moreInformationStep2,
                                      disabledStepImage: .moreInformationStep2Gray,
                                      initialState: .disabled)
    }()
    
    fileprivate lazy var goToWebsite: InfoSectionStepView = {
        let buttonTitle: String? = showWebsiteLink ? .moreInformationKeySharingCoronaTestStep3Button : nil
        let buttonActionHandler: (() ->())? = showWebsiteLink ? { [weak self] in self?.listener?.didRequestWebsiteOpen()} : nil
        
        return InfoSectionStepView(theme: theme,
                                   title: .moreInformationKeySharingCoronaTestStep3Title,
                                   stepImage: .moreInformationStep3,
                                   disabledStepImage: .moreInformationStep3Gray,
                                   buttonTitle: buttonTitle,
                                   buttonActionHandler: buttonActionHandler,
                                   isDisabled: true)
    }()
    
    fileprivate lazy var youAreDone: InfoSectionStepView = {
        InfoSectionStepView(theme: theme,
                            title: .moreInformationKeySharingCoronaTestStep4Title,
                            description: .moreInformationKeySharingCoronaTestStep4Content,
                            stepImage: .moreInformationStep4,
                            disabledStepImage: .moreInformationStep4Gray,
                            isLastStep: true,
                            isDisabled: true)
    }()
    
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
