import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "text.book.closed.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("SMTX")
                        .font(.title2)
                        .bold()
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            
            Section("开发者") {
                Text("暂未开放")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("关于")
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
} 