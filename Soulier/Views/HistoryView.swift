import SwiftUI

struct HistoryView: View {
    @Bindable var viewModel: StepsViewModel

    var body: some View {
        ZStack {
            AppTheme.blueGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 8)
                        .padding(.bottom, 28)

                    ForEach(Array(viewModel.trend.metrics.enumerated()), id: \.element.id) { index, metric in
                        TrendMetricRow(metric: metric)

                        if index < viewModel.trend.metrics.count - 1 {
                            DashedDivider()
                                .padding(.vertical, 22)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 110)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.light)
        .lightStatusBar()
        .task {
            await viewModel.loadTrend()
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.trendPeriod)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 7) {
            Text("Trend")
                .font(.system(size: 28, weight: .regular, design: .monospaced))
                .foregroundStyle(.white)

            Menu {
                ForEach(TrendPeriod.allCases) { period in
                    Button(period.title) {
                        Task {
                            await viewModel.setTrendPeriod(period)
                        }
                    }
                }
            } label: {
                HStack(alignment: .center, spacing: 5) {
                    Text(viewModel.trendPeriod.title)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TrendMetricRow: View {
    let metric: TrendMetric

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.totalValue)
                    .font(.system(size: 46, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .padding(.bottom, -4)

                HStack(spacing: 6) {
                    Image(systemName: metric.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(metric.label)
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }

            Spacer(minLength: 16)

            VStack(alignment: .trailing, spacing: 4) {
                Text(metric.averageValue)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)

                Text("Average")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
    }
}

#Preview {
    HistoryView(viewModel: StepsViewModel())
}
