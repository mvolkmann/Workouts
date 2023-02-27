import SwiftUI

struct Info: View {
    @Environment(\.dismiss) private var dismiss

    private let appInfo: AppInfo?

    init(appInfo: AppInfo?) {
        self.appInfo = appInfo
    }

    private var appIcon: UIImage? {
        guard let infoDict = Bundle.main.infoDictionary,
              let icons = infoDict["CFBundleIcons"] as? [String: Any],
              let primaryIcons = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcons["CFBundleIconFiles"] as? [String],
              let icon = iconFiles.first else { return nil }
        return UIImage(named: icon)
    }

    var body: some View {
        VStack(spacing: 20) {
            if let appInfo {
                let title = appInfo.name.localized + " " +
                    appInfo.installedVersion
                Text(title)
                    .accessibilityIdentifier("info-title")
                    .font(.headline)
                    .onTapGesture { dismiss() }
                // Image("AppIcon") // doesn't work
                if let appIcon {
                    let size: CGFloat = 100
                    Image(uiImage: appIcon)
                        .resizable()
                        .frame(width: size, height: size)
                }
                Text("Created by".localized + " R. Mark Volkmann")
            } else {
                Text("Failed to access AppInfo.")
            }

            /*
             Text("why-created")
                 .lineLimit(5)

             Link(
                 "GitHub Repository",
                 destination: URL(
                     string: "https://github.com/mvolkmann/WeatherKitDemo"
                 )!
             */
        }
        .padding()
    }
}
