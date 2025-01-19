import SwiftUI

struct InfoRow: View {
    let title: String
    let content: String
    var isEditable: Bool = false
    var showBindButton: Bool = false
    var onEdit: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundColor(.gray)
                .frame(width: 60, alignment: .leading)
            
            if isEditable {
                HStack {
                    Text(content)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.leading)
                        .lineLimit(title == "简介" ? 4 : 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                            onEdit?()
                        }
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            onEdit?()
                        }
                }
            } else {
                HStack {
                    Text(content)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.leading)
                        .lineLimit(title == "简介" ? 4 : 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if showBindButton {
                        Button("绑定") {
                            // TODO: 实现绑定功能
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    VStack {
        InfoRow(title: "昵称", content: "测试用户", isEditable: true)
        InfoRow(title: "简介", content: "这是一段很长的简介内容，可能会超过一行显示", isEditable: true)
        InfoRow(title: "邮箱", content: "test@example.com", showBindButton: true)
    }
} 