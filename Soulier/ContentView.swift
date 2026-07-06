import SwiftUI

struct ContentView: View {
    @State private var viewModel = StepsViewModel()

    var body: some View {
        StepsView(viewModel: viewModel)
            .preferredColorScheme(.dark)
            .task {
                await viewModel.load()
            }
    }
}

#Preview {
    ContentView()
}
