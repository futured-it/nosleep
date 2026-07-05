import SwiftUI
import UserNotifications

struct NosleepSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        Form {
            StatusSection(permissionStatus: $permissionStatus)
            SettingsSection(settings: settings, permissionStatus: permissionStatus)
            QuitButton()
        }
        .formStyle(.grouped)
        .frame(minWidth: 350, idealWidth: 400)
        .task {
            NSApplication.shared.activate(ignoringOtherApps: true)
            await checkPermission()
        }
        .onChange(of: settings.enableFirst) { _, _ in Scheduler.shared.reschedule() }
        .onChange(of: settings.enableRepeat) { _, _ in Scheduler.shared.reschedule() }
        .onChange(of: settings.firstTime) { _, _ in Scheduler.shared.reschedule() }
        .onChange(of: settings.startTime) { _, _ in Scheduler.shared.reschedule() }
        .onChange(of: settings.endTime) { _, _ in Scheduler.shared.reschedule() }
        .onChange(of: settings.intervalMinutes) { _, _ in Scheduler.shared.reschedule() }
    }

    @MainActor
    private func checkPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permissionStatus = settings.authorizationStatus
        if permissionStatus == .authorized {
            Scheduler.shared.reschedule()
        } else if permissionStatus == .notDetermined {
            await requestPermission()
        }
    }

    @MainActor
    private func requestPermission() async {
        NSApplication.shared.activate(ignoringOtherApps: true)
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            permissionStatus = granted ? .authorized : .denied
            if granted { Scheduler.shared.reschedule() }
        } catch {
            permissionStatus = .denied
        }
    }
}
