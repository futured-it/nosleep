import SwiftUI
import UserNotifications

struct SettingsSection: View {
    @ObservedObject var settings: AppSettings
    let permissionStatus: UNAuthorizationStatus

    var body: some View {
        // MARK: - First notification
        Section {
            Toggle(isOn: Binding(
                get: { settings.enableFirst },
                set: { newValue in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        settings.enableFirst = newValue
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("First notification")
                        .font(.body)
                    Text("Supposed to notify you at a specific time, so you can start preparing for sleep.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .disabled(permissionStatus != .authorized)
            
            if settings.enableFirst {
                HStack {
                    Text("Notify first at")
                    Spacer()
                    DatePicker("", selection: $settings.firstTime, displayedComponents: [.hourAndMinute])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .disabled(!settings.enableFirst || permissionStatus != .authorized)
                }
            }
        }

        // MARK: - Repeating notifications
        Section {
            VStack(spacing: 0) {
                Toggle(isOn: Binding(
                    get: { settings.enableRepeat },
                    set: { newValue in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            settings.enableRepeat = newValue
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Repeating notifications")
                            .font(.body)
                        Text("Send recurring alerts throughout a specific window to keep you on track.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .disabled(permissionStatus != .authorized)
                
                if settings.enableRepeat {
                    Divider()
                        .padding(.vertical, 8)
                    
                    HStack {
                        Text("Notify between")
                            .font(.body)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            DatePicker("", selection: $settings.startTime, displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                                .datePickerStyle(.compact)
                            
                            Text("and")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .fixedSize()
                            
                            DatePicker("", selection: $settings.endTime, displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                                .datePickerStyle(.compact)
                        }
                        .disabled(!settings.enableRepeat || permissionStatus != .authorized)
                    }
                    Divider()
                        .padding(.vertical, 8)
                    
                    HStack {
                        Text("Repeat every")
                            .font(.body)
                        
                        Spacer()
                        
                        Picker("", selection: $settings.intervalMinutes) {
                            Text("3 min").tag(3)
                            Text("5 min").tag(5)
                            Text("10 min").tag(10)
                            Text("15 min").tag(15)
                            Text("30 min").tag(30)
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .disabled(!settings.enableRepeat || permissionStatus != .authorized)
                    }
                }
            }
        }
    }
}
