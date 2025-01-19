import CoreData
import UIKit

// MARK: - Notification Names

extension Notification.Name {
    static let templateDidUpdate = Notification.Name("templateDidUpdate")
}

// MARK: - Storage Service

class TemplateStorage {
    static let shared = TemplateStorage()
    
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    private let languagesKey = "LanguageSections"
    private let userDefaults = UserDefaults.standard
    
    private init() {
        container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Error loading Core Data: \(error)")
            }
        }
        context = container.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Error Types
    
    enum StorageError: Error {
        case templateNotFound
        case sectionNotFound
        case notVideoTemplate
        
        var localizedDescription: String {
            switch self {
            case .templateNotFound:
                return "Template not found"
            case .sectionNotFound:
                return "Language section not found"
            case .notVideoTemplate:
                return "Not a video template"
            }
        }
    }

    // MARK: - Template Operations
    
    func createTemplate(title: String, sectionId: String, coverImage: UIImage) throws -> String {
        let template = Template(context: context)
        let templateId = UUID().uuidString
        
        // Set metadata
        template.id = templateId
        template.createdAt = Date()
        template.updatedAt = Date()
        template.version = "1.0"
        
        // Set cloud sync status
        template.cloudUid = nil
        template.cloudVersion = nil
        template.lastSyncedAt = nil
        
        // Set template data
        template.title = title
        template.coverImage = coverImage.jpegData(compressionQuality: 0.8)
        template.totalDuration = 0
        template.tags = []
        
        // Associate with section
        let section = try loadLanguageSection(id: sectionId)
        template.section = section
        
        try context.save()
        return templateId
    }
    
    func updateTemplate(
        templateId: String,
        title: String,
        coverImage: UIImage?,
        tags: [String],
        timelineItems: [TimelineItemData],
        totalDuration: Double,
        onlyScriptChanges: Bool = false
    ) throws {
        let template = try loadTemplate(templateId: templateId)
        
        print("📝 Updating template: \(templateId)")
        print("- Title: \(title)")
        print("- Duration: \(totalDuration) seconds")
        print("- Tags: \(tags)")
        print("- Timeline items: \(timelineItems.count)")
        print("- Only script changes: \(onlyScriptChanges)")
        
        // 更新版本号
        if let currentVersion = template.version {
            let versionComponents = currentVersion.split(separator: ".")
            if versionComponents.count == 2,
               let major = Int(versionComponents[0]),
               let minor = Int(versionComponents[1]) {
                // 增加次版本号，如果超过99则增加主版本号
                if minor >= 99 {
                    template.version = "\(major + 1).0"
                } else {
                    template.version = "\(major).\(minor + 1)"
                }
            } else {
                // 如果版本号格式不正确，重置为1.0
                template.version = "1.0"
            }
        } else {
            // 如果没有版本号，设置为1.0
            template.version = "1.0"
        }
        
        // 更新基本信息
        template.title = title
        template.updatedAt = Date()
        template.tags = tags as NSArray
        template.totalDuration = totalDuration
        
        // 更新封面图片（如果提供）
        if let coverImage = coverImage {
            template.coverImage = coverImage.jpegData(compressionQuality: 0.8)
        }
        
        // 更新时间轴项目
        let existingItems = template.timelineItems?.allObjects as? [TimelineItem] ?? []
        let existingItemsDict = Dictionary(grouping: existingItems) { $0.timestamp }
        
        // 添加或更新时间轴项目
        for itemData in timelineItems {
            let existingItem = existingItemsDict[itemData.timestamp]?.first
            let item = existingItem ?? TimelineItem(context: context)
            
            // 更新基本属性
            item.id = itemData.id
            item.timestamp = itemData.timestamp
            item.script = itemData.script
            item.createdAt = itemData.createdAt
            
            // 更新图片相关属性
            if !onlyScriptChanges {
                let currentImageHash = item.image?.sha256()
                let newImageHash = itemData.imageData?.sha256()
                
                if currentImageHash != newImageHash {
                    item.image = itemData.imageData
                    item.imageUpdatedAt = Date()
                }
            }
            
            // 更新脚本时间戳
            if item.script != itemData.script {
                item.updatedAt = Date()
            }
            
            item.template = template
        }
        
        // 删除不再使用的项目
        let timestampsToKeep = Set(timelineItems.map { $0.timestamp })
        for item in existingItems {
            if !timestampsToKeep.contains(item.timestamp) {
                context.delete(item)
            }
        }
        
        try context.save()
        print("✅ Template updated successfully")
        print("- New version: \(template.version ?? "1.0")")
        
        NotificationCenter.default.post(name: .templateDidUpdate, object: nil)
    }
    
    // 下载创建本地模板
    func createCloudLinkedTemplate(
        sectionId: String,
        cloudUid: String,
        cloudVersion: String,
        coverImage: Data,
        tags: [String],
        title: String,
        totalDuration: Double
    ) throws -> Template {
        let template = Template(context: context)
        let templateId = UUID().uuidString
        
        // 设置基本信息
        template.id = templateId
        template.title = title
        template.coverImage = coverImage
        template.totalDuration = totalDuration
        template.tags = tags as NSArray
        template.createdAt = Date()
        template.updatedAt = Date()
        
        // 设置云端信息
        template.cloudUid = cloudUid
        template.cloudVersion = cloudVersion
        template.version = cloudVersion
        template.lastSyncedAt = Date()
        
        // 关联分区
        let section = try loadLanguageSection(id: sectionId)
        template.section = section
        
        try context.save()
        return template
    }
    
    func getTemplateTags(_ template: Template) -> [String] {
        return (template.tags as? [String]) ?? []
    }
    
    func loadTemplate(templateId: String) throws -> Template {
        let request = Template.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", templateId)
        
        guard let template = try context.fetch(request).first,
              template.id != nil
        else {
            throw StorageError.templateNotFound
        }
        
        return template
    }
    
    func listTemplatesByLanguage() throws -> [String: [Template]] {
        let sections = try listLanguageSections()
        var templatesByLanguage: [String: [Template]] = [:]
        
        for section in sections {
            if let templates = section.templates?.allObjects as? [Template] {
                templatesByLanguage[section.name ?? ""] = templates.sorted { 
                    ($0.updatedAt ?? Date.distantPast) > ($1.updatedAt ?? Date.distantPast)
                }
            }
        }
        
        return templatesByLanguage
    }
    
    func saveTimelineItem(templateId: String, timestamp: Double, script: String, image: UIImage, type: String) throws -> String {
        let item = TimelineItem(context: context)
        
        let itemId = UUID().uuidString
        item.id = itemId
        item.timestamp = timestamp
        item.script = script
        item.image = image.jpegData(compressionQuality: 0.8)
        item.createdAt = Date()
        item.updatedAt = Date()
        item.imageUpdatedAt = Date()

        if type == "video" {
            let template = try loadVideoTemplate(templateId: templateId).0
            item.videoTemplate = template
            template.updatedAt = Date()
        } else {
            let template = try loadTemplate(templateId: templateId)
            item.template = template
            template.updatedAt = Date()
        }
        
        try context.save()
        
        return itemId
    }
    
    func deleteTemplate(templateId: String) throws {
        let template = try loadTemplate(templateId: templateId)
        context.delete(template)
        try context.save()
    }
    
    // MARK: - Language Section Management
    
    func getLanguageSections() -> [String] {
        return userDefaults.stringArray(forKey: languagesKey) ?? []
    }
    
    func addLanguageSection(_ name: String) {
        var sections = getLanguageSections()
        if !sections.contains(name) {
            sections.append(name)
            userDefaults.set(sections, forKey: languagesKey)
        }
    }

    func saveRecord(templateId: String, duration: Double, audioData: Data, templateType: TemplateType) throws -> String {
        let record = Record(context: context)
        let recordId = UUID().uuidString
        record.id = recordId
        record.createdAt = Date()
        record.duration = duration
        record.audioData = audioData

        switch templateType {
            case .localTextImage:
                let template = try loadTemplate(templateId: templateId)
                record.template = template
            case .localVideo:
                let (template, _) = try loadVideoTemplate(templateId: templateId)
                record.videoTemplate = template
        }
        
        try context.save()
        return recordId
    }
    
    func deleteRecord(_ recordId: String) throws {
        let context = container.viewContext
        let request: NSFetchRequest<Record> = Record.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", recordId)
        
        if let record = try context.fetch(request).first {
            // 直接删除记录，因为音频数据存储在 audioData 中
            context.delete(record)
            try context.save()
        }
    }
    
    // MARK: - Language Section Operations
    
    func createLanguageSection(name: String, cloudSectionId: String? = nil) throws -> LocalLanguageSection {
        let section = LocalLanguageSection(context: context)
        section.id = UUID().uuidString
        section.name = name
        section.cloudSectionId = cloudSectionId
        section.createdAt = Date()
        section.updatedAt = Date()
        
        try context.save()
        return section
    }
    
    func loadLanguageSection(id: String) throws -> LocalLanguageSection {
        let request = LocalLanguageSection.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        guard let section = try context.fetch(request).first else {
            throw StorageError.sectionNotFound
        }
        
        return section
    }
    
    func listLanguageSections() throws -> [LocalLanguageSection] {
        let request = LocalLanguageSection.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return try context.fetch(request)
    }
    
    func updateLanguageSection(id: String, name: String, cloudSectionId: String?) throws {
        let section = try loadLanguageSection(id: id)
        section.name = name
        section.cloudSectionId = cloudSectionId
        section.updatedAt = Date()
        
        try context.save()
    }
    
    func deleteLanguageSection(_ section: LocalLanguageSection) throws {
        context.delete(section)
        try context.save()
    }
    
    func assignTemplateToSection(templateId: String, sectionId: String) throws {
        let template = try loadTemplate(templateId: templateId)
        let section = try loadLanguageSection(id: sectionId)
        
        template.section = section
        try context.save()
    }
    
    // MARK: - Video Template Operations
    
    /// 创建视频模板
    func createVideoTemplate(
        title: String,
        sectionId: String,
        coverImage: UIImage,
        videoInfo: VideoInfo?,
        videoUrlOriginal: String,
        videoUrlLocal: String
    ) throws -> String {
        let template = VideoTemplate(context: context)
        let templateId = UUID().uuidString
        
        // 设置基本信息
        template.id = templateId
        template.title = title
        template.coverImage = coverImage.jpegData(compressionQuality: 0.8)
        template.videoInfo = videoInfo?.toJSONString()
        template.videoUrlOriginal = videoUrlOriginal
        template.videoUrlLocal = videoUrlLocal
        template.createdAt = Date()
        template.updatedAt = Date()
        template.version = "1.0"
        
        // 关联分区
        let section = try loadLanguageSection(id: sectionId)
        template.section = section
        
        try context.save()
        return templateId
    }
    
    /// 更新视频模板
    func updateVideoTemplate(
        templateId: String,
        title: String,
        coverImage: UIImage?,
        tags: [String],
        timelineItems: [TimelineItemData],
        totalDuration: Double,
        onlyScriptChanges: Bool
    ) throws {
        let request = VideoTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", templateId)
        guard let template = try context.fetch(request).first else {
            throw StorageError.templateNotFound
        }

        // 更新版本号
        if let currentVersion = template.version {
            let versionComponents = currentVersion.split(separator: ".")
            if versionComponents.count == 2,
               let major = Int(versionComponents[0]),
               let minor = Int(versionComponents[1]) {
                // 增加次版本号，如果超过99则增加主版本号
                if minor >= 99 {
                    template.version = "\(major + 1).0"
                } else {
                    template.version = "\(major).\(minor + 1)"
                }
            } else {
                // 如果版本号格式不正确，重置为1.0
                template.version = "1.0"
            }
        } else {
            // 如果没有版本号，设置为1.0
            template.version = "1.0"
        }
        
        // 更新基本信息
        template.title = title
        template.tags = tags as NSArray
        template.totalDuration = totalDuration
        template.updatedAt = Date()
        
        // 更新封面（如果提供）
        if let coverImage = coverImage {
            template.coverImage = coverImage.jpegData(compressionQuality: 0.8)
            template.coverUpdatedAt = Date()
        }
        
        // 更新时间轴项目
        let existingItems = template.timelineItems?.allObjects as? [TimelineItem] ?? []
        let existingItemsDict = Dictionary(grouping: existingItems) { $0.timestamp }
        
        // 添加或更新时间轴项目
        for itemData in timelineItems {
            let existingItem = existingItemsDict[itemData.timestamp]?.first
            let item = existingItem ?? TimelineItem(context: context)
            
            item.id = itemData.id
            item.timestamp = itemData.timestamp
            item.script = itemData.script
            item.createdAt = itemData.createdAt
            item.updatedAt = itemData.updatedAt
            item.videoTemplate = template
            // 更新图片相关属性
            if !onlyScriptChanges {
                let currentImageHash = item.image?.sha256()
                let newImageHash = itemData.imageData?.sha256()
                
                if currentImageHash != newImageHash {
                    item.image = itemData.imageData
                    item.imageUpdatedAt = Date()
                }
            }
        }
        
        // 删除不再使用的项目
        let timestampsToKeep = Set(timelineItems.map { $0.timestamp })
        for item in existingItems {
            if !timestampsToKeep.contains(item.timestamp) {
                context.delete(item)
            }
        }
        
        try context.save()
        NotificationCenter.default.post(name: .templateDidUpdate, object: nil)
    }

    // 下载创建本地视频模板
    func createCloudLinkedVideoTemplate(
        sectionId: String,
        cloudUid: String,
        cloudVersion: String,
        coverImage: Data,
        tags: [String],
        title: String,
        totalDuration: Double,
        videoInfo: VideoInfo,
        videoUrlOriginal: String,
        videoUrlLocal: String
    ) throws -> VideoTemplate {
        let template = VideoTemplate(context: context)
        let templateId = UUID().uuidString
        
        // 设置基本信息
        template.id = templateId
        template.title = title
        template.coverImage = coverImage
        template.totalDuration = totalDuration
        template.tags = tags as NSArray
        template.createdAt = Date()
        template.updatedAt = Date()
        template.videoInfo = videoInfo.toJSONString()
        template.videoUrlOriginal = videoUrlOriginal
        template.videoUrlLocal = videoUrlLocal

        // 设置云端信息
        template.cloudUid = cloudUid
        template.cloudVersion = cloudVersion
        template.version = cloudVersion
        template.lastSyncedAt = Date()
        
        // 关联分区
        let section = try loadLanguageSection(id: sectionId)
        template.section = section
        
        try context.save()
        return template
    }
    
    /// 加载视频模板
    func loadVideoTemplate(templateId: String) throws -> (VideoTemplate, VideoInfo) {
        let request = VideoTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", templateId)
        
        guard let template = try context.fetch(request).first,
              let videoInfoString = template.videoInfo,
              let videoInfo = VideoInfo.fromJSONString(videoInfoString) else {
            throw StorageError.templateNotFound
        }
        
        return (template, videoInfo)
    }
    
    /// 按语言分区列出视频模板
    func listVideoTemplatesByLanguage() throws -> [String: [VideoTemplate]] {
        let sections = try listLanguageSections()
        var templatesByLanguage: [String: [VideoTemplate]] = [:]
        
        for section in sections {
            if let templates = section.videoTemplates?.allObjects as? [VideoTemplate] {
                templatesByLanguage[section.name ?? ""] = templates.sorted { 
                    ($0.updatedAt ?? Date.distantPast) > ($1.updatedAt ?? Date.distantPast)
                }
            }
        }
        
        return templatesByLanguage
    }

    func deleteVideoTemplate(templateId: String) throws {
        let context = container.viewContext
        let request = VideoTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", templateId)
        
        guard let template = try context.fetch(request).first else {
            throw StorageError.templateNotFound
        }
        
        // 1. 获取视频文件名
        if let localPath = template.videoUrlLocal {
            let fileName = (localPath as NSString).lastPathComponent
            
            // 2. 检查是否有其他模板在使用这个视频文件
            let otherTemplatesRequest = VideoTemplate.fetchRequest()
            otherTemplatesRequest.predicate = NSPredicate(format: "id != %@ AND videoUrlLocal ENDSWITH %@", templateId, fileName)
            let otherTemplates = try context.fetch(otherTemplatesRequest)
            
            // 3. 如果没有其他模板使用这个视频文件，则删除文件
            if otherTemplates.isEmpty {
                try? VideoFileManager.shared.deleteVideo(at: localPath)
            }
        }
        
        // 4. 删除模板数据（关联的 timelineItems 会被自动级联删除）
        context.delete(template)
        try context.save()
    }
    
    /// 获取未使用的视频缓存大小
    func getUnusedVideoCacheSize() throws -> Int64 {
        let context = container.viewContext
        context.reset()
        
        let request = VideoTemplate.fetchRequest()
        request.propertiesToFetch = ["id", "videoUrlLocal"]
        
        // 获取所有视频模板
        let templates = try context.fetch(request)
        
        // 收集所有正在使用的视频文件名
        let usedFileNames = Set(templates.compactMap { template -> String? in
            guard let path = template.videoUrlLocal else { return nil }
            return (path as NSString).lastPathComponent
        })
        
        // 获取未使用的视频缓存大小
        return VideoFileManager.shared.getUnusedCacheSize(usedFileNames: usedFileNames)
    }
    
    /// 清理未使用的视频文件
    func cleanupUnusedVideos() throws {
        let context = container.viewContext
        context.reset()
        
        let request = VideoTemplate.fetchRequest()
        request.propertiesToFetch = ["id", "videoUrlLocal"]
        
        // 获取所有视频模板
        let templates = try context.fetch(request)
        
        // 收集所有正在使用的视频文件名
        let usedFileNames = Set(templates.compactMap { template -> String? in
            guard let path = template.videoUrlLocal else { return nil }
            return (path as NSString).lastPathComponent
        })
        
        // 调用 VideoFileManager 的清理方法
        VideoFileManager.shared.cleanupUnusedVideos(usedFileNames: usedFileNames)
    }
    
    /// 清理过期的视频文件
    func cleanupExpiredVideos(olderThan days: Int = 7) throws {
        let context = container.viewContext
        let request = VideoTemplate.fetchRequest()
        
        // 获取所有视频模板
        let templates = try context.fetch(request)
        
        // 收集所有正在使用的视频路径
        let usedPaths = Set(templates.compactMap { template -> String? in
            guard let path = template.videoUrlLocal else { return nil }
            return (path as NSString).standardizingPath
        })
        
        // 调用 VideoFileManager 的清理方法，传入使用中的路径
        VideoFileManager.shared.cleanupExpiredVideos(olderThan: days, usedPaths: usedPaths)
    }
}
