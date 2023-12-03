//
//  Extentions.swift
//  EzMoneyTracker
//
//  Created by Hai Hw on 4/12/23.
//

import Foundation
extension Array where Element: Numeric {
    func sum() -> Element {
        return reduce(0, +)
    }
}
extension Date {
    var beginingOfDay: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        let beginningOfDay = calendar.date(from: components)!
        return beginningOfDay
    }
    var beginingOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        let beginningOfDay = calendar.date(from: components)!
        return beginningOfDay
    }

    var beginingOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        let beginningOfDay = calendar.date(from: components)!
        return beginningOfDay
    }

    var beginingOfYear: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        let beginningOfDay = calendar.date(from: components)!
        return beginningOfDay
    }

}
extension Float {
    var toString: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: self as NSNumber) ?? ""
    }
}
extension String {
    var toNumericValue: Float? {
        let numericPart = self.dropLast().trimmingCharacters(in: .whitespaces)
        let unit = self.last?.lowercased() ?? ""
        let multiplier: Float
        switch unit {
        case "k":
            multiplier = 1_000
        case "m":
            multiplier = 1_000_000
        case "b":
            multiplier = 1_000_000_000
        default:
            multiplier = 1
        }

        if let numericValue = Float(numericPart) {
            return numericValue * multiplier
        } else {
            return nil
        }
    }

}
