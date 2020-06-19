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
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        moreInformationView.set(data: objects, listener: self)
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
                                                         title: "Over de app",
                                                         subtitle: "Hoe de app werkt en wat dit voor je privacy betekent.")

        let receivedNotificationModel = MoreInformationCellViewModel(identifier: .receivedNotification,
                                                                     icon: Image.named("Warning"),
                                                                     title: "Een melding ontvangen?",
                                                                     subtitle: "Wat je kunt doen nadat iemand anders het virus blijkt te hebben.")

        let requestTestModel = MoreInformationCellViewModel(identifier: .requestTest,
                                                            icon: Image.named("Coronatest"),
                                                            title: "Coronatest aanvragen",
                                                            subtitle: "Ontdek zo snel mogelijk of je zelf besmet bent.")

        let infectedModel = MoreInformationCellViewModel(identifier: .infected,
                                                         icon: Image.named("Infected"),
                                                         title: "Ik ben positief getest",
                                                         subtitle: "Waarschuw anderen anoniem meteen nadat je hoort dat je besmet bent.")

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

    var didSelectItem: ((MoreInformationIdentifier) -> ())?

    private let headerLabel: Label
    private let stackView: UIStackView

    // MARK: - Init

    override init(theme: Theme) {
        self.headerLabel = Label()
        self.stackView = UIStackView(frame: .zero)
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        headerLabel.text = "MEER INFORMATIE"
        headerLabel.font = theme.fonts.footnote // TODO: Should actually be bold

        stackView.axis = .vertical
        stackView.distribution = .fill

        addSubview(headerLabel)
        addSubview(stackView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        headerLabel.snp.makeConstraints { (maker: ConstraintMaker) in
            maker.top.equalToSuperview().offset(16)
            maker.leading.trailing.equalToSuperview().inset(16)
        }
        stackView.snp.makeConstraints { maker in
            maker.top.equalTo(headerLabel.snp.bottom).offset(16)
            maker.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - Private

    fileprivate func set(data: [MoreInformation], listener: MoreInformationCellListner) {
        for object in data {
            let view = MoreInformationCell(listener: listener, theme: theme, data: object)
            stackView.addArrangedSubview(view)
        }
    }
}
