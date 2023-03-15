import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var errorVM: ErrorViewModel

    @FocusState private var isFocused: Bool

    @State private var appInfo: AppInfo?
    @State private var isInfoPresented = false
    @State private var isSettingsPresented = false
    @State private var selection = "Workout"

    init() {
        customizeNavBar()
    }

    private func customizeNavBar() {
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue.withAlphaComponent(0.9),
            // When the font size is 30 or more, this causes the error
            // "[LayoutConstraints] Unable to simultaneously
            // satisfy constraints", but it still works.
            .font: UIFont.systemFont(ofSize: 24, weight: .bold)
        ]
        UINavigationBar.appearance().standardAppearance = navigationAppearance
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                Workout(isFocused: $isFocused)
                    .tabItem {
                        Label("Workout", systemImage: "figure.indoor.cycle")
                    }
                    .tag("Workout")
                Statistics()
                    .tabItem {
                        Label(
                            "Statistics",
                            systemImage: "chart.xyaxis.line"
                        )
                    }
                    .tag("Statistics")
                Settings(isFocused: $isFocused)
                    .tabItem {
                        Label(
                            "Settings",
                            systemImage: "gear"
                        )
                    }
                    .tag("Default Settings")
            }

            .navigationTitle(selection)
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { isInfoPresented = true }) {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityIdentifier("info-button")
                }
            }

            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button {
                        isFocused = false
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
        }

        .alert(
            "Error",
            isPresented: $errorVM.errorOccurred,
            actions: {}, // no custom buttons
            message: { errorVM.text }
        )

        .sheet(isPresented: $isInfoPresented) {
            Info(appInfo: appInfo)
                // .presentationDetents([.height(410)])
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium])
        }

        .task {
            await HealthStore().requestAuthorization()

            do {
                appInfo = try await AppInfo.create()
            } catch {
                Log.error("Failed to get AppInfo.")
                /*
                 errorVM.alert(
                     error: error,
                     message: "Failed to get AppInfo."
                 )
                 */
            }
        }

        .tint(.accentColor.opacity(0.9))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
