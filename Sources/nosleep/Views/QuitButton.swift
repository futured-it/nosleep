import SwiftUI

struct QuitButton: View {
    var body: some View {
        Section {
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text("Quit completely")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text("This terminates the background agent. No notifications will be sent.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Button("Quit") {
                    NotificationCenter.default.post(name: .quitApp, object: nil)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.regular)
            }
        }
    }
}
