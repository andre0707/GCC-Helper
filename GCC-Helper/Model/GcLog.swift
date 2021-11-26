//
//  GcLog.swift
//  GCC-Helper
//
//  Created by Andre Albach on 25.11.21.
//

import Foundation

/// A simple structure for a log on a geocaching.com website which the javascript part returns
struct GcLog: Codable {
    /// The geocaching nickname of the log writer
    let name: String
    /// The unique profile name id. Can be used to open this user in the message center
    let nameId: String
    /// The raw value of `GcLogType`
    let logType: Int
    /// The link to the log
    let logLink: String
    
    /// Indicator, if this cacher fulfils the challenge. Not set in the beginning.
    /// When this log was checked with a challenge checker it will be filled
    var fulfilsChallenge: Bool? = nil
    
    /// The url to the message center for the user who wrote this log
    var messageUserUrl: String { "https://www.geocaching.com/account/messagecenter?recipientId=\(nameId)" }
}


/// Conformance to `CustomStringConvertible`
extension GcLog: CustomStringConvertible {
    var description: String {
        """
        Name: \(name)
        Id: \(nameId)
        Type: \(LogType(rawValue: logType)?.description ?? "Other")
        Link: \(logLink)\n
        """
    }
}

/// Conformance to `Identifiable`
extension GcLog: Identifiable {
    var id: String { nameId }
}


extension GcLog {
    
    /// Some relevant log types.
    /// We are mainly just interested in `found` logs.
    enum LogType: Int, CustomStringConvertible {
        
        case found = 2
        case didNotFind = 3
        
        //case archive = 5
        //case archive2 = 6
        //case shouldBeArchived = 7
        
        var description: String {
            switch self {
                case .found:
                    return "Fount it"
                case .didNotFind:
                    return "Did not find"
            }
        }
    }
}
