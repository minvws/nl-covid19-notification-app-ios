/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import Foundation

/// @mockable
protocol ReceivedNotificationViewControllable: ViewControllable {
    
}

final class ReceivedNotificationViewController: ViewController, ReceivedNotificationViewControllable {
    
    init(listener: ReceivedNotificationListener) {
        self.listener = listener
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - ViewController Lifecycle
    
    override func loadView() {
        self.view = internalView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: Implement or delete
    }
    
    // MARK: - Private
    
    private weak var listener: ReceivedNotificationListener?
    private lazy var internalView: ReceivedNotificationView = ReceivedNotificationView()
}

private final class ReceivedNotificationView: View {
    override func build() {
        super.build()
        
        // TODO: Construct View here or delete this function
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        // TODO: Setup constraints here or delete this function
    }
}
