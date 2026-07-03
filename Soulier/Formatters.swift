import Foundation

enum Formatters {
    static let englishNumber: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
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
}
