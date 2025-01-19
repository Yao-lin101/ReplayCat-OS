import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let url: URL
    @Binding var currentTime: Double
    let aspectRatio: CGFloat
    var volume: Double = 1.0
    
    @StateObject private var controller = VideoPlayerController()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let player = controller.player {
                    VideoPlayer(player: player)
                        .disabled(true)  // 禁用播放器交互
                } else {
                    // 加载状态或错误状态
                    Rectangle()
                        .fill(Color.black.opacity(0.1))
                        .overlay {
                            if controller.isLoading {
                                VStack {
                                    ProgressView()
                                    Text("加载中...")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                        .padding(.top, 8)
                                }
                            } else if let error = controller.error {
                                VStack {
                                    Image(systemName: "video.slash")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text(error)
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                        .padding(.top, 8)
                                }
                            } else {
                                Image(systemName: "video.slash")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                            }
                        }
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.width / aspectRatio
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .onAppear {
            print("📱 VideoPlayerView.onAppear - Setting up player for URL: \(url)")
            controller.setupPlayer(with: url, volume: volume)
        }
        .onChange(of: currentTime) { newTime in
            controller.seek(to: newTime)
        }
        .onChange(of: volume) { newVolume in
            controller.setVolume(newVolume)
        }
        .onDisappear {
            controller.cleanup()
        }
    }
}

class VideoPlayerController: NSObject, ObservableObject {
    @Published var player: AVPlayer?
    @Published var isLoading = true
    @Published var error: String?
    
    private var playerItemObservations: Set<NSKeyValueObservation> = []
    private var timeObserver: Any?
    
    private var volume: Double = 1.0
    private(set) var currentURL: URL?
    
    var onReadyCallback: (() -> Void)?
    
    func setupPlayer(with url: URL, volume: Double, onReady: (() -> Void)? = nil) {
        cleanup() // 确保清理旧的观察者
        
        isLoading = true
        error = nil
        currentURL = url
        onReadyCallback = onReady
        
        let playerItem: AVPlayerItem
        
        if url.isFileURL {
            // 本地文件直接创建
            playerItem = AVPlayerItem(url: url)
        } else {
            // 网络视频需要特殊处理
            let asset = AVURLAsset(url: url, options: [
                "AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": "Mozilla/5.0"],
                "AVURLAssetOutOfBandMIMETypeKey": "video/mp4"
            ])
            playerItem = AVPlayerItem(asset: asset)
        }
        
        let player = AVPlayer(playerItem: playerItem)
        
        // 设置音频
        self.volume = volume
        player.volume = Float(volume)
        player.isMuted = false
        
        // 观察加载状态
        let statusObservation = playerItem.observe(\.status) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.handlePlayerItemStatus(item)
            }
        }
        playerItemObservations.insert(statusObservation)
        
        // 观察缓冲状态
        let bufferEmptyObservation = playerItem.observe(\.isPlaybackBufferEmpty) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.isLoading = item.isPlaybackBufferEmpty
            }
        }
        playerItemObservations.insert(bufferEmptyObservation)
        
        let bufferFullObservation = playerItem.observe(\.isPlaybackBufferFull) { [weak self] item, _ in
            DispatchQueue.main.async {
                if item.isPlaybackBufferFull {
                    self?.isLoading = false
                }
            }
        }
        playerItemObservations.insert(bufferFullObservation)
        
        let likelyToKeepUpObservation = playerItem.observe(\.isPlaybackLikelyToKeepUp) { [weak self] item, _ in
            DispatchQueue.main.async {
                if item.isPlaybackLikelyToKeepUp {
                    self?.isLoading = false
                }
            }
        }
        playerItemObservations.insert(likelyToKeepUpObservation)
        
        // 设置时间观察者
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] _ in
            // 时间同步逻辑
        }
        
        self.player = player
        
        // 加载完成后暂停在第一帧
        player.pause()
        player.seek(to: .zero)
    }
    
    private func handlePlayerItemStatus(_ playerItem: AVPlayerItem) {
        switch playerItem.status {
        case .readyToPlay:
            isLoading = false
            onReadyCallback?()
        case .failed:
            isLoading = false
            error = playerItem.error?.localizedDescription ?? "加载失败"
        default:
            break
        }
    }
    
    func cleanup() {
        // 清理所有观察者
        playerItemObservations.forEach { $0.invalidate() }
        playerItemObservations.removeAll()
        
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        
        currentURL = nil
        player = nil
        isLoading = true
        error = nil
    }
    
    deinit {
        cleanup()
    }
    
    func seek(to seconds: Double) {
        guard let player = player else { return }
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func setVolume(_ volume: Double) {
        self.volume = volume
        player?.volume = Float(volume)
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause() 
    }
    
    func stop() {
        player?.pause()
        seek(to: 0)
    }
}

// 添加 URL 扩展来判断是否为本地文件
extension URL {
    var isFileURL: Bool {
        scheme == "file"
    }
} 