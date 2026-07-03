import SwiftUI

enum AppTheme {
    static let blueTop = Color(red: 0.329, green: 0.675, blue: 0.929)      // #54ACED
    static let blueBottom = Color(red: 0.231, green: 0.533, blue: 0.765)   // #3B88C3
    static let blueGradient = LinearGradient(
        colors: [blueTop, blueBottom],
        startPoint: .top,
        endPoint: .bottom
    )
    static let mintGreen = Color(red: 0.30, green: 1.0, blue: 0.85)
    static let cardBackground = Color.white
    static let secondaryText = Color(red: 0.55, green: 0.55, blue: 0.58)
}
