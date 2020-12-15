/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import SnapKit
import UIKit

/// @mockable
protocol LaunchScreenRouting: Routing {}

final class LaunchScreenViewController: ViewController, LaunchScreenViewControllable {

    var router: LaunchScreenRouting?

    override init(theme: Theme) {
        super.init(theme: theme)

        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func loadView() {
        self.view = launchScreenView
    }

    private lazy var launchScreenView: LaunchScreenView = LaunchScreenView(theme: theme)
}

private final class LaunchScreenView: View {

    private lazy var onlyTogetherImage: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        imgView.image = .onlyTogetherCanWeControlCorona
        return imgView
    }()

    private lazy var rijkslintImage: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        imgView.image = .rijkslint
        return imgView
    }()

    private lazy var minVWSImage: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        imgView.image = .minVWS
        return imgView
    }()

    override func build() {
        super.build()

        addSubview(rijkslintImage)
        addSubview(minVWSImage)
        addSubview(onlyTogetherImage)
    }

    override func setupConstraints() {
        super.setupConstraints()

        rijkslintImage.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.safeAreaLayoutGuide).offset(-15)
        }

        minVWSImage.snp.makeConstraints { make in
            make.bottom.equalTo(rijkslintImage)
            make.leading.equalTo(rijkslintImage.snp.trailing).offset(8)
            make.trailing.equalTo(self.safeAreaLayoutGuide).inset(57)
            make.height.equalTo(50)
        }

        onlyTogetherImage.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(self.safeAreaLayoutGuide)
            make.height.equalTo(75)
            make.leading.trailing.equalTo(safeAreaLayoutGuide).inset(20)
        }
    }
}
