import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var router: NavigationRouter
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 功能列表
                VStack(spacing: 0) {
                    MenuRow(
                        icon: "gear", 
                        title: "设置",
                        action: { router.navigate(to: .settings) }
                    )
                    Divider()
                    MenuRow(
                        icon: "questionmark.circle", 
                        title: "帮助与反馈",
                        action: { router.navigate(to: .help) }
                    )
                    Divider()
                    MenuRow(
                        icon: "info.circle", 
                        title: "关于",
                        action: { router.navigate(to: .about) }
                    )
                    Divider()
                }
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
    }
}
// 菜单行视图
struct MenuRow: View {
    let icon: String
    let title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.footnote)
            }
            .padding(.horizontal, 20)
            .frame(height: 44)
        }
    }
}
