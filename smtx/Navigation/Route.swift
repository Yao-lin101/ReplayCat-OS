import Foundation

enum Route: Hashable, Identifiable {
    /// 语言分区页面
    case languageSection(String)
    /// 模板详情页面
    case templateDetail(String, TemplateType)
    /// 创建/编辑模板页面
    /// - Parameters:
    ///   - sectionId: 语言分区ID
    ///   - templateId: 模板ID（编辑时使用）
    case createTemplate(String, String?)
    // 添加视频模板创建路由
    case createVideoTemplate(String, String?, VideoInfo?, String?)
    /// 录音页面
    case recording(String, String?, TemplateType)
    
    
    // 个人中心路由
    case profile
    case settings
    case about
    case help
    case cacheCleaning  // 添加缓存清理路由
    
    var id: String {
        switch self {
        case .languageSection(let language):
            return "languageSection-\(language)"
        case .templateDetail(let templateId, let templateType):
            return "templateDetail-\(templateId)-\(templateType)"
        case .createTemplate(let language, let templateId):
            return "createTemplate-\(language)-\(templateId ?? "new")"
        case .recording(let templateId, let recordId, let templateType):
            return "recording-\(templateId)-\(recordId ?? "new")-\(templateType)"
        case .profile:
            return "profile"
        case .settings:
            return "settings"
        case .about:
            return "about"
        case .help:
            return "help"
        case .createVideoTemplate(let sectionId, let templateId, let videoInfo, _):
            return "createVideoTemplate-\(sectionId)-\(templateId ?? "new")-\(videoInfo?.originalId ?? "none")"
        case .cacheCleaning:
            return "cacheCleaning"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .languageSection(let language):
            hasher.combine(0)
            hasher.combine(language)
        case .templateDetail(let templateId, let templateType):
            hasher.combine(1)
            hasher.combine(templateId)
            hasher.combine(templateType)
        case .createTemplate(let language, let templateId):
            hasher.combine(2)
            hasher.combine(language)
            hasher.combine(templateId)
        case .recording(let templateId, let recordId, let templateType):
            hasher.combine(3)
            hasher.combine(templateId)
            hasher.combine(recordId)
            hasher.combine(templateType)
        case .profile:
            hasher.combine(4)
        case .settings:
            hasher.combine(6)
        case .about:
            hasher.combine(7)
        case .help:
            hasher.combine(8)
        case .createVideoTemplate(let sectionId, let templateId, let videoInfo, let originalUrl):
            hasher.combine(20)
            hasher.combine(sectionId)
            hasher.combine(templateId)
            if let videoInfo = videoInfo {
                hasher.combine(videoInfo.originalId)
            }
            hasher.combine(originalUrl)
        case .cacheCleaning:
            hasher.combine(21)
        }
    }
    
    static func == (lhs: Route, rhs: Route) -> Bool {
        switch (lhs, rhs) {
        case (.languageSection(let l), .languageSection(let r)):
            return l == r
        case (.templateDetail(let l, let lIsCloudTemplate), .templateDetail(let r, let rIsCloudTemplate)):
            return l == r && lIsCloudTemplate == rIsCloudTemplate
        case (.createTemplate(let l1, let l2), .createTemplate(let r1, let r2)):
            return l1 == r1 && l2 == r2
        case (.recording(let l1, let l2, let l3), .recording(let r1, let r2, let r3)):
            return l1 == r1 && l2 == r2 && l3 == r3
        case (.profile, .profile),
             (.settings, .settings),
             (.about, .about),
             (.help, .help):
            return true
        case (.createVideoTemplate(let l1, let l2, let l3, let l4), 
              .createVideoTemplate(let r1, let r2, let r3, let r4)):
            return l1 == r1 && l2 == r2 && l3?.originalId == r3?.originalId && l4 == r4
        case (.cacheCleaning, .cacheCleaning):
            return true
        default:
            return false
        }
    }
    
    var title: String {
        switch self {
        case .languageSection(let language):
            return language
        case .templateDetail:
            return "模板详情"
        case .createTemplate(_, let templateId):
            return templateId == nil ? "创建模板" : "编辑模板"
        case .recording:
            return "录音"
        case .profile:
            return "个人中心"
        case .settings:
            return "设置"
        case .about:
            return "关于"
        case .help:
            return "帮助"
        case .createVideoTemplate(_, let templateId, _, _):
            return templateId == nil ? "创建视频模板" : "编辑视频模板"
        case .cacheCleaning:
            return "缓存清理"
        }
    }
} 
