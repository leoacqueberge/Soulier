import Foundation

enum Formatters {
    static let englishNumber: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    static let frenchNumber: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    static let frenchDecimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static let englishDecimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func steps(_ value: Int) -> String {
        englishNumber.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func compactSteps(_ value: Int) -> String {
        guard value >= 1_000 else {
            return frenchNumber.string(from: NSNumber(value: value)) ?? "\(value)"
        }

        let thousands = Double(value) / 1_000
        if thousands.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(thousands))k"
        }

        return "\(trendDecimal(thousands, fractionDigits: 1))k"
    }

    static func distanceKm(_ value: Double) -> String {
        let number = frenchDecimal.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "\(number) km"
    }

    static func trendDecimal(_ value: Double, fractionDigits: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(fractionDigits)f", value)
    }

    static func trendInteger(_ value: Int) -> String {
        trendDecimal(Double(value), fractionDigits: 0)
    }

    static func dateRange(from start: Date, to end: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM"
        let startText = formatter.string(from: start)
        formatter.dateFormat = "d MMM"
        let endText = formatter.string(from: end)
        return "\(startText) – \(endText)"
    }

    static func todayTitle(_ date: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d MMMM"
        return "Today \(formatter.string(from: date))"
    }
}
