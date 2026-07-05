import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    @MainActor static let shared = AppSettings()
    
    @Published var enableFirst: Bool {
        didSet { save() }
    }
    @Published var enableRepeat: Bool {
        didSet { save() }
    }
    @Published var firstTime: Date {
        didSet { save() }
    }
    @Published var startTime: Date {
        didSet { save() }
    }
    @Published var endTime: Date {
        didSet { save() }
    }
    @Published var intervalMinutes: Int {
        didSet { save() }
    }

    private enum Keys {
        static let enableFirst = "enableFirst"
        static let enableRepeat = "enableRepeat"
        static let firstTime = "firstTime"
        static let startTime = "startTime"
        static let endTime = "endTime"
        static let intervalMinutes = "intervalMinutes"
    }

    private init() {
        let defaults = UserDefaults.standard
        enableFirst = defaults.bool(forKey: Keys.enableFirst)
        enableRepeat = defaults.bool(forKey: Keys.enableRepeat)

        if let first = defaults.object(forKey: Keys.firstTime) as? Date {
            firstTime = first
        } else {
            var dc = DateComponents()
            dc.hour = 23
            dc.minute = 0
            firstTime = Calendar.current.date(from: dc)!
        }

        if let start = defaults.object(forKey: Keys.startTime) as? Date {
            startTime = start
        } else {
            var dc = DateComponents()
            dc.hour = 23
            dc.minute = 30
            startTime = Calendar.current.date(from: dc)!
        }

        if let end = defaults.object(forKey: Keys.endTime) as? Date {
            endTime = end
        } else {
            var dc = DateComponents()
            dc.hour = 4
            dc.minute = 0
            endTime = Calendar.current.date(from: dc)!
        }

        intervalMinutes = defaults.integer(forKey: Keys.intervalMinutes)
        if intervalMinutes == 0 { intervalMinutes = 10 }
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(enableFirst, forKey: Keys.enableFirst)
        defaults.set(enableRepeat, forKey: Keys.enableRepeat)
        defaults.set(firstTime, forKey: Keys.firstTime)
        defaults.set(startTime, forKey: Keys.startTime)
        defaults.set(endTime, forKey: Keys.endTime)
        defaults.set(intervalMinutes, forKey: Keys.intervalMinutes)
    }
}
