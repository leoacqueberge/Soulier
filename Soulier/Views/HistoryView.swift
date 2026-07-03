import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No History Yet",
                systemImage: "clock",
                description: Text("Your step history will appear here.")
            )
            .navigationTitle("History")
        }
    }
}

#Preview {
    HistoryView()
}
