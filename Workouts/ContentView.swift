import SwiftUI

struct ContentView: View {
    @State private var appInfo: AppInfo?
    @State private var isInfoPresented = false
    @State private var isSettingsPresented = false
    @StateObject private var viewModel = HealthKitViewModel()

    init() {
        customizeNavBar()
    }

    private func customizeNavBar() {
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            // When the font size is 30 or more, this causes the error
            // "[LayoutConstraints] Unable to simultaneously
            // satisfy constraints", but it still works.
            .font: UIFont.systemFont(ofSize: 24, weight: .bold)
        ]
        UINavigationBar.appearance().standardAppearance = navigationAppearance
    }

    var body: some View {
        NavigationStack {
            TabView {
                Workout()
                    .tabItem {
                        Label("Workout", systemImage: "figure.indoor.cycle")
                    }
                Statistics()
                    .tabItem {
                        Label(
                            "Statistics",
                            systemImage: "chart.xyaxis.line"
                        )
                    }
                Settings()
                    .tabItem {
                        Label(
                            "Settings",
                            systemImage: "gear"
                        )
                    }
            }
            .navigationTitle("Workout ME")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { isInfoPresented = true }) {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityIdentifier("info-button")
                }
            }
        }
        .sheet(isPresented: $isInfoPresented) {
            Info(appInfo: appInfo)
                // .presentationDetents([.height(410)])
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $isSettingsPresented) {
            Settings()
                // Need at least this height for iPhone SE.
                // .presentationDetents([.height(470)])
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium])
        }
        .task {
            do {
                appInfo = try await AppInfo.create()
            } catch {
                Log.error("error getting AppInfo: \(error)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
