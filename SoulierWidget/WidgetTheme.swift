import SwiftUI
import UIKit

enum WidgetTheme {
    static let background = Color.adaptive(light: 0xFFFFFF, dark: 0x000000)
    static let steps = Color.adaptive(light: 0x000000, dark: 0xF5F6F5)
    static let stepsWalked = Color(hex: 0x575757)
    static let distance = Color(hex: 0x2FC472)
    static let calories = Color(hex: 0xF3BB23)
    static let floors = Color(hex: 0xF16315)
}

private extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }

    static func adaptive(light lightHex: UInt32, dark darkHex: UInt32) -> Color {
        Color(UIColor { traitCollection in
            UIColor(hex: traitCollection.userInterfaceStyle == .dark ? darkHex : lightHex)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}

enum WidgetFormatters {
    private static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        return formatter
    }()

    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let compactStepsFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    static func integer(_ value: Int) -> String {
        integerFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func steps(_ value: Int) -> String {
        guard value >= 10_000 else {
            return integer(value)
        }

        let thousands = floor(Double(value) / 100.0) / 10.0

        if thousands.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(thousands))K"
        }

        let formatted = compactStepsFormatter.string(from: NSNumber(value: thousands))
            ?? String(format: "%.1f", thousands).replacingOccurrences(of: ".", with: ",")
        return "\(formatted)K"
    }

    static func decimal(_ value: Double) -> String {
        decimalFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}
