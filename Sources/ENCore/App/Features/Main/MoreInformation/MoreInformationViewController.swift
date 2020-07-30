/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import SnapKit
import UIKit

enum MoreInformationIdentifier {
    case about
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

final class MoreInformationViewController: ViewController, MoreInformationViewControllable, MoreInformationCellListner {

    // MARK: - Init

    init(listener: MoreInformationListener, theme: Theme) {
        self.listener = listener

        super.init(theme: theme)
    }

    // MARK: - View Lifecycle

    override func loadView() {
        self.view = moreInformationView
        self.view.frame = UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        moreInformationView.set(data: objects, listener: self)

        if let dictionary = Bundle.main.infoDictionary,
            let version = dictionary["CFBundleShortVersionString"] as? String,
            let build = dictionary["CFBundleVersion"] as? String {
            moreInformationView.version = "v\(version) (\(build))"
        }
    }

    // MARK: - MoreInformationCellListner

    func didSelect(identifier: MoreInformationIdentifier) {
        switch identifier {
        case .about:
            listener?.moreInformationRequestsAbout()
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
            receivedNotificationModel,
            requestTestModel,
            infectedModel
        ]
    }

    private lazy var moreInformationView: MoreInformationView = MoreInformationView(theme: self.theme)

    private weak var listener: MoreInformationListener?
}

private final class MoreInformationView: View {

    fileprivate var version: String? {
        get { versionLabel.text }
        set { versionLabel.text = newValue }
    }
    var didSelectItem: ((MoreInformationIdentifier) -> ())?

    private let stackView: UIStackView
    private let versionLabel: Label

    // MARK: - Init

    override init(theme: Theme) {
        self.stackView = UIStackView(frame: .zero)
        self.versionLabel = Label()
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        stackView.axis = .vertical
        stackView.distribution = .fill

        versionLabel.textAlignment = .center

        addSubview(stackView)
        addSubview(versionLabel)
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
