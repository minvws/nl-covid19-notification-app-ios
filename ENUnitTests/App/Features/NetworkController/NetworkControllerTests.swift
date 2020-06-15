//
//  NetworkController.swift
//  ENTests
//
//  Created by Leon Boon on 15/06/2020.
//
@testable import EN
import XCTest

class NetworkControllerTests: XCTestCase {

    private var networkController:NetworkController!
    private let networkManager = NetworkManagingMock()
    override func setUp() {
        networkController = NetworkController(networkManager: networkManager)
    }

}
