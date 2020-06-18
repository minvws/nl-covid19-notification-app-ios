/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import ZIPFoundation
enum UnzipNetworkResponseError: Error {
    case placeholder
    case cantOpenDirectory
}



final class UnzipNetworkResponseHandler: NetworkResponseHandling {
    
    let zip = "file.zip"
    
    let fileManager:FileManager
    init(fileManager:FileManager = FileManager.default) {
        self.fileManager = fileManager
    }
    
    func handle(url: URL) throws -> [URL] {
        
        let zipUrl = try self.moveToTemporaryLocation(url: url)
        let urls = try self.unzipAndMove(sourceURL: zipUrl)
        return urls
    }
    
    private func moveToTemporaryLocation(url:URL) throws -> URL {
        guard let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw UnzipNetworkResponseError.cantOpenDirectory
        }
        
        let zipUrl = cachesDirectory.appendingPathComponent(zip)
        try fileManager.moveItem(at: url, to: zipUrl)
        return zipUrl
    }
    
    func unzipAndMove(sourceURL: URL) throws -> [URL] {
        
        guard let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw UnzipNetworkResponseError.cantOpenDirectory
        }
        
        let destinationDirectory = cachesDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true, attributes: nil)
        try fileManager.unzipItem(at: sourceURL, to: destinationDirectory)
        
        // clean up zip file
        try fileManager.removeItem(at: sourceURL)
        
        let files = try fileManager.contentsOfDirectory(at: destinationDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        return files
    }
    
}
