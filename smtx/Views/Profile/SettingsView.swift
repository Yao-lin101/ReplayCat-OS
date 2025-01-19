import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var router: NavigationRouter
    
    var body: some View {
        List {
            Section("通用设置") {
                MenuRow(
                    icon: "trash",
                    title: "缓存清理",
                    action: { router.navigate(to: .cacheCleaning) }
                )
            }
        }
        .navigationTitle("设置")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
} 
