import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Goals") {
                    LabeledContent("Daily step goal", value: "20,000")
                }

                Section("Health") {
                    LabeledContent("Data source", value: "Apple Health")
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
