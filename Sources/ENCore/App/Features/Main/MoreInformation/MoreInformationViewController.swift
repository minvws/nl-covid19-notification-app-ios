/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

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
                                                         icon: Image.named("About"),
                                                         title: Localization.string(for: "moreInformation.cell.about.title"),
                                                         subtitle: Localization.string(for: "moreInformation.cell.about.subtitle"))

        let receivedNotificationModel = MoreInformationCellViewModel(identifier: .receivedNotification,
                                                                     icon: Image.named("Warning"),
                                                                     title: Localization.string(for: "moreInformation.cell.receivedNotification.title"),
                                                                     subtitle: Localization.string(for: "moreInformation.cell.receivedNotification.subtitle"))

        let requestTestModel = MoreInformationCellViewModel(identifier: .requestTest,
                                                            icon: Image.named("Coronatest"),
                                                            title: Localization.string(for: "moreInformation.cell.requestTest.title"),
                                                            subtitle: Localization.string(for: "moreInformation.cell.requestTest.subtitle"))

        let infectedModel = MoreInformationCellViewModel(identifier: .infected,
                                                         icon: Image.named("Infected"),
                                                         title: Localization.string(for: "moreInformation.cell.infected.title"),
                                                         subtitle: Localization.string(for: "moreInformation.cell.infected.subtitle"))

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

    private let headerLabel: Label
    private let stackView: UIStackView
    private let versionLabel: Label

    // MARK: - Init

    override init(theme: Theme) {
        self.headerLabel = Label()
        self.stackView = UIStackView(frame: .zero)
        self.versionLabel = Label()
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        headerLabel.text = Localization.string(for: "moreInformation.headerTitle").uppercased()
        headerLabel.font = theme.fonts.footnote // TODO: Should actually be bold
        headerLabel.accessibilityTraits = .header

        stackView.axis = .vertical
        stackView.distribution = .fill

        versionLabel.textAlignment = .center
        headerLabel.font = theme.fonts.footnote

        addSubview(headerLabel)
        addSubview(stackView)
        addSubview(versionLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        headerLabel.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.equalToSuperview().offset(16)
            maker.leading.trailing.equalToSuperview().inset(16)
        }
        stackView.snp.makeConstraints { maker in
            maker.top.equalTo(headerLabel.snp.bottom).offset(16)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(versionLabel.snp.top).offset(-16)
        }
        versionLabel.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(hasHomeButton ? 16 : 0)
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
