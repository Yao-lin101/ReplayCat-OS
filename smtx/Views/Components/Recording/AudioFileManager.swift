import Foundation
import AVFoundation

class AudioFileManager {
    static let shared = AudioFileManager()
    
    private init() {}
    
    // 创建临时音频文件
    func createTempFile(for recordId: String, with data: Data) throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("preview_\(recordId).m4a")
        try data.write(to: tempURL)
        return tempURL
    }
    
    // 删除临时文件
    func removeTempFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    // 创建录音文件
    func createRecordingFile() throws -> URL {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw AudioFileError.documentsDirectoryNotFound
        }
        
        let recordingName = "recording_\(Date().timeIntervalSince1970).m4a"
        return documentsPath.appendingPathComponent(recordingName)
    }
    
    // 获取音频数据
    func getAudioData(from url: URL) throws -> Data {
        try Data(contentsOf: url)
    }
    
    enum AudioFileError: Error {
        case documentsDirectoryNotFound
    }
} 