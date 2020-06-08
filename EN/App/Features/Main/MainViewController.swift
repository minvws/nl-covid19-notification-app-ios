/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

final class MainViewController: ViewController, MainViewControllable {
    
    // MARK: - View Lifecycle
    
    override func loadView() {
        self.view = mainView
    }
    
    // MARK: - Private
    
    private lazy var mainView: MainView = MainView()
}

private final class MainView: View {
    override func build() {
        super.build()
        
        backgroundColor = .orange
    }
}
