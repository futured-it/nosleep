import SwiftUI
import UserNotifications

struct StatusSection: View {
    @Binding var permissionStatus: UNAuthorizationStatus

    var body: some View {
        Section {
            HStack(alignment: .center, spacing: 10) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications Permission")
                        .font(.body)
                    Text(statusDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if permissionStatus == .denied {
                    Button("Open System Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                } else if permissionStatus == .notDetermined {
                    Button("Request Permission") {
                        Task { await requestPermission() }
                    }
                } else if permissionStatus == .authorized {
                    Button("Test") {
                        NotificationManager.shared.scheduleTestNotification(after: 1)
                    }
                }
            }
        }
    }

    private var statusColor: Color {
        switch permissionStatus {
        case .authorized: return .green
        case .denied: return .red
        case .notDetermined: return .yellow
        default: return .gray
        }
    }

    private var statusDescription: String {
        switch permissionStatus {
        case .authorized: return "Granted"
        case .denied: return "Denied - enable in System Settings"
        case .notDetermined: return "Not requested yet"
        default: return "Unknown"
        }
    }

    @MainActor
    private func requestPermission() async {
        NSApplication.shared.activate(ignoringOtherApps: true)
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            permissionStatus = granted ? .authorized : .denied
        } catch {
            permissionStatus = .denied
        }
    }
}
