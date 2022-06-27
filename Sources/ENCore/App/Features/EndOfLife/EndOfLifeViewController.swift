/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import RxSwift
import SafariServices
import SnapKit
import UIKit

/// @mockable
protocol EndOfLifeViewControllable: ViewControllable {}

final class EndOfLifeViewController: ViewController, EndOfLifeViewControllable, Logging {

    private static let endOfLifeURL = "https://coronamelder.nl"

    init(listener: EndOfLifeListener,
         theme: Theme,
         storageController: StorageControlling,
         interfaceOrientationStream: InterfaceOrientationStreaming) {
        self.listener = listener
        self.storageController = storageController
        self.interfaceOrientationStream = interfaceOrientationStream

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

        setupContent()

        internalView.showVisual = !(interfaceOrientationStream.currentOrientationIsLandscape ?? false)

        interfaceOrientationStream
            .isLandscape
            .subscribe { [weak self] isLandscape in
                self?.internalView.showVisual = !isLandscape
            }.disposed(by: disposeBag)
    }

    // MARK: - Private

    private weak var listener: EndOfLifeListener?
    private lazy var internalView: EndOfLifeView = EndOfLifeView(theme: self.theme)
    private let storageController: StorageControlling
    private let interfaceOrientationStream: InterfaceOrientationStreaming
    private var disposeBag = DisposeBag()

    @objc private func didTapActionButton(sender: Button) {
        guard let url = URL(string: EndOfLifeViewController.endOfLifeURL) else {
            return logError("Cannot create URL from: \(EndOfLifeViewController.endOfLifeURL)")
        }
        listener?.endOfLifeRequestsRedirect(to: url)
    }

    private func setupContent() {
        guard let applicationConfiguration = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.appConfiguration),
            let resourceBundle: TreatmentPerspective = storageController.retrieveObject(identifiedBy: ExposureDataStorageKey.treatmentPerspective),
            let titleKey = applicationConfiguration.deactivationContent?.titleResourceKey,
            let bodyKey = applicationConfiguration.deactivationContent?.bodyResourceKey else {
            // Falling back to default
            return
        }

        let resource = resourceBundle.resources[.treatmentPerspectiveLanguage]
        let fallbackResource = resourceBundle.resources["en"]

        if let localizedTitle = resource?[titleKey], let localizedBody = resource?[bodyKey] {
            internalView.set(title: localizedTitle, body: localizedBody)
        } else if let fallbackTitle = fallbackResource?[titleKey], let fallbackBody = fallbackResource?[bodyKey] {
            internalView.set(title: fallbackTitle, body: fallbackBody)
        }

        // else use default set values
    }
}

private final class EndOfLifeView: View {

    private let headerImageView: UIImageView
    private let titleLabel: Label
    private let descriptionLabel: Label
    fileprivate let actionButton: Button

    private let contentView: UIView
    private let scrollView: UIScrollView
    private var imageCollapseConstraint: NSLayoutConstraint!

    var showVisual: Bool = true {
        didSet {
            imageCollapseConstraint.isActive = !showVisual
        }
    }

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
        titleLabel.accessibilityTraits = .header

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
            maker.height.equalTo(headerImageView.snp.width).dividedBy(imageAspectRatio).priority(.high)
        }
        imageCollapseConstraint = headerImageView.heightAnchor.constraint(equalToConstant: 0)
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
            maker.leading.trailing.equalToSuperview()
            maker.width.equalTo(scrollView.frameLayoutGuide)
        }
        scrollView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalTo(safeAreaLayoutGuide)
            maker.bottom.equalTo(actionButton.snp.top).inset(-16)
        }
        actionButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            maker.height.greaterThanOrEqualTo(50)

            constrainToSafeLayoutGuidesWithBottomMargin(maker: maker)
        }
    }

    func set(title: String, body: String) {
        titleLabel.text = title
        descriptionLabel.text = body
    }
}
