/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import ENFoundation
import Foundation

enum LocalFolder {
    case temporary
    case documents
    case cache
    case exposureKeySets
}

/// @mockable
protocol LocalPathProviding {
    func path(for folder: LocalFolder) -> URL?
}

final class LocalPathProvider: LocalPathProviding, Logging {

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        clearTemporaryFiles()
    }

    func path(for folder: LocalFolder) -> URL? {
        let path: URL?

        switch folder {
        case .cache:
            path = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        case .documents:
            path = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        case .temporary:
            path = fileManager.urls(for: .itemReplacementDirectory, in: .userDomainMask).first
        case .exposureKeySets:
            path = self.path(for: .documents)?.appendingPathComponent("exposureKeySets")
        }

        guard let finalPath = path else {
            return nil
        }

        return createFolder(with: finalPath) ? finalPath : nil
    }

    // MARK: - Private

    private func createFolder(with url: URL) -> Bool {
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            return false
        }
    }

    private func deleteFilesAtUrls(_ urls: [URL]) {
        urls.forEach { url in
            do {
                try fileManager.removeItem(at: url)
            } catch {
                logError("Error deleting file at url \(url) with error: \(error)")
            }
        }
    }

    private func retreiveContentsAt(_ directory: FileManager.SearchPathDirectory) -> [URL] {

        var files: [URL] = []
        let urls = fileManager.urls(for: directory, in: .userDomainMask)

        urls.forEach { url in
            do {
                let result = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
                files.append(contentsOf: result)
            } catch {
                logError("Error retreiving file at url \(url) with error: \(error) and SearchPathDirectory: \(directory)")
            }
        }

        return files
    }

    private func clearTemporaryFiles() {

        if volatileFileUrls.isEmpty {
            logDebug("Temporary directories are empty")
            return
        }

        logDebug("Deleting \(cachesDirectoryFileUrls.count) cachesDirectoryFileUrls")
        logDebug("Deleting \(temporaryDirectoryFileUrls.count) temporaryDirectoryFileUrls")

        deleteFilesAtUrls(volatileFileUrls)
    }

    private let fileManager: FileManager
    private var volatileFileUrls: [URL] {
        return cachesDirectoryFileUrls + temporaryDirectoryFileUrls
    }
    private var cachesDirectoryFileUrls: [URL] {
        return retreiveContentsAt(.cachesDirectory)
    }
    private var temporaryDirectoryFileUrls: [URL] {
        return retreiveContentsAt(.itemReplacementDirectory)
    }
}
