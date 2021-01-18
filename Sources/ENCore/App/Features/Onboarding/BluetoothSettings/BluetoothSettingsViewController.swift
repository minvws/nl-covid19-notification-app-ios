/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation
import UIKit

/// @mockable
protocol BluetoothSettingsViewControllable: ViewControllable {}

final class BluetoothSettingsViewController: ViewController, BluetoothSettingsViewControllable, UITableViewDelegate, UITableViewDataSource {

    init(listener: BluetoothSettingsListener, theme: Theme) {
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

        internalView.tableView.dataSource = self
        internalView.tableView.delegate = self

        internalView.titleLabel.text = .enableBluetoothTitle

        NotificationCenter.default.addObserver(self, selector: #selector(checkBluetoothStatus), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - TableView

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: BluetoothSettingsTableViewCell
        let cellIdentifier = "BluetoothSettingsTableViewCell"

        if let aCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? BluetoothSettingsTableViewCell {
            cell = aCell
        } else {
            cell = BluetoothSettingsTableViewCell(theme: theme, reuseIdentifier: cellIdentifier)
        }

        let setting = settings[indexPath.row]

        cell.indexLabel.text = setting.index
        cell.titleLabel.attributedText = setting.title
        cell.settingsTitleLabel.text = setting.settingsTitle
        cell.settingsImageView.image = setting.image
        cell.disclosureImageView.isHidden = !setting.showDisclosure

        return cell
    }

    // MARK: - Private

    private weak var listener: BluetoothSettingsListener?
    private lazy var internalView: BluetoothSettingsView = BluetoothSettingsView(theme: self.theme, listener: listener)

    private lazy var settings: [BluetoothSettingsModel] = [
        BluetoothSettingsModel(index: .enableBluetoothSettingIndexRow1,
                               title: .makeFromHtml(text: .enableBluetoothSettingTitleRow1, font: theme.fonts.body, textColor: .black, textAlignment: Localization.isRTL ? .right : .left),
                               settingsTitle: .enableBluetoothSettingTitleSettingRow1,
                               image: .settingsIcon,
                               showDisclosure: false),
        BluetoothSettingsModel(index: .enableBluetoothSettingIndexRow2,
                               title: .makeFromHtml(text: .enableBluetoothSettingTitleRow2, font: theme.fonts.body, textColor: .black, textAlignment: Localization.isRTL ? .right : .left),
                               settingsTitle: .enableBluetoothSettingTitleSettingRow2,
                               image: .bluetoothIcon,
                               showDisclosure: true),
        BluetoothSettingsModel(index: .enableBluetoothSettingIndexRow3,
                               title: .makeFromHtml(text: .enableBluetoothSettingTitleRow3, font: theme.fonts.body, textColor: .black, textAlignment: Localization.isRTL ? .right : .left),
                               settingsTitle: .enableBluetoothSettingTitleSettingRow3,
                               image: .switchIcon,
                               showDisclosure: false)
    ]
    @objc private func checkBluetoothStatus() {
        self.listener?.isBluetoothEnabled { enabled in
            if enabled {
                self.listener?.bluetoothSettingsDidComplete()
            }
        }
    }
}

private final class BluetoothSettingsView: View {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = theme.fonts.largeTitle
        label.accessibilityTraits = .header
        return label
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.estimatedRowHeight = 130
        tableView.rowHeight = UITableView.automaticDimension

        tableView.showsVerticalScrollIndicator = true
        tableView.showsHorizontalScrollIndicator = false
        tableView.isScrollEnabled = true

        tableView.allowsSelection = false

        return tableView
    }()

    fileprivate lazy var navigationBar = UINavigationBar()

    private lazy var viewsInDisplayOrder = [tableView, titleLabel, navigationBar]
    private weak var listener: BluetoothSettingsListener?

    init(theme: Theme, listener: BluetoothSettingsListener?) {
        self.listener = listener
        super.init(theme: theme)
    }

    override func build() {
        super.build()

        let navigationItem = UINavigationItem()
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(target: self, action: #selector(didTapClose(sender:)))

        navigationBar.setItems([navigationItem], animated: false)
        navigationBar.makeTransparant()

        viewsInDisplayOrder.forEach { addSubview($0) }
    }

    @objc private func didTapClose(sender: UIBarButtonItem) {
        self.listener?.bluetoothSettingsDidComplete()
    }

    override func setupConstraints() {
        super.setupConstraints()

        hasBottomMargin = true

        navigationBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(20)
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(32)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
}

private class BluetoothSettingsTableViewCell: UITableViewCell {

    lazy var indexLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = theme.fonts.body
        label.accessibilityTraits = .header
        return label
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = theme.fonts.body
        label.accessibilityTraits = .header
        return label
    }()

    lazy var settingsTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = theme.fonts.body
        label.accessibilityTraits = .header
        return label
    }()

    lazy var settingsImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        return imageView
    }()

    lazy var disclosureImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        imageView.image = Image.named("DisclosureIcon")
        imageView.isHidden = true
        return imageView
    }()

    private lazy var settingsBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.00)
        view.layer.cornerRadius = 8
        return view
    }()

    init(theme: Theme, reuseIdentifier: String) {
        self.theme = theme
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        build()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func build() {

        addSubview(indexLabel)
        addSubview(titleLabel)
        addSubview(settingsBackgroundView)
        addSubview(settingsImageView)
        addSubview(settingsTitleLabel)
        addSubview(disclosureImageView)
    }

    func setupConstraints() {

        indexLabel.snp.makeConstraints { maker in
            maker.top.leading.equalToSuperview().inset(16)
            maker.height.equalTo(30)
            maker.width.equalTo(20)
        }

        titleLabel.snp.makeConstraints { maker in
            maker.top.trailing.equalToSuperview().inset(16)
            maker.leading.equalTo(indexLabel.snp.trailing)
            maker.height.equalTo(30)
        }

        settingsBackgroundView.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(8)
            maker.leading.trailing.equalToSuperview().inset(16)
            maker.height.equalTo(56)
            maker.bottom.equalToSuperview()
        }

        settingsImageView.snp.makeConstraints { maker in
            maker.top.equalTo(settingsBackgroundView.snp.top).inset(16)
            maker.leading.equalTo(settingsBackgroundView.snp.leading).inset(16)
            maker.height.equalTo(24)
            maker.width.equalTo(24)
        }

        settingsTitleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(settingsBackgroundView.snp.top)
            maker.leading.equalTo(settingsImageView.snp.trailing).offset(16)
            maker.trailing.equalTo(settingsBackgroundView.snp.trailing)
            maker.bottom.equalTo(settingsBackgroundView.snp.bottom)
        }

        disclosureImageView.snp.makeConstraints { maker in
            maker.top.equalTo(settingsBackgroundView.snp.top).inset(21)
            maker.trailing.equalTo(settingsBackgroundView.snp.trailing).inset(16)
            maker.height.equalTo(14)
            maker.width.equalTo(8)
        }
    }

    // MARK: - Private

    private let theme: Theme
}

private struct BluetoothSettingsModel {

    let index: String
    let title: NSAttributedString
    let settingsTitle: String
    let image: UIImage?
    let showDisclosure: Bool
}
