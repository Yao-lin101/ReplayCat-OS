import SwiftUI
import AVFoundation

class RecordingController: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var currentTime: Double = 0
    @Published var audioLevels: [CGFloat] = []
    
    private var audioRecorder: AVAudioRecorder?
    var recordingURL: URL?
    private var timer: Timer?
    private var totalDuration: Double = 0
    private var levelUpdateCounter: Int = 0
    
    var onRecordingFinished: (() -> Void)?
    
    // 添加与 TimelinePlayerController 的集成方法
    func bindTimelinePlayer(_ player: TimelinePlayerController) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self, weak player] _ in
            guard let self = self else { return }
            
            self.currentTime += 0.03
            self.updateAudioLevels()
            
            // 更新播放器时间
            player?.updateCurrentTime(self.currentTime)
            
            if self.currentTime >= self.totalDuration {
                self.stopRecording()
                self.onRecordingFinished?()
            }
        }
    }
    
    func startRecording(duration: Double) throws {
        self.totalDuration = duration
        self.currentTime = 0
        
        // 使用 AudioFileManager 创建录音文件
        let url = try AudioFileManager.shared.createRecordingFile()
        self.recordingURL = url
        
        // 配置录音设置
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // 创建录音器
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
        
        // 开始录音
        audioRecorder?.record()
        isRecording = true
        
        // 启动定时器更新音频电平
        startAudioLevelTimer()
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        timer?.invalidate()
        timer = nil
        isRecording = false
    }
    
    private func startAudioLevelTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            self?.updateAudioLevels()
        }
    }
    
    private func updateAudioLevels() {
        guard let recorder = audioRecorder, isRecording else { return }
        
        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)
        let normalizedLevel = CGFloat(pow(10, level/20)) // 将分贝转换为线性值
        
        // 每3帧更新一次波形
        levelUpdateCounter += 1
        if levelUpdateCounter % 3 == 0 {
            DispatchQueue.main.async {
                if self.audioLevels.count >= 50 {
                    self.audioLevels.removeFirst()
                }
                self.audioLevels.append(normalizedLevel)
            }
        }
    }
    
    var recordingDuration: Double {
        currentTime
    }
    
    enum RecordingError: Error {
        case documentsDirectoryNotFound
    }
    
    // 添加清理方法
    func cleanup() {
        stopRecording()
        audioLevels.removeAll()
        levelUpdateCounter = 0
        currentTime = 0
        totalDuration = 0
        recordingURL = nil
    }
} 