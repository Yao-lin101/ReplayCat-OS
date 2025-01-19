import SwiftUI
import AVFoundation

struct BaseRecordingView: View {
    let timelineProvider: TimelineProvider
    let delegate: RecordingDelegate
    var onUpload: (() -> Void)?
    let isUploading: Bool
    let showDeleteButton: Bool
    let showUploadButton: Bool
    let isVideo: Bool
    let videoUrl: URL?
    let initialRecordId: String?
    @State private var recordId: String?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recordingController = RecordingController()
    @StateObject private var playerController = TimelinePlayerController()
    @State private var currentItem: TimelineDisplayData?
    @State private var isPreviewMode = false
    @State private var showingDeleteAlert = false
    @State private var showingWaveform = false
    @State private var isInitializing: Bool = true
    
    init(
        timelineProvider: TimelineProvider,
        delegate: RecordingDelegate,
        recordId: String? = nil,
        onUpload: (() -> Void)? = nil,
        isUploading: Bool = false,
        showDeleteButton: Bool = true,
        showUploadButton: Bool = true,
        isVideo: Bool = false,
        videoUrl: URL? = nil
    ) {
        self.timelineProvider = timelineProvider
        self.delegate = delegate
        self.initialRecordId = recordId
        self._recordId = State(initialValue: recordId)
        self.onUpload = onUpload
        self.isUploading = isUploading
        self.showDeleteButton = showDeleteButton
        self.showUploadButton = showUploadButton
        self.isVideo = isVideo
        self.videoUrl = videoUrl
    }
    
