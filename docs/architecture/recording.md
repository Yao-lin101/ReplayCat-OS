# 录音系统设计

## 概述

录音系统是 SMTX 应用的重要功能模块，支持用户根据模板内容进行录音练习。本文档详细说明了录音系统的设计和实现细节。

## 核心功能

1. 录音功能
2. 音频播放
3. 波形显示
4. 音频处理
5. 录音管理

## 技术组件

### 1. RecordingManager

负责录音的核心功能：

```swift
class RecordingManager: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var currentTime: TimeInterval = 0
    
    private var audioEngine: AVAudioEngine
    private var audioFile: AVAudioFile?
    
    func startRecording() throws
    func stopRecording() throws -> URL
    func pauseRecording()
    func resumeRecording()
}
```

### 2. AudioPlayer

处理音频播放：

```swift
class AudioPlayer: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    func play(url: URL)
    func pause()
    func stop()
    func seek(to time: TimeInterval)
    func skipForward(_ seconds: TimeInterval = 15)
    func skipBackward(_ seconds: TimeInterval = 15)
}
```

### 3. WaveformView

显示音频波形：

```swift
struct WaveformView: View {
    let audioURL: URL
    @StateObject private var viewModel: WaveformViewModel
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // 绘制波形
            }
            .stroke(Color.accentColor, lineWidth: 2)
        }
    }
}
```

## 数据模型

### Recording

```swift
struct Recording: Identifiable, Codable {
    let id: String
    let templateId: String
    let audioUrl: URL
    let duration: TimeInterval
    let createdAt: Date
    var waveformData: [Float]?
    var metadata: RecordingMetadata
}

struct RecordingMetadata: Codable {
    var title: String
    var notes: String?
    var tags: [String]
    var quality: Int // 1-5 星评分
}
```

## 音频处理

### 1. 录音设置

```swift
struct AudioSettings {
    static let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 44100,
        channels: 1,
        interleaved: false
    )!
    
    static let recordingSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
}
```

### 2. 波形生成

```swift
class WaveformGenerator {
    func generateWaveform(from url: URL, 
                         samples: Int = 100) -> [Float] {
        // 读取音频文件
        // 处理音频数据
        // 生成波形数据
        return waveformData
    }
}
```

## 存储管理

### RecordingStorage

```swift
class RecordingStorage {
    func saveRecording(_ recording: Recording) throws
    func loadRecording(id: String) -> Recording?
    func deleteRecording(id: String) throws
    func getAllRecordings() -> [Recording]
    
    private func getDocumentsDirectory() -> URL
    private func getRecordingsDirectory() -> URL
}
```

## 用户界面

### 1. 录音界面

```swift
struct RecordingView: View {
    @StateObject private var recordingManager = RecordingManager()
    @State private var showingRecordingControls = false
    
    var body: some View {
        VStack {
            // 模板内容显示
            TemplateContentView(template: template)
            
            // 波形显示
            WaveformView(audioURL: recordingManager.currentRecordingURL)
            
            // 录音控制
            RecordingControlsView(manager: recordingManager)
        }
    }
}
```

### 2. 播放界面

```swift
struct PlaybackView: View {
    @StateObject private var audioPlayer = AudioPlayer()
    let recording: Recording
    
    var body: some View {
        VStack {
            // 波形显示
            WaveformView(audioURL: recording.audioUrl)
            
            // 播放控制
            PlaybackControlsView(player: audioPlayer)
            
            // 元数据显示
            RecordingMetadataView(metadata: recording.metadata)
        }
    }
}
```

## 性能优化

1. **内存管理**:
   - 及时释放音频资源
   - 优化波形数据处理
   - 缓存管理

2. **文件管理**:
   - 自动清理临时文件
   - 优化存储空间
   - 文件压缩

3. **UI 性能**:
   - 波形渲染优化
   - 动画性能
   - 响应性优化

## 错误处理

```swift
enum RecordingError: Error {
    case permissionDenied
    case initializationFailed
    case recordingFailed
    case saveFailed
    case loadFailed
    case invalidFormat
    
    var localizedDescription: String {
        switch self {
        case .permissionDenied:
            return "麦克风访问权限被拒绝"
        case .initializationFailed:
            return "录音系统初始化失败"
        // ...其他错误处理
        }
    }
}
```

## 测试策略

1. **单元测试**:
   - 录音功能测试
   - 音频处理测试
   - 存储操作测试

2. **集成测试**:
   - 完整录音流程测试
   - 文件管理测试
   - 性能测试

3. **UI 测试**:
   - 用户交互测试
   - 界面响应测试
   - 错误处理测试

## 最佳实践

1. **录音质量**:
   - 合适的采样率
   - 降噪处理
   - 音量标准化

2. **用户体验**:
   - 实时反馈
   - 直观的控制
   - 清晰的状态显示

3. **资源管理**:
   - 及时释放资源
   - 优化存储空间
   - 性能监控

## 常见问题

1. **权限问题**:
   - 麦克风权限请求
   - 存储权限管理
   - 权限状态监控

2. **性能问题**:
   - 长时间录音
   - 波形显示卡顿
   - 内存占用过高

3. **兼容性问题**:
   - 设备兼容性
   - iOS 版本适配
   - 音频格式支持
