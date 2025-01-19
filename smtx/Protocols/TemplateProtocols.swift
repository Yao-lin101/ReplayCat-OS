import Foundation
import SwiftUI

public protocol TemplateListItem: Identifiable {
    var title: String? { get }
    var coverImage: Data? { get }
    var totalDuration: Double { get }
    var tags: NSArray? { get }
    var updatedAt: Date? { get }
    var type: String? { get }
    var cloudUid: String? { get }
    // 添加获取唯一标识符的方法
    func getIdentifier() -> String
    func getVersion() -> String
}

// 提供默认实现
public extension TemplateListItem {
    var id: String {
        return getIdentifier()
    }

    var version: String {  
        return getVersion()
    }
}

protocol TemplateContainer {
    var records: NSSet? { get }
    var title: String? { get }
    var cloudUid: String? { get }
    var cloudVersion: String? { get }
    var tags: NSArray? { get }
    var coverImage: Data? { get }
    var totalDuration: Double { get }
    var timelineItems: NSSet? { get }
    var type: String? { get }
}

public protocol ReleaseContainer: Identifiable {
    var id: String? { get }
    var title: String? { get }
    var cloudUid: String? { get }
    var cloudVersion: String? { get }
    var tags: NSArray? { get }
    var coverImage: Data? { get }
    var totalDuration: Double { get }
    var timelineItems: NSSet? { get }
    var coverUpdatedAt: Date? { get }
    var lastSyncedAt: Date? { get }
    var createdAt: Date? { get }
    var version: String? { get }
    var updatedAt: Date? { get }
    var type: String? { get }

    func getVideoUrl() -> String
}

public extension ReleaseContainer {
    var videoUrlOriginal: String {
        return getVideoUrl()
    }
}

// 扩展现有模型以遵循 TemplateListItem 协议
extension Template: TemplateContainer, TemplateListItem, ReleaseContainer {
    public func getIdentifier() -> String {
        return id ?? UUID().uuidString
    }

    public func getVersion() -> String {
        return version ?? ""
    }

    public func getVideoUrl() -> String {
        return ""
    }
}

extension VideoTemplate: TemplateContainer, TemplateListItem, ReleaseContainer {
    public func getIdentifier() -> String {
        return id ?? UUID().uuidString
    }
    
    public func getVersion() -> String {
        return version ?? ""
    }

    public func getVideoUrl() -> String {
        return videoUrlOriginal ?? ""
    }
}