    var body: some View {
        Group {
            if isInitializing {
                ProgressView()
            } else {
                VStack(spacing: 0) {
                    TimelinePlayerView(
                        playerController: playerController,
                        isPreviewMode: isPreviewMode,
                        isVideo: isVideo,
                        videoUrl: videoUrl
                    )
                    .padding(.top, 40)
                    
                    // 底部控制区域
                    VStack(spacing: 20) {
                        // 示波器
                        if !isPreviewMode{
                            WaveformView(levels: showingWaveform ? [] : recordingController.audioLevels)
                                .frame(height: 100)
                                .padding(.horizontal, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.black.opacity(0.08))
                                )
                                .padding(.horizontal, 8)
                                .opacity((recordingController.isRecording || showingWaveform) ? 1 : 0)
                        }
                        
                        // 控制按钮
                        RecordingControlsView(
                            mode: isPreviewMode ? .preview : .recording,
                            isRecording: recordingController.isRecording,
                            isPlaying: playerController.isAudioPlaying,
                            onRecordTap: recordingController.isRecording ? stopRecording : startRecording,
                            onPlayTap: playerController.isAudioPlaying ? pausePreview : startPreview,
                            onBackward: backward10Seconds,
                            onForward: forward10Seconds,
                            onDelete: { showingDeleteAlert = true },
                            onDismiss: { @MainActor in dismiss() },
                            onUpload: onUpload,
                            isUploading: isUploading,
                            showDeleteButton: showDeleteButton,
                            showUploadButton: showUploadButton
                        )
                        .id(playerController.playStateVersion)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let recordId = recordId {
                await initializePreview(recordId: recordId)
            }
            isInitializing = false
        }
        .onDisappear {
            stopRecording()
            stopPreview()
            playerController.cleanup()
        }
        .alert("删除录音", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {
                print("❌ Delete cancelled")
            }
            Button("删除", role: .destructive) {
                print("✅ Delete confirmed, proceeding with deletion")
                deleteRecording()
            }
        } message: {
            Text("确定要删除这个录音吗？")
        }
    }
    
    // MARK: - Recording Methods
    
    private func startRecording() {
        print("🎙️ Starting recording...")
        
        do {
            // 1. 配置音频会话 - 录音时不需要混音
            try playerController.configureRecordingSession(allowMixing: false)
            
            // 2. 如果有视频，先设置视频播放器
            if isVideo, let videoUrl = videoUrl {
                print("🎥 Setting up video with URL: \(videoUrl)")
                playerController.setupVideo(with: videoUrl, volume: 0)
            }
            
            // 3. 开始录音
            try recordingController.startRecording(duration: timelineProvider.totalDuration)
            
            // 4. 设置录音完成回调
            recordingController.onRecordingFinished = {
                self.stopRecording()
            }
            
            recordingController.bindTimelinePlayer(playerController)
            
            // 5. 开始播放视频
            if isVideo {
                print("▶️ Requesting video playback")
                playerController.play()
            }
            
            playerController.setDuration(timelineProvider.totalDuration)
            
        } catch {
            print("❌ Failed to start recording: \(error)")
        }
    }
    
    private func stopRecording() {
        print("🛑 Stopping recording...")
        
        recordingController.stopRecording()
        recordingController.onRecordingFinished = nil
        
        guard let recordingURL = recordingController.recordingURL else { return }
        let recordedDuration = recordingController.currentTime
        
        do {
            try playerController.setupAudioPlayer(with: recordingURL)
            
            Task {
                do {
                    let audioData = try AudioFileManager.shared.getAudioData(from: recordingURL)
                    recordId = try await delegate.saveRecording(audioData: audioData, duration: recordedDuration)
                    print("✅ Recording saved")
                    
                    await MainActor.run {
                        isPreviewMode = true
                        playerController.stop()
                        playerController.seek(to: 0)
                    }
                    
                    AudioFileManager.shared.removeTempFile(at: recordingURL)
                } catch {
                    print("❌ Failed to save recording: \(error)")
                }
            }
        } catch {
            print("❌ Failed to prepare preview: \(error)")
        }
    }
    
    // MARK: - Preview Methods
    
    private func startPreview() {
        print("▶️ Starting preview at time: \(playerController.currentTime)")
        playerController.play()
    }
    
    private func pausePreview() {
        print("⏸️ Pausing preview at time: \(playerController.currentTime)")
        playerController.pause()
    }
    
    private func stopPreview() {
        print("⏹️ Stopping preview")
        playerController.stop()
    }
    
    private func forward10Seconds() {
        let newTime = min(playerController.recordedDuration, playerController.currentTime + 10)
        print("⏩ Forward 10s: \(playerController.currentTime) -> \(newTime) (max: \(playerController.recordedDuration))")
        playerController.seek(to: newTime)
    }
    
    private func backward10Seconds() {
        let newTime = max(0, playerController.currentTime - 10)
        print("⏪ Backward 10s: \(playerController.currentTime) -> \(newTime)")
        playerController.seek(to: newTime)
    }
    
    // MARK: - Helper Methods
    
    private func initializePreview(recordId: String) async {
        playerController.setupTimelineProvider(timelineProvider)
        
        do {
            guard let (audioData, _) = try await delegate.loadRecording(id: recordId) else {
                return
            }
            
            // 使用 AudioFileManager 创建临时文件
            let tempURL = try AudioFileManager.shared.createTempFile(for: recordId, with: audioData)
            
            await MainActor.run {
                isPreviewMode = true
                
                // 设置播放器控制器
                do {
                    try playerController.setupAudioPlayer(with: tempURL)
                    if let videoUrl = videoUrl {
                        playerController.setupVideo(with: videoUrl, volume: 0)
                    }
                    checkAndStartPlayback()
                } catch {
                    print("❌ Failed to setup audio player: \(error)")
                }
            }
        } catch {
            print("❌ Failed to load recording for preview: \(error)")
        }
    }
    
    private func deleteRecording() {
        guard let recordId = recordId else {
            print("❌ Cannot delete recording: recordId is nil")
            return
        }
        
        print("🗑️ Starting to delete recording: \(recordId)")
        Task {
            do {
                try await delegate.deleteRecording(id: recordId)
                print("✅ Successfully deleted recording: \(recordId)")
                await MainActor.run {
                    print("🔄 Dismissing view after deletion")
                    dismiss()
                }
            } catch {
                print("❌ Failed to delete recording: \(error)")
            }
        }
    }
    
    private func checkAndStartPlayback() {
        if playerController.isReadyToPlay {
            print("✅ Both audio and video are ready for playback")
            do {
                try playerController.configureAudioSession(for: .playbackWithMixing)
                playerController.seek(to: playerController.currentTime)
            } catch {
                print("❌ Failed to configure audio session: \(error)")
            }
        }
    }
} 
