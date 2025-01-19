import AVFoundation
import SwiftUI

class TimelinePlayerController: ObservableObject {
    @Published var currentTime: Double = 0
    @Published var isPlaying: Bool = false
    @Published var duration: Double = 0
    @Published var isLoading: Bool = false
    @Published var isVideoReady: Bool = false
    @Published var isAudioReady: Bool = false
    @Published var currentItem: TimelineDisplayData?
    @Published var recordedDuration: Double = 0
    @Published var playStateVersion: Int = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var videoController: VideoPlayerController?
    private var timer: Timer?
    private var timelineProvider: TimelineProvider?
    private var isSettingUpVideo = false  // 添加标志位防止重复设置
    
    // 添加播放状态计算属性
    var isAudioPlaying: Bool {
        audioPlayer?.isPlaying == true
    }
    
    // 修改音频播放器设置方法
    func setupAudioPlayer(with url: URL) throws {
        // 配置音频会话
        try AudioSessionManager.shared.configurePlaybackSession()
        
        let player = try AVAudioPlayer(contentsOf: url)
        player.prepareToPlay()
        self.audioPlayer = player
        DispatchQueue.main.async {
            self.duration = player.duration
            self.recordedDuration = player.duration
            self.isAudioReady = true
        }
    }
    
    // 添加播放器清理方法
    func cleanup() {
        stopPlaybackTimer()
        audioPlayer?.stop()
        audioPlayer = nil
        videoController = nil
        isSettingUpVideo = false  // 清理时重置标志位
        deactivateSession()
        
        DispatchQueue.main.async {
            self.currentTime = 0
            self.duration = 0
            self.recordedDuration = 0
            self.isPlaying = false
            self.isAudioReady = false
            self.isVideoReady = false
            self.currentItem = nil
        }
    }
    
    // 设置时间轴提供者
    func setupTimelineProvider(_ provider: TimelineProvider) {
        self.timelineProvider = provider
        updateTimelineContent()
    }
    
    // 更新时间轴内容
    private func updateTimelineContent() {
        if let provider = timelineProvider {
            self.currentItem = provider.getItemAt(timestamp: self.currentTime)
        }
    }
    
    // 设置视频播放器
    func setupVideo(with url: URL, volume: Double) {
        // 防止重复设置
        guard !isSettingUpVideo else {
            print("🎥 Setup already in progress, skipping...")
            return
        }
        
        // 如果已经设置了相同的视频，就不重复设置
        if let currentVideo = videoController?.currentURL, currentVideo == url {
            print("🎥 Skip setup - Already playing same URL: \(url)")
            return
        }
        
        isSettingUpVideo = true
        print("🎥 Starting video setup for URL: \(url)")
        
        videoController = VideoPlayerController()
        videoController?.setupPlayer(with: url, volume: volume) { [weak self] in
            DispatchQueue.main.async {
                self?.isVideoReady = true
                self?.isSettingUpVideo = false  // 设置完成后重置标志位
                if self?.isPlaying == true {
                    print("▶️ Auto-playing video after setup")
                    self?.videoController?.play()
                }
            }
        }
    }
    
    // 检查是否准备就绪
    var isReadyToPlay: Bool {
        isAudioReady && (videoController == nil || isVideoReady)
    }
    
    // 播放控制
    func play() {
        print("▶️ Attempting to play")
        
        // 如果视频还没准备好，设置标志等待视频准备完成后自动播放
        if videoController != nil && !isVideoReady {
            print("⏳ Video not ready, will play when ready")
            isPlaying = true
            return
        }
        
        guard isReadyToPlay else { 
            print("⚠️ Player not ready to play")
            return 
        }
        
        do {
            try configurePlaybackSession()
            
            videoController?.play()
            audioPlayer?.play()
            startPlaybackTimer()
            
            DispatchQueue.main.async {
                self.isPlaying = true
                self.playStateVersion += 1
            }
        } catch {
            print("❌ Failed to configure audio session for playback: \(error)")
        }
    }
    
    func pause() {
        // 先暂停视频
        videoController?.pause()
        // 然后暂停音频
        audioPlayer?.pause()
        
        stopPlaybackTimer()
        DispatchQueue.main.async {
            self.isPlaying = false
            self.playStateVersion += 1
        }
    }
    
    func stop() {
        // 先停止视频播放器
        videoController?.stop()
        
        // 然后停止音频播放器
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        
        stopPlaybackTimer()
        currentTime = 0
        
        DispatchQueue.main.async {
            self.isPlaying = false
            self.playStateVersion += 1
        }
        
        deactivateSession()
    }
    
    func seek(to time: Double) {
        let targetTime = max(0, min(time, duration))
        if let videoController = videoController {
            videoController.seek(to: targetTime)
        }
        audioPlayer?.currentTime = targetTime
        self.currentTime = targetTime
        updateTimelineContent()
    }
    
    private func startPlaybackTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let player = self.audioPlayer {
                let currentTime = player.currentTime
                let duration = self.duration
                
                DispatchQueue.main.async {
                    self.currentTime = currentTime
                    self.updateTimelineContent()
                    
                    // 修改检测逻辑，增加容差值
                    if currentTime >= (duration - 0.1) {
                        self.stop()
                    }
                }
            }
        }
    }
    
    private func stopPlaybackTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func setVolume(_ volume: Double) {
        videoController?.setVolume(volume)
    }
    
    // 重置状态
    func resetState() {
        DispatchQueue.main.async {
            self.currentTime = 0
            self.duration = 0
            self.recordedDuration = 0
            self.isPlaying = false
            self.isAudioReady = false
            self.isVideoReady = false
            self.currentItem = nil
        }
        stopPlaybackTimer()
    }
    
    // 设置总时长
    func setDuration(_ duration: Double) {
        DispatchQueue.main.async {
            self.duration = duration
        }
    }
    
    // 更新当前时间
    func updateCurrentTime(_ time: Double) {
        DispatchQueue.main.async {
            self.currentTime = time
            self.updateTimelineContent()
        }
    }
    
    // 添加音频会话管理方法
    func configurePlaybackSession() throws {
        try AudioSessionManager.shared.configurePlaybackSession()
    }
    
    func configureRecordingSession(allowMixing: Bool = false) throws {
        try AudioSessionManager.shared.configureRecordingSession()
    }
    
    func deactivateSession() {
        AudioSessionManager.shared.deactivateSession()
    }
    
    // 设置录音时长
    func setRecordedDuration(_ duration: Double) {
        DispatchQueue.main.async {
            self.recordedDuration = duration
        }
    }
    
    // 添加音频会话配置方法
    func configureAudioSession(for mode: AudioSessionMode) throws {
        switch mode {
            case .playback:
                try AudioSessionManager.shared.configurePlaybackSession()
            case .recording:
                try AudioSessionManager.shared.configureRecordingSession()
            case .playbackWithMixing:
                try AudioSessionManager.shared.configurePlaybackSession(allowMixing: true)
        }
    }
    
    // 添加音频音量控制方法
    func setAudioVolume(_ volume: Double) {
        audioPlayer?.volume = Float(volume)
    }
    
    // 修改现有的 setVolume 方法名称，使其更明确
    func setVideoVolume(_ volume: Double) {
        videoController?.setVolume(volume)
    }
    
    enum AudioSessionMode {
        case playback
        case recording
        case playbackWithMixing
    }
    
    deinit {
        stopPlaybackTimer()
        videoController = nil
    }
} 