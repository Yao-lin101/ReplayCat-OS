import Foundation
import CoreData
import AVFoundation

// MARK: - Data Models
struct RecordData {
    let id: String
    let duration: Double
    let audioPath: String
    let createdAt: Date
    let updatedAt: Date
}

enum RecordingError: LocalizedError {
    case invalidTemplate
    case recordNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidTemplate:
            return "无效的模板"
        case .recordNotFound:
            return "找不到录音记录"
        }
    }
} 

class LocalRecordingDelegate: RecordingDelegate {
    private let template: Template
    private let storage = TemplateStorage.shared
    
    init(template: Template) {
        self.template = template
    }
    
    func saveRecording(audioData: Data, duration: Double) async throws -> String {
        guard let templateId = template.id else {
            throw RecordingError.invalidTemplate
        }
        
        let recordId = try storage.saveRecord(
            templateId: templateId,
            duration: duration,
            audioData: audioData,
            templateType: .localTextImage
        )
        return recordId
    }
    
    func deleteRecording(id: String) async throws {
        try storage.deleteRecord(id)
    }
    
    func loadRecording(id: String) async throws -> (Data, Double)? {
        guard let records = template.records?.allObjects as? [Record],
              let record = records.first(where: { $0.id == id }),
              let audioData = record.audioData else {
            return nil
        }
        
        return (audioData, record.duration)
    }
}

// MARK: - Local Video Recording Delegate
class LocalVideoRecordingDelegate: RecordingDelegate {
    private let template: VideoTemplate
    private let storage = TemplateStorage.shared
    
    init(template: VideoTemplate) {
        self.template = template
    }
    
    func saveRecording(audioData: Data, duration: Double) async throws -> String {
        guard let templateId = template.id else {
            throw RecordingError.invalidTemplate
        }
        
        let recordId = try storage.saveRecord(
            templateId: templateId,
            duration: duration,
            audioData: audioData,
            templateType: .localVideo
        )
        return recordId
    }
    
    func deleteRecording(id: String) async throws {
        try storage.deleteRecord(id)
    }
    
    func loadRecording(id: String) async throws -> (Data, Double)? {
        guard let records = template.records?.allObjects as? [Record],
              let record = records.first(where: { $0.id == id }),
              let audioData = record.audioData else {
            return nil
        }
        
        return (audioData, record.duration)
    }
}
