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
protocol ReceivedNotificationViewControllable: ViewControllable {}

final class ReceivedNotificationViewController: ViewController, ReceivedNotificationViewControllable, UIAdaptivePresentationControllerDelegate {

    // MARK: - Init

    init(listener: ReceivedNotificationListener, theme: Theme) {
        self.listener = listener

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

    private weak var listener: ReceivedNotificationListener?
    private lazy var internalView: ReceivedNotificationView = ReceivedNotificationView(theme: self.theme)

    @objc private func didTapCloseButton(sender: UIBarButtonItem) {
        listener?.receivedNotificationWantsDismissal(shouldDismissViewController: true)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        listener?.receivedNotificationWantsDismissal(shouldDismissViewController: false)
    }
}

private final class ReceivedNotificationView: View {

    var contactButtonActionHandler: (() -> ())? {
        get { infoView.actionHandler }
        set { infoView.actionHandler = newValue }
    }

    private let infoView: InfoView

    // MARK: - Init

    override init(theme: Theme) {
        let config = InfoViewConfig(actionButtonTitle: "Bel voor coronatest",
                                    headerImage: Image.named("ReceivedNotificationHeader"))
        self.infoView = InfoView(theme: theme, config: config)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        infoView.addSections([
            notificationExplanation(),
            complaints(),
            doCoronaTest(),
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

    private func notificationExplanation() -> View {
        InfoSectionTextView(theme: theme, title: "Wat betekent het als je een melding krijgt?", content: NSAttributedString(string: "De app stuurt een melding als je 10 minuten dicht bij iemand bent geweest die daarna positief is getest op het virus. Ook moet deze persoon de app gebruiken. Het RIVM en de GGD zien het contact als een mogelijk gevaarlijke situatie. Voor jezelf en je omgeving."))
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
