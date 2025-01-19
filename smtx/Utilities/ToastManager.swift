import SwiftUI

@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var isPresented = false
    @Published var message = ""
    @Published var type: ToastView.ToastType = .success
    
    private init() {}
    
    func show(_ message: String, type: ToastView.ToastType = .success) {
        self.message = message
        self.type = type
        withAnimation(.spring()) {
            isPresented = true
        }
        // 2秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.spring()) {
                self.isPresented = false
            }
        }
    }
}

// 创建一个视图修饰符来添加 Toast 功能
struct ToastManagerModifier: ViewModifier {
    @StateObject private var toastManager = ToastManager.shared
    
    func body(content: Content) -> some View {
        content
            .toast(isPresented: $toastManager.isPresented,
                  message: toastManager.message,
                  type: toastManager.type)
    }
}

// 扩展 View 以添加便捷方法
extension View {
    func toastManager() -> some View {
        modifier(ToastManagerModifier())
    }
} 