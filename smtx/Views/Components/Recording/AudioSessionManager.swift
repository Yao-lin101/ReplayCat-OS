import AVFoundation

class AudioSessionManager {
    static let shared = AudioSessionManager()
    
    private init() {}
    
    func configurePlaybackSession(allowMixing: Bool = false) throws {
        let options: AVAudioSession.CategoryOptions = allowMixing ? [.mixWithOthers, .duckOthers] : []
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: options)
        try AVAudioSession.sharedInstance().setActive(true)
    }
    
    func configureRecordingSession(allowMixing: Bool = false) throws {
        let session = AVAudioSession.sharedInstance()
        
        // 设置 .playAndRecord 类别，但不使用 .defaultToSpeaker 选项
        // 这样会使用系统默认的音频路由（如耳机）
        let options: AVAudioSession.CategoryOptions = [.allowBluetooth, .allowBluetoothA2DP]
        try session.setCategory(.playAndRecord, mode: .default, options: options)
        
        // 确保不会强制使用扬声器
        try session.overrideOutputAudioPort(.none)
        try session.setActive(true)
    }
    
    func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false)
    }
} 