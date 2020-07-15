/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import SnapKit
import UIKit

/// @mockable
protocol InfectedRouting: Routing {
    func didUploadCodes(withKey key: ExposureConfirmationKey)
    func infectedWantsDismissal(shouldDismissViewController: Bool)
}

final class InfectedViewController: ViewController, InfectedViewControllable, UIAdaptivePresentationControllerDelegate {

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

    init(theme: Theme, exposureController: ExposureControlling) {
        self.exposureController = exposureController

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

        title = Localization.string(for: "moreInformation.infected.title")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                            target: self,
                                                            action: #selector(didTapCloseButton(sender:)))

        internalView.infoView.actionHandler = { [weak self] in
            self?.uploadCodes()
        }
        requestLabConfirmationKey()
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        router?.infectedWantsDismissal(shouldDismissViewController: false)
    }

    // MARK: - InfectedViewControllable

    func push(viewController: ViewControllable) {
        navigationController?.pushViewController(viewController.uiviewController, animated: true)
    }

    func thankYouWantsDismissal() {
        router?.infectedWantsDismissal(shouldDismissViewController: false)

        navigationController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - Private

    private func uploadCodes() {
        guard case let .success(key) = state else { return }

        exposureController.requestUploadKeys(forLabConfirmationKey: key) { [weak self] result in
            switch result {
            case .success:
                self?.router?.didUploadCodes(withKey: key)
            default:
                // TODO: Error Handling
                let alertController = UIAlertController(title: Localization.string(for: "error.title"),
                                                        message: Localization.string(for: "moreInformation.infected.error.uploadingCodes", ["\(result)"]),
                                                        preferredStyle: .alert)

                let alertAction = UIAlertAction(title: Localization.string(for: "ok"), style: .default) { _ in
                    alertController.dismiss(animated: true, completion: nil)
                }

                alertController.addAction(alertAction)

                self?.present(alertController, animated: true, completion: nil)
            }
        }
    }

    private lazy var internalView: InfectedView = InfectedView(theme: self.theme)
    private let exposureController: ExposureControlling

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        router?.infectedWantsDismissal(shouldDismissViewController: true)
    }

    private func updateState() {
        switch state {
        case .loading:
            internalView.infoView.isActionButtonEnabled = false
            internalView.controlCode.set(state: .loading(Localization.string(for: "moreInformation.infected.loading")))
        case let .success(key):
            internalView.infoView.isActionButtonEnabled = true
            internalView.controlCode.set(state: .success(key.key))
        case .error:
            internalView.infoView.isActionButtonEnabled = false
            internalView.controlCode.set(state: .error(Localization.string(for: "moreInformation.infected.error")) { [weak self] in
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
        let header = NSAttributedString(string: Localization.string(for: "moreInformation.infected.header"),
                                        attributes: [
                                            NSAttributedString.Key.foregroundColor: UIColor.black,
                                            NSAttributedString.Key.font: theme.fonts.body
                                        ])
        let howDoesItWork = NSAttributedString(string: Localization.string(for: "moreInformation.infected.how_does_it_work"),
                                               attributes: [
                                                   NSAttributedString.Key.foregroundColor: theme.colors.primary,
                                                   NSAttributedString.Key.font: theme.fonts.bodyBold
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
                                      title: Localization.string(for: "moreInformation.infected.step1"),
                                      stepImage: Image.named("MoreInformation.Step1"))
    }()

    private lazy var waitForTheGGD: View = {
        InfoSectionStepView(theme: theme,
                            title: Localization.string(for: "moreInformation.infected.step2"),
                            stepImage: Image.named("MoreInformation.Step2"))
    }()

    private lazy var shareYourCodes: View = {
        InfoSectionStepView(theme: theme,
                            title: Localization.string(for: "moreInformation.infected.step3"),
                            stepImage: Image.named("MoreInformation.Step3"))
    }()

    // MARK: - Init

    override init(theme: Theme) {
        let config = InfoViewConfig(actionButtonTitle: Localization.string(for: "moreInformation.infected.upload"),
                                    headerImage: Image.named("InfectedHeader"))
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
            shareYourCodes
        ])

        addSubview(infoView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        infoView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.bottom.leading.trailing.equalToSuperview()
        }
    }
}
