import SwiftUI

struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (AsyncImagePhase) -> Content
    @State private var phase: AsyncImagePhase = .empty
    
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
    }
    
    var body: some View {
        content(phase)
            .task(id: url) {
                guard let url = url else { return }
                do {
                    let image = try await ImageCacheManager.shared.loadImage(from: url)
                    withAnimation(transaction.animation) {
                        phase = .success(Image(uiImage: image))
                    }
                } catch {
                    phase = .failure(error)
                }
            }
    }
} 