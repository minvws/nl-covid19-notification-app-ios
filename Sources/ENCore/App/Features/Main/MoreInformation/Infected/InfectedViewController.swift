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

    // NOTE: This is temp, should hook into the framework
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

        title = Localization.string(for: "moreInformation.infected.title")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                            target: self,
                                                            action: #selector(didTapCloseButton(sender:)))

        internalView.infoView.actionHandler = { [weak self] in
            self?.uploadCodes()
        }

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
                                                        message: Localization.string(for: "moreInformation.infected.error.uploadingCodes", "\(result)"),
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
            internalView.controlCode.set(state: .error(Localization.string(for: "moreInformation.infected.error")) {
                print("Handle Retry")
            })
        }
    }
}

private final class InfectedView: View {

    fileprivate let infoView: InfoView

    private lazy var anonomuslyWarnOthers: View = {
        InfoSectionTextView(theme: theme,
                            title: Localization.string(for: "moreInformation.infected.section.anonomuslyWarnOthers.title"),
                            content: Localization.attributedString(for: "moreInformation.infected.section.anonomuslyWarnOthers.content"))
    }()

    fileprivate lazy var controlCode: InfoSectionDynamicCalloutView = {
        InfoSectionDynamicCalloutView(theme: theme,
                                      title: Localization.string(for: "moreInformation.infected.section.controlCode.title"))
    }()

    private lazy var uploadCodes: View = {
        InfoSectionTextView(theme: theme,
                            title: Localization.string(for: "moreInformation.infected.section.controlCode.title"),
                            content: Localization.attributedString(for: "moreInformation.infected.section.controlCode.content"))
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
            anonomuslyWarnOthers,
            controlCode,
            uploadCodes
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
