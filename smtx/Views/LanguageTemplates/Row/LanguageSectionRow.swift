import SwiftUI
// MARK: - Helper Views

struct TemplateRowInfo: Codable, Equatable, Hashable {
    let coverImage: Data?
    let title: String?
    let totalDuration: Double
    private let _tags: [String]?
    
    var tags: NSArray? {
        get {
            if let tags = _tags {
                return tags as NSArray
            }
            return nil
        }
    }
    
    init(coverImage: Data?, title: String?, totalDuration: Double, tags: NSArray?) {
        self.coverImage = coverImage
        self.title = title
        self.totalDuration = totalDuration
        self._tags = tags as? [String]
    }
    
    enum CodingKeys: String, CodingKey {
        case coverImage
        case title
        case totalDuration
        case _tags = "tags"
    }
    
    // 实现 Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(coverImage)
        hasher.combine(title)
        hasher.combine(totalDuration)
        hasher.combine(_tags)
    }
    
    // 实现 Equatable
    static func == (lhs: TemplateRowInfo, rhs: TemplateRowInfo) -> Bool {
        return lhs.coverImage == rhs.coverImage &&
               lhs.title == rhs.title &&
               lhs.totalDuration == rhs.totalDuration &&
               lhs._tags == rhs._tags
    }
} 

struct TemplateRow: View {
    let template: TemplateRowInfo
    
    var body: some View {
        HStack(spacing: 12) {
            // 封面图片
            if let imageData = template.coverImage,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // 标题
                Text(template.title ?? "")
                    .font(.headline)
                    .lineLimit(2)
                
                HStack(alignment: .center, spacing: 8) {
                    // 时长
                    Text(formatDuration(template.totalDuration))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 分隔点
                    if let tags = template.tags as? [String], !tags.isEmpty {
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 3, height: 3)
                    }
                    
                    // 标签
                    if let tags = template.tags as? [String] {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.1))
                                        .foregroundColor(.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct GalleryTemplateRow: View {
    let template: TemplateRowInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 封面图片
            if let imageData = template.coverImage,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160,height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 160,height: 120)
            }
            
            // 标题区域 - 固定两行高度
            Text(template.title ?? "")
                .font(.headline)
                .lineLimit(2)
                .frame(height: 44, alignment: .topLeading) // 固定两行高度
            
            // 时长和标签区域 - 固定两行高度
            VStack(alignment: .leading, spacing: 4) {
                // 第一行：时长和第一个标签
                HStack(spacing: 6) {
                    Text(formatDuration(template.totalDuration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let tags = template.tags as? [String], !tags.isEmpty {
                        // 分隔点
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 3, height: 3)
                        
                        // 第一个标签
                        Text(tags[0])
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .clipShape(Capsule())
                            .lineLimit(1)
                    }
                }
                
                // 第二行：剩余标签的滚动视图
                if let tags = template.tags as? [String], tags.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(Array(tags.dropFirst()), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .clipShape(Capsule())
                                    .lineLimit(1)
                            }
                        }
                    }
                    .frame(height: 20) // 固定第二行高度
                }
            }
            .frame(height: 44, alignment: .topLeading) // 固定总高度
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// 添加新的进度条视图组件
struct PublishingProgressBar: View {
    let progress: Double
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(.linear)
                .tint(.accentColor)
                .frame(width: 200)
            
            Text(String(format: "%.0f%%", progress * 100))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 4)
    }
}