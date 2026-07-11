import SwiftUI
import AppKit
import UserNotifications

extension Notification.Name {
    static let quitApp = Notification.Name("quitApp")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?
    private var shouldTerminate = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        let settingsView = NosleepSettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "nosleep"
        window.setContentSize(NSSize(width: 400, height: 500))
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]

        // Give it the modern, unified macOS title bar look
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
        
        window.delegate = self
        window.makeKeyAndOrderFront(nil)

        self.settingsWindow = window

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(quitApp),
            name: .quitApp,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        Scheduler.shared.reschedule()
    }

    @objc func systemWillSleep() {
        print("    System will sleep")
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        }
    }

    @objc func systemDidWake() {
        print("    System did wake")
        DispatchQueue.main.async {
            // Clear everything, then reschedule
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            Scheduler.shared.reschedule()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let window = settingsWindow {
            if !window.isVisible {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if shouldTerminate {
            return .terminateNow
        } else {
            NSApp.hide(nil)
            return .terminateCancel
        }
    }

    @MainActor
    @objc func quitApp() {
        shouldTerminate = true
        NSApp.terminate(nil)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}

@main
struct NosleepApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        SwiftUI.Settings {
            EmptyView()
        }
    }
}
