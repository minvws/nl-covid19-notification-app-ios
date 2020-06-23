/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import SnapKit
import UIKit

/// @mockable
protocol MessageViewControllable: ViewControllable {}

final class MessageViewController: ViewController, MessageViewControllable, UIAdaptivePresentationControllerDelegate {

    struct Message {
        let title: String
        let body: String
    }

    // MARK: - Init

    init(listener: MessageListener, theme: Theme, message: Message) {
        self.listener = listener
        self.message = message

        super.init(theme: theme)
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Melding gekregen"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close,
                                                            target: self,
                                                            action: #selector(didTapCloseButton(sender:)))

        internalView.infoView.actionHandler = {
            let urlString = "tel://08001202"
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                print("🔥 Unable to open \(urlString)")
            }
        }
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.messageWantsDismissal(shouldDismissViewController: false)
    }

    // MARK: - Private

    private let message: Message

    private weak var listener: MessageListener?
    private lazy var internalView: MessageView = {
        MessageView(theme: self.theme, title: self.message.title, body: self.message.body)
    }()

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.messageWantsDismissal(shouldDismissViewController: true)
    }
}

private final class MessageView: View {

    fileprivate let infoView: InfoView
    private let title: String
    private let body: String

    // MARK: - Init

    init(theme: Theme, title: String, body: String) {
        self.title = title
        self.body = body
        let config = InfoViewConfig(actionButtonTitle: "Bel voor coronatest", headerImage: Image.named("MessageHeader"))
        self.infoView = InfoView(theme: theme, config: config)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        infoView.addSections([
            message(),
            complaints(),
            doCoronaTest(),
            info()
        ])

        addSubview(infoView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        infoView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.edges.equalToSuperview()
        }
    }

    // MARK: - Private

    private func message() -> View {
        InfoSectionTextView(theme: theme, title: title, content: NSAttributedString(string: body))
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

    private func doCoronaTest() -> View {
        // TODO: Bold Phone Number
        InfoSectionTextView(theme: theme, title: "Doe een coronatest", content: NSAttributedString(string: "De GGD raadt aan je te laten testen op het virus, zelfs als je je nog niet ziek voelt. Want zonder je ziek te voelen kun je het virus al verspreiden en zo anderen besmetten.\n\nTesten is gratis en kan meestal snel gebeuren. Blijf zo veel mogelijk thuis tot de uitslag bekend is.\n\nBel gratis 0800-1202 om een coranatest aan te vragen."))
    }

    private func info() -> View {
        let string = NSAttributedString(string: "Houd je burgerservicenummer bij de hand. Dit vind je op je paspoort of identiteitskaart.")
        return InfoSectionCalloutView(theme: theme, content: string)
    }
}
