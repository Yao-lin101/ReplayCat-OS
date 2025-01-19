import Foundation
import SwiftUI

@MainActor
class LocalTemplateViewModel: ObservableObject {
    // 添加单例
    static let shared = LocalTemplateViewModel()
    
    @Published var template: Template?
    @Published var videoTemplate: VideoTemplate?
    @Published var templateContainer: TemplateContainer?
    @Published var isLoading = false
    @Published var error: Error?
    
    // 使用单例
    
    private var loadedTemplateId: String?
    private var loadedOperationType: TemplateType?
    
    // 私有化初始化方法
    private init() {}
    
    enum LoadMethod {
        case normal           // 普通加载
        case findByCloudId   // 通过云端ID查找本地模板
    }
    
    func loadTemplateIfNeeded(templateId: String, templateType: TemplateType, loadMethod: LoadMethod = .normal) {
        // 如果已经加载了相同的模板，则不重复加载
        guard templateId != loadedTemplateId || templateType != loadedOperationType else {
            return
        }
        
        loadedTemplateId = templateId
        loadedOperationType = templateType
        
        Task {
            await loadTemplate(templateId: templateId, templateType: templateType, loadMethod: loadMethod)
        }
    }
    
    private func loadTemplate(templateId: String, templateType: TemplateType, loadMethod: LoadMethod) async {
        isLoading = true
        error = nil
        
        do {
            switch templateType {
            case .localTextImage:
                template = try TemplateStorage.shared.loadTemplate(templateId: templateId)
                
                templateContainer = template

            case .localVideo:
                videoTemplate = try TemplateStorage.shared.loadVideoTemplate(templateId: templateId).0

                templateContainer = videoTemplate
            }
        } catch {
            self.error = error
            print("Error loading template: \(error)")
        }
        
        isLoading = false
    }
    
    func updateTemplate(_ updatedTemplate: Template) {
        if updatedTemplate.id == loadedTemplateId {
            template = updatedTemplate
        }
    }
    
    func clearTemplate() {
        template = nil
        videoTemplate = nil
        loadedTemplateId = nil
        loadedOperationType = nil
        error = nil
    }
}
