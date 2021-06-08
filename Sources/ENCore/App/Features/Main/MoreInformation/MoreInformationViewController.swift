/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import RxSwift
import SafariServices
import SnapKit
import UIKit

enum MoreInformationIdentifier: CaseIterable {
    case about
    case settings
    case share
    case infected
    case receivedNotification
    case requestTest
    case shareKeyGGD
    case shareKeyWebsite
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
         bundleInfoDictionary: [String: Any]?,
         exposureController: ExposureControlling) {
        self.listener = listener
        self.bundleInfoDictionary = bundleInfoDictionary
        self.exposureController = exposureController
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

        self.exposureController.lastTEKProcessingDate()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { lastTEKProcessingDate in
                let date = self.formatTEKProcessingDateToString(lastTEKProcessingDate)
                self.moreInformationView.latestTekUpdate = .moreInformationLastTEKProcessingDateInformation(date)
            })
            .disposed(by: self.disposeBag)
        
        exposureController.updateLastExposureProcessingDateSubject()
        
        if let dictionary = bundleInfoDictionary,
            let version = dictionary["CFBundleShortVersionString"] as? String,
            let build = dictionary["CFBundleVersion"] as? String,
            let hash = dictionary["GitHash"] as? String {
            let buildAndHash = "\(build)-\(hash)"
            moreInformationView.version = "\(version) (\(buildAndHash))"
        }
    }

    // MARK: - MoreInformationCellListner

    func didSelect(identifier: MoreInformationIdentifier) {
        switch identifier {
        case .about:
            listener?.moreInformationRequestsAbout()
        case .settings:
            listener?.moreInformationRequestsSettings()
        case .share:
            listener?.moreInformationRequestsSharing()
        case .infected:
            listener?.moreInformationRequestsInfected()
        case .receivedNotification:
            listener?.moreInformationRequestsReceivedNotification()
        case .requestTest:
            listener?.moreInformationRequestsRequestTest()
        case .shareKeyGGD, .shareKeyWebsite:
            // Unhandled cases in this screen
            return
        }
    }

    // MARK: - Private

    private var objects: [MoreInformation] {
        let aboutAppModel = MoreInformationCellViewModel(identifier: .about,
                                                         icon: .about,
                                                         title: .moreInformationCellAboutTitle,
                                                         subtitle: .moreInformationCellAboutSubtitle)

        let settingsModel = MoreInformationCellViewModel(identifier: .settings,
                                                         icon: .settings,
                                                         title: .moreInformationCellSettingsTitle,
                                                         subtitle: .moreInformationCellSettingsSubtitle)

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
            settingsModel,
            receivedNotificationModel,
            requestTestModel,
            shareAppModel,
            infectedModel
        ]
    }

    private lazy var moreInformationView: MoreInformationView = MoreInformationView(theme: self.theme)
    private weak var listener: MoreInformationListener?
    private var disposeBag = DisposeBag()
    private let bundleInfoDictionary: [String: Any]?
    private let exposureController: ExposureControlling

    private func formatTEKProcessingDateToString(_ date: Date?) -> String? {
        guard let date = date else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
}

private final class MoreInformationView: View {

    fileprivate var version: String? {
        get { versionLabel.text }
        set { versionLabel.text = newValue }
    }
    fileprivate var latestTekUpdate: String? {
        get { lastTEKProcessingDateLabel.text }
        set { lastTEKProcessingDateLabel.text = newValue }
    }
    var didSelectItem: ((MoreInformationIdentifier) -> ())?

    private let stackView: UIStackView
    private let versionLabel: Label
    private let lastTEKProcessingDateLabel: Label

    // MARK: - Init

    override init(theme: Theme) {
        self.stackView = UIStackView(frame: .zero)
        self.versionLabel = Label()
        self.lastTEKProcessingDateLabel = Label()
        super.init(theme: theme)
    }

    // MARK: - Overrides

    override func build() {
        super.build()

        stackView.axis = .vertical
        stackView.distribution = .fill

        lastTEKProcessingDateLabel.numberOfLines = 0
        lastTEKProcessingDateLabel.lineBreakMode = .byWordWrapping
        lastTEKProcessingDateLabel.font = theme.fonts.footnote
        lastTEKProcessingDateLabel.textColor = theme.colors.gray
        lastTEKProcessingDateLabel.textAlignment = .center

        versionLabel.font = theme.fonts.footnote
        versionLabel.textColor = theme.colors.gray
        versionLabel.textAlignment = .center

        addSubview(stackView)
        addSubview(lastTEKProcessingDateLabel)
        addSubview(versionLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        stackView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(16)
            maker.leading.trailing.equalTo(safeAreaLayoutGuide)
        }
        lastTEKProcessingDateLabel.snp.makeConstraints { maker in
            maker.top.equalTo(stackView.snp.bottom).offset(16)
            maker.leading.equalTo(stackView).offset(16)
            maker.trailing.equalTo(stackView).offset(-16)
        }
        versionLabel.snp.makeConstraints { maker in
            maker.top.equalTo(lastTEKProcessingDateLabel.snp.bottom).offset(16)
            maker.leading.trailing.equalTo(stackView)
            constrainToSafeLayoutGuidesWithBottomMargin(maker: maker)
        }
    }

    // MARK: - Private

    fileprivate func set(data: [MoreInformation], listener: MoreInformationCellListner) {
        let lastIndex = data.count - 1
        for (index, object) in data.enumerated() {
            let borderIsHidden = index == lastIndex
            let view = MoreInformationCell(listener: listener, theme: theme, data: object, borderIsHidden: borderIsHidden)
            stackView.addListSubview(view, index: index, total: data.count)
        }
    }
}
