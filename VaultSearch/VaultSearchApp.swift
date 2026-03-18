import SwiftUI
import Sparkle

enum AppTab: String, CaseIterable {
    case search = "Search"
    case faces = "Faces"
    case status = "Status"

    var icon: String {
        switch self {
        case .search: return "magnifyingglass"
        case .faces: return "person.crop.rectangle.stack"
        case .status: return "server.rack"
        }
    }
}

@main
struct VaultSearchApp: App {
    @State private var selectedTab: AppTab = .search
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 0) {
                // Tab bar
                HStack(spacing: 0) {
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        Button {
                            selectedTab = tab
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 12))
                                Text(tab.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(selectedTab == tab ? .white : .secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(selectedTab == tab ? Color.accentColor.opacity(0.8) : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(nsColor: .windowBackgroundColor))

                Divider()

                // Content
                switch selectedTab {
                case .search:
                    SearchView()
                case .faces:
                    FacesView()
                case .status:
                    StatusView()
                }
            }
            .frame(minWidth: 800, minHeight: 550)
            .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1100, height: 750)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updaterController.updater.checkForUpdates()
                }
            }
        }
    }
}
