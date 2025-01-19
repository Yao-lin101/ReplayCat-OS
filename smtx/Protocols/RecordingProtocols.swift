import Foundation

protocol TimelineProvider {
    var totalDuration: Double { get }
    var timelineItems: [TimelineDisplayData] { get }
    func getItemAt(timestamp: Double) -> TimelineDisplayData?
}

protocol RecordingDelegate {
    func saveRecording(audioData: Data, duration: Double) async throws -> String
    func deleteRecording(id: String) async throws
    func loadRecording(id: String) async throws -> (Data, Double)?
} 

// MARK: - Record Interface
protocol RecordInterface {
    var id: String? { get }
    var duration: Double { get }
    var createdAt: Date? { get }
}

extension Record: RecordInterface {}