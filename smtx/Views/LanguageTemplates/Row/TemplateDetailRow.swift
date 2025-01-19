import SwiftUI
// MARK: - Record Row
struct RecordRow<T: RecordInterface>: View {
    let record: T
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(record.createdAt ?? Date()))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text(formatDuration(record.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "play.circle")
                .font(.title2)
                .foregroundColor(.accentColor)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
