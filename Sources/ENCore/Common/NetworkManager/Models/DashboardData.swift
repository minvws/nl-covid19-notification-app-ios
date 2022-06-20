/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct DashboardData: Codable {
    struct MovingAverage: Codable {
        let start: Date
        let end: Date
        let value: Int
    }

    struct DatedValue: Codable {
        let date: Date
        let value: Int
    }

    struct PositiveTestResults: Codable {
        let sortingValue: Int
        let values: [DatedValue]
        let infectedPercentage: Double
        let movingAverage: MovingAverage
        let highlightedValue: DatedValue
        let moreInfoUrl: URL?
    }

    struct HospitalAdmissions: Codable {
        let sortingValue: Int
        let values: [DatedValue]
        let movingAverage: MovingAverage
        let highlightedValue: DatedValue
        let moreInfoUrl: URL?
    }

    struct IcuAdmissions: Codable {
        let sortingValue: Int
        let values: [DatedValue]
        let movingAverage: MovingAverage
        let highlightedValue: DatedValue
        let moreInfoUrl: URL?
    }

    struct VaccinationCoverage: Codable {
        let sortingValue: Int
        let vaccinationCoverage18Plus: Double
        let boosterCoverage18Plus: Double
        let highlightedValue: DatedValue?
        let moreInfoUrl: URL?
    }

    struct CoronaMelderUsers: Codable {
        let sortingValue: Int
        let values: [DatedValue]
        let highlightedValue: DatedValue
        let moreInfoUrl: URL?
    }

    let positiveTestResults: PositiveTestResults?
    let hospitalAdmissions: HospitalAdmissions?
    let icuAdmissions: IcuAdmissions?
    let vaccinationCoverage: VaccinationCoverage?
    let coronaMelderUsers: CoronaMelderUsers?
    let moreInfoUrl: URL?
}

// MARK: - Codable

extension DashboardData {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        positiveTestResults = try? container.decodeIfPresent(PositiveTestResults.self, forKey: .positiveTestResults)
        hospitalAdmissions = try? container.decodeIfPresent(HospitalAdmissions.self, forKey: .hospitalAdmissions)
        icuAdmissions = try? container.decodeIfPresent(IcuAdmissions.self, forKey: .icuAdmissions)
        vaccinationCoverage = try? container.decodeIfPresent(VaccinationCoverage.self, forKey: .vaccinationCoverage)
        coronaMelderUsers = try? container.decodeIfPresent(CoronaMelderUsers.self, forKey: .coronaMelderUsers)
        moreInfoUrl = try? container.decodeIfPresent(URL.self, forKey: .moreInfoUrl)

        let allMappedValues = [
            positiveTestResults as Any?,
            hospitalAdmissions as Any?,
            icuAdmissions as Any?,
            vaccinationCoverage as Any?,
            coronaMelderUsers as Any?
        ].compactMap { $0 }

        if allMappedValues.isEmpty {
            throw DecodingError.dataCorruptedError(forKey: .positiveTestResults, in: container, debugDescription: "Could not decode DashboardData")
        }
    }
}

extension DashboardData.PositiveTestResults {
    enum CodingKeys: String, CodingKey {
        case sortingValue
        case values
        case infectedPercentage
        case movingAverage = "infectedMovingAverage"
        case highlightedValue
        case moreInfoUrl
    }
}

extension DashboardData.HospitalAdmissions {
    enum CodingKeys: String, CodingKey {
        case sortingValue
        case values
        case movingAverage = "hospitalAdmissionMovingAverage"
        case highlightedValue
        case moreInfoUrl
    }
}

extension DashboardData.IcuAdmissions {
    enum CodingKeys: String, CodingKey {
        case sortingValue
        case values
        case movingAverage = "icuAdmissionMovingAverage"
        case highlightedValue
        case moreInfoUrl
    }
}

extension DashboardData.MovingAverage {
    enum CodingKeys: String, CodingKey {
        case timestampStart
        case timestampEnd
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        do {
            value = try container.decode(Int.self, forKey: .value)
        } catch {
            let doubleValue = try container.decode(Double.self, forKey: .value)
            value = Int(doubleValue)
        }

        let timestampStart = try container.decode(Int.self, forKey: .timestampStart)
        let timestampEnd = try container.decode(Int.self, forKey: .timestampEnd)

        start = Date(timeIntervalSince1970: TimeInterval(timestampStart))
        end = Date(timeIntervalSince1970: TimeInterval(timestampEnd))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(value, forKey: .value)

        let timestampStart = Int(start.timeIntervalSince1970)
        let timestampEnd = Int(end.timeIntervalSince1970)

        try container.encode(timestampStart, forKey: .timestampStart)
        try container.encode(timestampEnd, forKey: .timestampEnd)
    }
}

extension DashboardData.DatedValue {
    enum CodingKeys: String, CodingKey {
        case timestamp
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        do {
            value = try container.decode(Int.self, forKey: .value)
        } catch {
            let doubleValue = try container.decode(Double.self, forKey: .value)
            value = Int(doubleValue)
        }

        let timestamp = try container.decode(Int.self, forKey: .timestamp)

        date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(value, forKey: .value)

        let timestamp = Int(date.timeIntervalSince1970)
        try container.encode(timestamp, forKey: .timestamp)
    }
}
