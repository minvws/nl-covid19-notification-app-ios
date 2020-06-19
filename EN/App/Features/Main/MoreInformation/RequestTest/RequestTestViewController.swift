/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import SnapKit
import UIKit

/// @mockable
protocol RequestTestViewControllable: ViewControllable {}

final class RequestTestViewController: ViewController, RequestTestViewControllable, UIAdaptivePresentationControllerDelegate {

    // MARK: - Init

    init(listener: RequestTestListener, theme: Theme) {
        self.listener = listener

        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Coronatest aanvragen"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                            target: self,
                                                            action: #selector(didTapCloseButton(sender:)))

        internalView.contactButtonActionHandler = {
            let urlString = "tel://08001202"
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                print("🔥 Unable to open \(urlString)")
            }
        }
    }

    // MARK: - Private

    private weak var listener: RequestTestListener?
    private lazy var internalView: RequestTestView = RequestTestView(theme: self.theme)

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.requestTestWantsDismissal(shouldDismissViewController: true)
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.requestTestWantsDismissal(shouldDismissViewController: false)
    }
}

private final class RequestTestView: View {

    var contactButtonActionHandler: (() -> ())? {
        get { infoView.actionHandler }
        set { infoView.actionHandler = newValue }
    }

    private let infoView: InfoView

    // MARK: - Init

    override init(theme: Theme) {
        let config = InfoViewConfig(actionButtonTitle: "Bel voor coronatest",
                                    headerImage: UIImage(named: "CoronatestHeader"))
        self.infoView = InfoView(theme: theme, config: config)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        infoView.addSections([
            receivedNotification(),
            complaints(),
            info()
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

    private func receivedNotification() -> View {
        // TODO: Bold Phone Number
        InfoSectionTextView(theme: theme, title: "Heb je een melding gekregen of twijfel je of je ziek bent? Vraag een test aan", content: NSAttributedString(string: "Als je een melding krijgt, raadt de GGD aan je te laten testen op het virus. Ook als je je nog niet ziek voelt. Heb je geen melding gekregen, maar wel last van klachten die bij het virus passen? Vraag ook dan een test aan.\n\nTesten is gratis en kan meestal snel gebeuren. Blijf zo veel mogelijk thuis tot de uitslag bekend is. Bel gratis 0800-1202 om een coranatest aan te vragen."))
    }

    private func complaints() -> View {
        let list = NSAttributedString.bulletList(["(licht) hoesten", "loopneus, niezen, keelpijn", "verlies van geur en/of smaak kortademigheid/benauwdheid", "koorts boven de 38 graden"],
                                                 theme: theme,
                                                 font: theme.fonts.body)
        let content = NSAttributedString(string: "Heb je klachten? Blijf dan zoveel mogelijk thuis. Zijn het ernstige klachten? Bel meteen je huisarts.")

        let string = NSMutableAttributedString()
        string.append(list)
        string.append(content)
        return InfoSectionTextView(theme: theme, title: "Klachten die passen bij het coronavirus (COVID-19)", content: string)
    }

    private func info() -> View {
        let string = NSAttributedString(string: "Houd je burgerservicenummer bij de hand. Dit vind je op je paspoort of identiteitskaart.")
        return InfoSectionCalloutView(theme: theme, content: string)
    }
}
