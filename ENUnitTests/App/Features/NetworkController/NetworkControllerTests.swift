/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

//
//  NetworkController.swift
//  ENTests
//
//  Created by Leon Boon on 15/06/2020.
//
@testable import EN
import XCTest

final class NetworkControllerTests: XCTestCase {

    private var networkController: NetworkController!
    private let networkManager = NetworkManagingMock()
    private let storageController = StorageControllingMock()

    override func setUp() {
        super.setUp()

        networkController = NetworkController(networkManager: networkManager,
                                              storageController: storageController)
    }
}
