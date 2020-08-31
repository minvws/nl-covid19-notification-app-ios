/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import SnapKit
import UIKit
import WebKit

/// @mockable
protocol TechnicalInformationRouting: Routing {
    func routeToGithubPage()
}

final class TechnicalInformationViewController: ViewController, TechnicalInformationViewControllable {
    weak var router: TechnicalInformationRouting?

    init(listener: TechnicalInformationListener, theme: Theme) {
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
        navigationItem.rightBarButtonItem = self.navigationController?.navigationItem.rightBarButtonItem

        internalView.githubCardButton.action = { [weak self] in
            self?.router?.routeToGithubPage()
        }

        internalView.appInfoButton.action = { [weak self] in
            self?.listener?.technicalInformationRequestsToAppInformation()
        }
    }

    // MARK: - Private

    private weak var listener: TechnicalInformationListener?
    private lazy var internalView: TechnicalInformationView = TechnicalInformationView(theme: self.theme)
}

private final class TechnicalInformationView: View {

    override func build() {
        super.build()
        appInfoButton.backgroundColor = theme.colors.headerBackgroundBlue
        githubCardButton.backgroundColor = theme.colors.tertiary

        addSubview(scrollableStackView)

        buttonsWrapperView.addSubview(appInfoButton)
        buttonsWrapperView.addSubview(githubCardButton)

        scrollableStackView.attributedTitle = String.helpTechnicalInformationTitle.attributed()
        scrollableStackView.addSections([
            step1View,
            step2View,
            step3View,
            step4View,
            step5View,
            buttonsWrapperView
        ])
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollableStackView.snp.makeConstraints { maker in
            maker.top.leading.trailing.bottom.equalToSuperview()
        }

        appInfoButton.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview().inset(16)
        }

        githubCardButton.snp.makeConstraints { maker in
            maker.top.equalTo(appInfoButton.snp.bottom).offset(30)
            maker.leading.trailing.bottom.equalToSuperview().inset(16)
        }
    }

    lazy var githubCardButton = CardButton(title: .helpTechnicalInformationGithubTitle,
                                           subtitle: .helpTechnicalInformationGithubSubtitle,
                                           image: .githubLogo,
                                           type: .short,
                                           theme: theme)

    lazy var appInfoButton = CardButton(title: .aboutAppInformationTitle,
                                        subtitle: .aboutAppInformationDescription,
                                        image: .aboutAppInformation,
                                        type: .long,
                                        theme: theme)

    // MARK: - Private

    private lazy var scrollableStackView = ScrollableStackView(theme: theme)

    private lazy var step1View = InformationCardView(theme: theme,
                                                     image: UIImage.technicalInformationStep1,
                                                     title: String.helpTechnicalInformationStep1Title.attributed(),
                                                     message: String.helpTechnicalInformationStep1Description.attributed())

    private lazy var step2View = InformationCardView(theme: theme,
                                                     image: UIImage.technicalInformationStep2,
                                                     title: String.helpTechnicalInformationStep2Title.attributed(),
                                                     message: String.helpTechnicalInformationStep2Description.attributed())

    private lazy var step3View = InformationCardView(theme: theme,
                                                     image: UIImage.technicalInformationStep3,
                                                     title: String.helpTechnicalInformationStep3Title.attributed(),
                                                     message: String.helpTechnicalInformationStep3Description.attributed())

    private lazy var step4View = InformationCardView(theme: theme,
                                                     image: UIImage.technicalInformationStep4,
                                                     title: String.helpTechnicalInformationStep4Title.attributed(),
                                                     message: String.helpTechnicalInformationStep4Description.attributed())

    private lazy var step5View = InformationCardView(theme: theme,
                                                     image: UIImage.technicalInformationStep5,
                                                     title: String.helpTechnicalInformationStep5Title.attributed(),
                                                     message: String.helpTechnicalInformationStep5Description.attributed())

    private lazy var buttonsWrapperView = View(theme: theme)
}
