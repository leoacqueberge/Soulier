import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = StepsViewModel()

    var body: some View {
        StepsView(viewModel: viewModel)
            .preferredColorScheme(.dark)
            .task {
                await viewModel.load()
                viewModel.startLiveUpdates()
                await viewModel.startLiveStepTracking()
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    Task {
                        viewModel.startLiveUpdates()
                        await viewModel.startLiveStepTracking()
                    }
                case .background:
                    viewModel.stopLiveStepTracking()
                default:
                    break
                }
            }
    }
}

#Preview {
    ContentView()
}
