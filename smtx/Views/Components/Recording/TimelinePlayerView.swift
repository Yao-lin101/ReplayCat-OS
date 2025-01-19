import SwiftUI

struct TimelinePlayerView: View {
    @ObservedObject var playerController: TimelinePlayerController
    let isPreviewMode: Bool
    let isVideo: Bool
    let videoUrl: URL?
    
    @State private var videoVolume: Double = 0
    @State private var audioVolume: Double = 1.0
    
    @State private var isDragging = false
    @State private var dragTime: Double = 0
    @State private var draggedItem: TimelineDisplayData?
    
    private var progress: Double {
        guard playerController.duration > 0 else { return 0 }
        if isDragging {
            return dragTime / playerController.duration
        }
        return playerController.currentTime / playerController.duration
    }
    
    private var displayImage: UIImage? {
        if isDragging {
            if let imageData = draggedItem?.displayImage {
                return UIImage(data: imageData)
            }
        } else if let imageData = playerController.currentItem?.displayImage {
            return UIImage(data: imageData)
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 视频/图片区域
            if isVideo, let url = videoUrl {
                ZStack {
                    VideoPlayerView(
                        url: url,
                        currentTime: .constant(isDragging ? dragTime : playerController.currentTime),
                        aspectRatio: 16/9,
                        volume: videoVolume
                    )
                }
                .frame(height: 200)
            } else {
                ZStack {
                    if let image = displayImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.2))
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                            }
                    }
                }
                .frame(height: 200)
            }
            
            // 台词区域
            ZStack {
                if let script = (isDragging ? draggedItem?.script : playerController.currentItem?.script) {
                    Text(script)
                        .font(.body)
                        .multilineTextAlignment(.center)
                } else {
                    Text("无台词")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 60)
            .padding(.horizontal)

            // 底部控制区域
            VStack(spacing: 16) {  // 减小间距
                // 音量控制区域
                VStack(spacing: 8) {
                    // 录音音量控制
                    if isPreviewMode {
                        HStack(spacing: 12) {  // 添加固定间距
                            Image(systemName: audioVolume == 0 ? "mic.slash.fill" : "mic.fill")
                                .font(.system(size: 16))  // 统一图标大小
                                .frame(width: 20)  // 固定宽度
                                .foregroundColor(.secondary)
                            
                            Slider(
                                value: Binding(
                                    get: { audioVolume },
                                    set: { newValue in
                                        audioVolume = newValue
                                        playerController.setAudioVolume(newValue)
                                    }
                                ),
                                in: 0...1
                            )
                            
                            Image(systemName: "mic.fill")  // 使用相同的图标
                                .font(.system(size: 16))  // 统一图标大小
                                .frame(width: 20)  // 固定宽度
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    
                    // 视频音量控制
                    if isVideo {
                        HStack(spacing: 12) {  // 添加固定间距
                            Image(systemName: videoVolume == 0 ? "speaker.slash.fill" : "speaker.fill")
                                .font(.system(size: 16))  // 统一图标大小
                                .frame(width: 20)  // 固定宽度
                                .foregroundColor(.secondary)
                            
                            Slider(
                                value: Binding(
                                    get: { videoVolume },
                                    set: { newValue in
                                        videoVolume = newValue
                                        playerController.setVideoVolume(newValue)
                                    }
                                ),
                                in: 0...1
                            )
                            
                            Image(systemName: "speaker.fill")  // 使用相同的图标
                                .font(.system(size: 16))  // 统一图标大小
                                .frame(width: 20)  // 固定宽度
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 进度条和时间
                VStack(spacing: 4) {
                    // 时间显示
                    HStack {
                        Text(formatTime(isDragging ? dragTime : playerController.currentTime))
                        Spacer()
                        Text(formatTime(playerController.duration))
                    }
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
                    
                    // 进度条
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 背景条
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 4)
                            
                            // 进度条
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.accentColor)
                                .frame(width: max(0, min(geometry.size.width, geometry.size.width * progress)), height: 4)
                            
                            // 拖动手柄
                            if isPreviewMode {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 16, height: 16)
                                    .shadow(radius: 2)
                                    .position(x: max(8, min(geometry.size.width - 8, geometry.size.width * progress)), y: 2)
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                if !isDragging {
                                                    isDragging = true
                                                    playerController.pause()
                                                }
                                                let ratio = max(0, min(1, value.location.x / geometry.size.width))
                                                dragTime = ratio * playerController.duration
                                                // 更新拖动时的时间轴项目
                                                if let provider = playerController.currentItem?.provider {
                                                    draggedItem = provider.getItemAt(timestamp: dragTime)
                                                }
                                            }
                                            .onEnded { _ in
                                                isDragging = false
                                                draggedItem = nil
                                                playerController.seek(to: dragTime)
                                            }
                                    )
                            }
                        }
                    }
                    .frame(height: 4)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)  // 增加底部间距
        }
        .padding(.vertical)
        .onChange(of: playerController.currentItem) { _ in
            if isDragging {
                isDragging = false
                draggedItem = nil
            }
        }
        .onAppear {
            // 初始化音量设置
            playerController.setAudioVolume(audioVolume)
            if isVideo {
                playerController.setVideoVolume(videoVolume)
            }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
} 