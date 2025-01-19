import SwiftUI

@MainActor
class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()
    @Published var sheet: Route?
    @Published var fullScreenCover: Route?
    @Published var currentRoute: Route = .languageSection("")
    
    func navigate(to route: Route) {
        currentRoute = route
        path.append(route)
    }
    
    func navigateBack() {
        path.removeLast()
    }
    
    func navigate(to route: Route, presentAsSheet: Bool) {
        switch route {
        default:
            path.append(route)
        }
        
        if let last = (path as Any as? [Route])?.last {
            currentRoute = last
        } else {
            currentRoute = .languageSection("")
        }
    }
    
    func dismiss() {
        sheet = nil
        fullScreenCover = nil
    }
    
    func pop() {
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .languageSection(let language):
            LanguageSectionView(language: language)
        case .templateDetail(let templateId, let templateType):
            TemplateDetailView(templateId: templateId, templateType: templateType)
        case .createTemplate(let sectionId, let templateId):
            CreateTemplateView(sectionId: sectionId, existingTemplateId: templateId)
        case .createVideoTemplate(let sectionId, let templateId, let videoInfo, _):
            CreateVideoTemplateView(
                sectionId: sectionId,
                existingTemplateId: templateId,
                videoInfo: videoInfo
            )
        case .recording(let templateId, let recordId, let templateType):
            LocalRecordingView(templateId: templateId, recordId: recordId, templateType: templateType)
        case .profile:
            ProfileView()
        case .settings:
            SettingsView()
        case .about:
            AboutView()
        case .help:
            HelpView()
        case .cacheCleaning:
            CacheCleaningView()
        }
    }
} 
