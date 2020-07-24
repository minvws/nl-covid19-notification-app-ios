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

final class TechnicalInformationViewController: ViewController {

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
    }

    // MARK: - Private

    private weak var listener: TechnicalInformationListener?
    private lazy var internalView: TechnicalInformationView = TechnicalInformationView(theme: self.theme)
}

private final class TechnicalInformationView: View {

    private lazy var scrollableStackView = ScrollableStackView(theme: theme)

    override func build() {
        super.build()

        addSubview(scrollableStackView)

        scrollableStackView.attributedTitle = String.helpTechnicalInformationTitle.attributed()
        scrollableStackView.addSections([
            step1View,
            step2View,
            step3View,
            step4View,
            step5View
        ])
    }

    override func setupConstraints() {
        super.setupConstraints()

        scrollableStackView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.leading.trailing.bottom.equalToSuperview()
        }
    }

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
}
