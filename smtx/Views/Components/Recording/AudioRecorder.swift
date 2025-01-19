import Foundation
import AVFoundation
import SwiftUI

class AudioRecorder: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private(set) var recordingURL: URL?
    
    @Published var isRecording = false
    @Published var audioLevels: [CGFloat] = []
    private let maxLevels = 100
    
    init() {
        setupAudioSession()
        setupAudioEngine()
    }
    
    private func setupAudioSession() {
        do {
            try AudioSessionManager.shared.configureRecordingSession()
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        let recordingFormat = inputNode?.outputFormat(forBus: 0)
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            DispatchQueue.main.async {
                self?.updateAudioLevels(buffer: buffer)
            }
        }
    }
    
    private func updateAudioLevels(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let channelDataCount = Int(buffer.frameLength)
        
        let normalizeSample = { (sample: Float) -> CGFloat in
            let absolute = abs(sample)
            let scaled = pow(absolute, 0.5) * 1.2
            return CGFloat(min(scaled, 1.0))
        }
        
        // 计算音频样本的峰值
        var peak: Float = 0
        for i in 0..<channelDataCount {
            peak = max(peak, abs(channelData[i]))
        }
        
        let newLevel = normalizeSample(peak)
        
        if audioLevels.count >= maxLevels {
            audioLevels.removeFirst()
        }
        
        audioLevels.append(newLevel)
    }
    
    func startRecording(url: URL) {
        recordingURL = url
        print("🎙️ AudioRecorder - Starting recording to: \(url.path)")
        
        // 设置录音参数
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            
            try audioEngine?.start()
            isRecording = true
            print("✅ AudioRecorder - Recording started successfully")
        } catch {
            print("❌ AudioRecorder - Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        print("🛑 AudioRecorder - Stopping recording...")
        audioRecorder?.stop()
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        isRecording = false
        print("✅ AudioRecorder - Recording stopped")
        
        // 清空音频电平数组
        audioLevels.removeAll()
    }
}

struct WaveformView: View {
    let levels: [CGFloat]
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - 4
            let barWidth = max(1, availableWidth / CGFloat(200))
            let spacing = max(0, barWidth / 2)
            
            HStack(spacing: spacing) {
                ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: barWidth)
                        .frame(height: geometry.size.height * 0.4 * level)
                        .frame(maxHeight: .infinity, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 2)
        }
    }
} 
