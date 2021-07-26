/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import SafariServices
import SnapKit
import UIKit

/// @mockable
protocol EndOfLifeViewControllable: ViewControllable {}

final class EndOfLifeViewController: ViewController, EndOfLifeViewControllable, Logging {

    private static let endOfLifeURL = "https://coronamelder.nl"

    init(listener: EndOfLifeListener, theme: Theme) {
        self.listener = listener

        super.init(theme: theme)

        modalPresentationStyle = .fullScreen
    }

    // MARK: - ViewController Lifecycle

    override func loadView() {
        self.view = internalView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        internalView.actionButton.addTarget(self, action: #selector(didTapActionButton(sender:)), for: .touchUpInside)
    }

    // MARK: - Private

    private weak var listener: EndOfLifeListener?
    private lazy var internalView: EndOfLifeView = EndOfLifeView(theme: self.theme)

    @objc private func didTapActionButton(sender: Button) {
        guard let url = URL(string: EndOfLifeViewController.endOfLifeURL) else {
            return logError("Cannot create URL from: \(EndOfLifeViewController.endOfLifeURL)")
        }
        listener?.endOfLifeRequestsRedirect(to: url)
    }
}

private final class EndOfLifeView: View {

    private let headerImageView: UIImageView
    private let titleLabel: Label
    private let descriptionLabel: Label
    fileprivate let actionButton: Button

    private let contentView: UIView
    private let scrollView: UIScrollView

    // MARK: - Init

    override init(theme: Theme) {
        self.headerImageView = UIImageView(image: Image.illustrationNotification)
        self.titleLabel = Label()
        self.descriptionLabel = Label()
        self.actionButton = Button(title: .learnMore, theme: theme)

        self.contentView = UIView(frame: .zero)
        self.scrollView = UIScrollView(frame: .zero)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        headerImageView.contentMode = .scaleAspectFit
        contentView.backgroundColor = .clear

        titleLabel.numberOfLines = 0
        titleLabel.font = theme.fonts.title2
        titleLabel.text = .endOfLifeTitle

        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = theme.fonts.body
        descriptionLabel.text = .endOfLifeDescription

        contentView.addSubview(headerImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        scrollView.addSubview(contentView)
        addSubview(scrollView)
        addSubview(actionButton)
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        let imageAspectRatio = headerImageView.image?.aspectRatio ?? 1.0

        headerImageView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
            maker.height.equalTo(headerImageView.snp.width).dividedBy(imageAspectRatio)
        }
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(headerImageView.snp.bottom).offset(40)
            maker.leading.trailing.equalToSuperview().inset(16)
        }
        descriptionLabel.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(16)
            maker.leading.trailing.equalTo(titleLabel)
            maker.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.equalTo(scrollView)
            maker.bottom.equalTo(scrollView)
            maker.leading.trailing.equalTo(self)
        }
        scrollView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.width.equalToSuperview()
            maker.bottom.equalTo(actionButton.snp.top).inset(-16)
        }
        actionButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.height.equalTo(50)

            constrainToSafeLayoutGuidesWithBottomMargin(maker: maker)
        }
    }
}
