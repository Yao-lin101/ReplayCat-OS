import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType
    
    enum ToastType {
        case success
        case error
        
        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "exclamationmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success:
                return .green
            case .error:
                return .red
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.system(size: 16))
            Text(message)
                .foregroundColor(.primary)
                .font(.system(size: 14))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// 创建一个视图修饰符来添加 Toast 功能
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let type: ToastView.ToastType
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isPresented {
                    ToastView(message: message, type: type)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
            }
    }
}

// 扩展 View 以添加便捷方法
extension View {
    func toast(isPresented: Binding<Bool>, message: String, type: ToastView.ToastType = .success) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, type: type))
    }
}

#Preview {
    VStack {
        ToastView(message: "这是一个成功提示", type: .success)
        ToastView(message: "这是一个错误提示", type: .error)
    }
} 