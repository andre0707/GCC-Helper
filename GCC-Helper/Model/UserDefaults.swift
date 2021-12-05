//
//  UserDefaults.swift
//  GCC-Helper
//
//  Created by Andre Albach on 05.12.21.
//

import Foundation

extension UserDefaults {
    /// The time the scripts wait for the checker to execute.
    /// Time is in seconds
    var checkerWaitingTime: Double {
        get { (self.object(forKey: "checkerWaitingTime") as? Double) ?? 5.0 }
        set { self.set(newValue, forKey: "checkerWaitingTime") }
    }
}
