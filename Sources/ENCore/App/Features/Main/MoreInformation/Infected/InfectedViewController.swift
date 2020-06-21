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
    func didUploadCodes()
    func infectedWantsDismissal(shouldDismissViewController: Bool)
}

final class InfectedViewController: ViewController, InfectedViewControllable, UIAdaptivePresentationControllerDelegate {

    // NOTE: This is temp, should hook into the framework
    enum State {
        case loading
        case success
        case error
    }

    weak var router: InfectedRouting?

    var state: State = .loading {
        didSet {
            updateState()
        }
    }

    // MARK: - Overrides

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Positief getest"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                            target: self,
                                                            action: #selector(didTapCloseButton(sender:)))

        internalView.infoView.actionHandler = { [weak self] in
            self?.router?.didUploadCodes()
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

    private lazy var internalView: InfectedView = InfectedView(theme: self.theme)

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        router?.infectedWantsDismissal(shouldDismissViewController: true)
    }

    private func updateState() {
        switch state {
        case .loading:
            internalView.infoView.isActionButtonEnabled = false
            internalView.controlCode.set(state: .loading("Controlecode aan het ophalen"))
        case .success:
            internalView.infoView.isActionButtonEnabled = true
            internalView.controlCode.set(state: .success("A 4 5 - 3 2 F")) // TODO: Should be the real code
        case .error:
            internalView.infoView.isActionButtonEnabled = false
            internalView.controlCode.set(state: .error("Er kon geen controlecode worden opgehaald. Controleer je internet- verbinding en probeer het opnieuw.") {
                print("Handle Retry")
            })
        }
    }
}

private final class InfectedView: View {

    fileprivate let infoView: InfoView

    private lazy var anonomuslyWarnOthers: View = {
        InfoSectionTextView(theme: theme,
                            title: "Waarschuw anderen anoniem dat je besmet bent",
                            content: NSAttributedString(string: "Je kunt alleen mensen waarschuwen als je positief getest bent door de GGD. De GGD vraagt je tijdens een telefoongesprek naar dit scherm te gaan en de volgende instructies te volgen:"))
    }()

    fileprivate lazy var controlCode: InfoSectionDynamicCalloutView = {
        InfoSectionDynamicCalloutView(theme: theme, title: "1. Geef deze controlecode aan de GGD-medewerker:")
    }()

    private lazy var uploadCodes: View = {
        InfoSectionTextView(theme: theme,
                            title: "2. Upload de codes die op je telefoon bewaard zijn",
                            content: NSAttributedString(string: "Alle mensen met de app waarbij je, in de periode dat je besmettelijk was, in de buurt bent geweest krijgen daarna een melding. Deze melding is anoniem."))
    }()

    // MARK: - Init

    override init(theme: Theme) {
        let config = InfoViewConfig(actionButtonTitle: "Codes uploaden",
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
