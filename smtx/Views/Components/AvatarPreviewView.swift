import SwiftUI

struct AvatarPreviewView: View {
    let imageURL: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let url = URL(string: imageURL) {
                CachedAsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .empty:
                        ProgressView()
                    case .failure:
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .gesture(
            TapGesture()
                .onEnded { _ in
                    dismiss()
                }
        )
    }
}

#Preview {
    AvatarPreviewView(imageURL: "https://example.com/avatar.jpg")
} 