import SwiftUI

struct MetricsRow: View {
    let distanceKm: Double
    let floors: Int
    let activeMinutes: Int

    var body: some View {
        HStack(spacing: 0) {
            metric(title: "DISTANCE", value: Formatters.distanceKm(distanceKm))
            metric(title: "CLIMBED", value: "\(floors) flights")
            metric(title: "ACTIVE", value: "\(activeMinutes) m")
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(spacing: 7) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .tracking(0.5)

            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MetricsRow(distanceKm: 2.93, floors: 9, activeMinutes: 39)
        .padding()
        .background(AppTheme.background)
}
