import SwiftUI

struct MainTabView: View {
    @StateObject private var localRouter = NavigationRouter()   // 本地模板的路由
    @StateObject private var profileRouter = NavigationRouter() // 个人中心的路由
    @State private var selectedTab = 1  // 默认选中本地模板页
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // 本地模板页
            NavigationStack(path: $localRouter.path) {
                LocalTemplatesView()
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .languageSection(let language):
                            LanguageSectionView(language: language)
                        case .templateDetail(let templateId, let templateType):
                            TemplateDetailView(templateId: templateId, templateType: templateType)
                        case .createTemplate(let sectionId, let templateId):
                            CreateTemplateView(sectionId: sectionId, existingTemplateId: templateId)
                        case .createVideoTemplate(let sectionId, let templateId, let videoInfo, let originalUrl):
                            CreateVideoTemplateView(
                                sectionId: sectionId,
                                existingTemplateId: templateId,
                                videoInfo: videoInfo,
                                originalUrl: originalUrl
                            )
                        case .recording(let templateId, let recordId, let templateType):
                            LocalRecordingView(templateId: templateId, recordId: recordId, templateType: templateType)
                        case .profile, .settings, .help, .about, .cacheCleaning:
                            // 这些路由在本地模板页面不需要处理
                            EmptyView()
                        }
                    }
            }
            .environmentObject(localRouter)  // 本地模板使用 localRouter
            .tabItem {
                Label("本地", systemImage: "folder")
            }
            .tag(1)
            
            // 个人中心
            NavigationStack(path: $profileRouter.path) {
                ProfileView()
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .settings:
                            SettingsView()
                        case .help:
                            HelpView()
                        case .about:
                            AboutView()
                        case .cacheCleaning:
                            CacheCleaningView()
                        case .languageSection, .templateDetail, .createTemplate, .recording,
                             .profile, .createVideoTemplate:
                            // 这些路由在个人中心不需要处理
                            EmptyView()
                        }
                    }
            }
            .environmentObject(profileRouter)  // 个人中心使用 profileRouter
            .tabItem {
                Label("我的", systemImage: "person")
            }
            .tag(2)
        }
    }
}

#Preview {
    MainTabView()
} 
