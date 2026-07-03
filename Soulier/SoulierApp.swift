import SwiftUI

@main
struct SoulierApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

extension View {
    func lightStatusBar() -> some View {
        background(
            StatusBarStyleModifier(style: .lightContent)
                .frame(width: 0, height: 0)
        )
    }
}

private struct StatusBarStyleModifier: UIViewControllerRepresentable {
    let style: UIStatusBarStyle

    func makeUIViewController(context: Context) -> StatusBarViewController {
        StatusBarViewController(style: style)
    }

    func updateUIViewController(_ uiViewController: StatusBarViewController, context: Context) {
        uiViewController.statusBarStyle = style
        uiViewController.setNeedsStatusBarAppearanceUpdate()
    }
}

private final class StatusBarViewController: UIViewController {
    var statusBarStyle: UIStatusBarStyle

    init(style: UIStatusBarStyle) {
        statusBarStyle = style
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        statusBarStyle
    }
}
