/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Combine
import ENFoundation
import SafariServices
import SnapKit
import UIKit

enum MoreInformationIdentifier: CaseIterable {
    case about
    case share
    case infected
    case receivedNotification
    case requestTest
}

protocol MoreInformation {
    var identifier: MoreInformationIdentifier { get }
    var icon: UIImage? { get }
    var title: String { get }
    var subtitle: String { get }
}

struct MoreInformationCellViewModel: MoreInformation {
    let identifier: MoreInformationIdentifier
    let icon: UIImage?
    let title: String
    let subtitle: String
}

final class MoreInformationViewController: ViewController, MoreInformationViewControllable, MoreInformationCellListner, Logging {

    // MARK: - Init

    init(listener: MoreInformationListener,
         theme: Theme,
         testPhaseStream: AnyPublisher<Bool, Never>, bundleInfoDictionary: [String: Any]?) {
        self.listener = listener
        self.testPhaseStream = testPhaseStream
        self.bundleInfoDictionary = bundleInfoDictionary

        super.init(theme: theme)
    }

    deinit {
        disposeBag.forEach { $0.cancel() }
    }

    // MARK: - View Lifecycle

    override func loadView() {
        self.view = moreInformationView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        moreInformationView.set(data: objects, listener: self)

        if let dictionary = bundleInfoDictionary,
            let version = dictionary["CFBundleShortVersionString"] as? String,
            let build = dictionary["CFBundleVersion"] as? String,
            let hash = dictionary["GitHash"] as? String {
            moreInformationView.version = "\(version) (\(build), \(hash))"

            testPhaseStream
                .sink(receiveValue: { isTestPhase in
                    if isTestPhase {
                        self.moreInformationView.version = .testVersionTitle(version, build)
                        self.moreInformationView.learnMoreButton.isHidden = false
                    }
                }).store(in: &disposeBag)
        }

        moreInformationView.learnMoreButton.addTarget(self, action: #selector(didTapLearnMore(sender:)), for: .touchUpInside)
    }

    // MARK: - MoreInformationCellListner

    func didSelect(identifier: MoreInformationIdentifier) {
        switch identifier {
        case .about:
            listener?.moreInformationRequestsAbout()
        case .share:
            listener?.moreInformationRequestsSharing()
        case .infected:
            listener?.moreInformationRequestsInfected()
        case .receivedNotification:
            listener?.moreInformationRequestsReceivedNotification()
        case .requestTest:
            listener?.moreInformationRequestsRequestTest()
        }
    }

    // MARK: - Private

    private var objects: [MoreInformation] {
        let aboutAppModel = MoreInformationCellViewModel(identifier: .about,
                                                         icon: .about,
                                                         title: .moreInformationCellAboutTitle,
                                                         subtitle: .moreInformationCellAboutSubtitle)

        let shareAppModel = MoreInformationCellViewModel(identifier: .share,
                                                         icon: .share,
                                                         title: .moreInformationCellShareTitle,
                                                         subtitle: .moreInformationCellShareSubtitle)

        let receivedNotificationModel = MoreInformationCellViewModel(identifier: .receivedNotification,
                                                                     icon: .warning,
                                                                     title: .moreInformationCellReceivedNotificationTitle,
                                                                     subtitle: .moreInformationCellReceivedNotificationSubtitle)

        let requestTestModel = MoreInformationCellViewModel(identifier: .requestTest,
                                                            icon: .coronatest,
                                                            title: .moreInformationCellRequestTestTitle,
                                                            subtitle: .moreInformationCellRequestTestSubtitle)

        let infectedModel = MoreInformationCellViewModel(identifier: .infected,
                                                         icon: .infected,
                                                         title: .moreInformationCellInfectedTitle,
                                                         subtitle: .moreInformationCellInfectedSubtitle)

        return [
            aboutAppModel,
            shareAppModel,
            receivedNotificationModel,
            requestTestModel,
            infectedModel
        ]
    }

    private lazy var moreInformationView: MoreInformationView = MoreInformationView(theme: self.theme)
    private weak var listener: MoreInformationListener?
    private let testPhaseStream: AnyPublisher<Bool, Never>
    private var disposeBag = Set<AnyCancellable>()
    private let bundleInfoDictionary: [String: Any]?

    @objc private func didTapLearnMore(sender: Button) {
        guard let url = URL(string: .helpTestVersionLink) else {
            return logError("Cannot create URL from: \(String.helpTestVersionLink)")
        }
        let viewController = SFSafariViewController(url: url)
        viewController.dismissButtonStyle = .close
        viewController.modalPresentationStyle = .automatic
        present(viewController, animated: true) {}
    }
}

private final class MoreInformationView: View {

    fileprivate var version: String? {
        get { versionLabel.text }
        set { versionLabel.text = newValue }
    }
    var didSelectItem: ((MoreInformationIdentifier) -> ())?

    private let stackView: UIStackView
    private let versionLabel: Label
    fileprivate let learnMoreButton: Button

    // MARK: - Init

    override init(theme: Theme) {
        self.stackView = UIStackView(frame: .zero)
        self.versionLabel = Label()
        self.learnMoreButton = Button(title: .learnMore, theme: theme)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        stackView.axis = .vertical
        stackView.distribution = .fill

        versionLabel.font = theme.fonts.footnote
        versionLabel.textColor = theme.colors.gray
        versionLabel.textAlignment = .center
        learnMoreButton.style = .info
        learnMoreButton.titleLabel?.font = theme.fonts.footnote
        learnMoreButton.isHidden = true

        addSubview(stackView)
        addSubview(versionLabel)
        addSubview(learnMoreButton)
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        stackView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(16)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(versionLabel.snp.top).offset(-16)
        }
        versionLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
        }
        learnMoreButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(versionLabel.snp.bottom)
            constrainToSafeLayoutGuidesWithBottomMargin(maker: maker)
        }
    }

    // MARK: - Private

    fileprivate func set(data: [MoreInformation], listener: MoreInformationCellListner) {
        let lastIndex = data.count - 1
        for (index, object) in data.enumerated() {
            let borderIsHidden = index == lastIndex
            let view = MoreInformationCell(listener: listener, theme: theme, data: object, borderIsHidden: borderIsHidden)
            stackView.addArrangedSubview(view)
        }
    }
}
