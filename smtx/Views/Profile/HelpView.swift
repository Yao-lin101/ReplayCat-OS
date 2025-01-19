import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            Section("常见问题") {
                Text("暂未开放")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("帮助与反馈")
    }
}

#Preview {
    NavigationStack {
        HelpView()
    }
} 