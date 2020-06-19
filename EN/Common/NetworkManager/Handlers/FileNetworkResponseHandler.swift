/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import ZIPFoundation
enum UnzipNetworkResponseError: Error {
    case error
    case cantOpenDirectory
}


/// @mockable
protocol FileManaging {}
extension FileManager: FileManaging {}

final class FileNetworkResponseHandler {
    
    let localFile = "response.bin"
    
    let fileManager:FileManager
    init(fileManager:FileManager = FileManager.default) {
        self.fileManager = fileManager
    }
    
    func handle(url: URL,type: ContentType) throws -> [URL] {
        
        var urls = [URL]()
        let fileUrl = try self.moveToTemporaryLocation(url: url)
        
        if(type == .zip) {
            urls = try self.unzipAndMove(sourceURL: fileUrl)
        } else {
            urls.append(fileUrl)
        }
        return urls
    }
    
    private func moveToTemporaryLocation(url:URL) throws -> URL {
        
        guard let zipUrl = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(localFile) else {
            throw UnzipNetworkResponseError.error
        }
        
        // clean up possible old files
        try? fileManager.removeItem(at: zipUrl)
        // move
        try fileManager.moveItem(at: url, to: zipUrl)
        return zipUrl
    }
    
    func unzipAndMove(sourceURL: URL) throws -> [URL] {
        
        guard let destinationDirectory = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString) else {
            throw UnzipNetworkResponseError.error
        }
        
        try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true, attributes: nil)
        try fileManager.unzipItem(at: sourceURL, to: destinationDirectory)
        
        // clean up zip file
        try fileManager.removeItem(at: sourceURL)
        
        let files = try fileManager.contentsOfDirectory(at: destinationDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        return files
    }
    
}
