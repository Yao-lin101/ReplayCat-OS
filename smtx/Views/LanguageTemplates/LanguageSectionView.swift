import SwiftUI

// 在文件开头添加 View 扩展
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// 展示模式枚举
enum TemplateListDisplayMode: String {
    case list
    case gallery
}

enum TemplateType: String {
    case localVideo
    case localTextImage
}

// 添加一个包装类型
struct IdentifiableReleaseContainer: Identifiable {
    let container: any ReleaseContainer
    var id: String { container.id ?? UUID().uuidString }
}

struct LanguageSectionView: View {
    let language: String
    @EnvironmentObject private var router: NavigationRouter
    @State private var templates: [Template] = []
    @State private var videoTemplates: [VideoTemplate] = []
    @State private var refreshTrigger = UUID()
    @AppStorage("templateListDisplayMode") private var displayMode: TemplateListDisplayMode = .list
    @State private var showingDeleteAlert = false
    @State private var templateToDelete: String?
    @State private var templateType: TemplateType = .localTextImage
    @State private var searchText = ""
    @State private var showingVideoInputAlert = false
    @State private var videoUrl = ""
    @State private var isParsingVideo = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var parsingStatus = "" // 添加解析状态文本
    @State private var isTextImageExpanded = true
    @State private var isVideoExpanded = true
    
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 180), spacing: 16)
    ]
    
    private var filteredTemplates: [Template] {
        if searchText.isEmpty {
            return templates
        }
        
        return templates.filter { template in
            if let title = template.title?.lowercased(),
               title.contains(searchText.lowercased()) {
                return true
            }
            
            let tags = TemplateStorage.shared.getTemplateTags(template)
            return tags.contains { tag in
                tag.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    // 添加计算属性来处理视频模板数组
    private var filteredvideoTemplates: [VideoTemplate] {
        if searchText.isEmpty {
            return videoTemplates
        }
        
        return videoTemplates.filter { template in
            // 标题搜索
            if let title = template.title?.lowercased(),
               title.contains(searchText.lowercased()) {
                return true
            }
            
            // 标签搜索
            if let tags = template.tags as? [String] {
                return tags.contains { tag in
                    tag.lowercased().contains(searchText.lowercased())
                }
            }
            
            return false
        }
    }

    
    // 在 本地页签是否展示分组
    private var shouldShowGroups: Bool {
        !filteredTemplates.isEmpty && !filteredvideoTemplates.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar

            switch displayMode {
                case .list:
                    listView
                case .gallery:
                    galleryView
            }
        }
        .id(refreshTrigger)
        .navigationTitle(language)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: toggleDisplayMode) {
                        Image(systemName: displayMode == .list ? "square.grid.2x2" : "list.bullet")
                    }
                    
                    Menu {
                        Button(action: {
                            if let section = try? TemplateStorage.shared.listLanguageSections().first(where: { $0.name == language }) {
                                router.navigate(to: .createTemplate(section.id ?? "", nil))
                            }
                        }) {
                            Label("图文模板", systemImage: "doc.text.image")
                        }
                        
                        Button(action: {
                            showingVideoInputAlert = true
                        }) {
                            Label("视频模板", systemImage: "video")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .confirmationDialog("所有模板和录音记录都将删除。", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
            Button("删除模板", role: .destructive) {
                if let templateId = templateToDelete {
                    deleteTemplate(templateId)
                }
                templateToDelete = ""
            }
            Button("取消", role: .cancel) {
                templateToDelete = ""
            }
        }
        .onAppear {
            refreshTemplates()
        }
        .toastManager()
        .sheet(isPresented: $showingVideoInputAlert) {
            VideoInputSheet(
                isPresented: $showingVideoInputAlert,
                videoUrl: $videoUrl,
                isParsingVideo: $isParsingVideo,
                parsingStatus: $parsingStatus
            ) {
                Task {
                    await parseVideo()
                }
            }
            .interactiveDismissDisabled(isParsingVideo)
        }
        .alert("解析失败", isPresented: $showingErrorAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var galleryView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if shouldShowGroups {
                    // 图文模板分组
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: { isTextImageExpanded.toggle() }) {
                            HStack {
                                Text("图文模板")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: isTextImageExpanded ? "chevron.down" : "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if isTextImageExpanded {
                            templateGalleryGrid(templates: filteredTemplates, type: .localTextImage)
                        }
                    }
                    
                    // 视频模板分组
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: { isVideoExpanded.toggle() }) {
                            HStack {
                                Text("视频模板")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: isVideoExpanded ? "chevron.down" : "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if isVideoExpanded {
                            templateGalleryGrid(templates: filteredvideoTemplates, type: .localVideo)
                        }
                    }
                } else {
                    // 只有一种类型的模板时直接显示
                    if !filteredTemplates.isEmpty {
                        templateGalleryGrid(templates: filteredTemplates, type: .localTextImage)
                    } else if !filteredvideoTemplates.isEmpty {
                        templateGalleryGrid(templates: filteredvideoTemplates, type: .localVideo)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var listView: some View {
        List {
            if shouldShowGroups {
                // 图文模板分组
                Section {
                    if isTextImageExpanded {
                        templateListRows(templates: filteredTemplates, type: .localTextImage)
                    }
                } header: {
                    Button(action: { isTextImageExpanded.toggle() }) {
                        HStack {
                            Text("图文模板")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: isTextImageExpanded ? "chevron.down" : "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                
                // 视频模板分组
                Section {
                    if isVideoExpanded {
                        templateListRows(templates: filteredvideoTemplates, type: .localVideo)
                    }
                } header: {
                    Button(action: { isVideoExpanded.toggle() }) {
                        HStack {
                            Text("视频模板")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: isVideoExpanded ? "chevron.down" : "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } else {
                // 只有一种类型的模板时直接显示
                if !filteredTemplates.isEmpty {
                    templateListRows(templates: filteredTemplates, type: .localTextImage)
                } else if !filteredvideoTemplates.isEmpty {
                    templateListRows(templates: filteredvideoTemplates, type: .localVideo)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索标题或标签", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private func templateContextMenu<T: ReleaseContainer>(for template: T) -> some View {
        Group {
            editButton(for: template)
            
            Button(role: .destructive) {
                templateToDelete = template.id
                showingDeleteAlert = true
                templateType = template is VideoTemplate ? .localVideo : .localTextImage
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
    
    private func toggleDisplayMode() {
        withAnimation {
            displayMode = displayMode == .list ? .gallery : .list
        }
    }
    
    private func loadTemplates() -> Bool{
        do {
            let allTemplates = try TemplateStorage.shared.listTemplatesByLanguage()
            let newTemplates = (allTemplates[language] ?? []).filter { template in
                guard let version = template.version else { return false }
                return version != "1.0"
            }
            let allvideoTemplates = try TemplateStorage.shared.listVideoTemplatesByLanguage()
            let newVideoTemplates = (allvideoTemplates[language] ?? []).filter { template in
                guard let version = template.version else { return false }
                return version != "1.0"
            }
            
            // 强制更新列表和刷新触发器
            templates = newTemplates
            videoTemplates = newVideoTemplates
            refreshTrigger = UUID()
            return templates.isEmpty && videoTemplates.isEmpty
        } catch {
            return true
        }
    }
    
    private func deleteTemplate(_ templateId: String) {
        do {
            switch templateType {
                case .localVideo:
                    try TemplateStorage.shared.deleteVideoTemplate(templateId: templateId)
                case .localTextImage:
                    try TemplateStorage.shared.deleteTemplate(templateId: templateId)
            }
            refreshTemplates()
            print("✅ Template deleted and list reloaded: \(templateId)")
        } catch {
            print("❌ Failed to delete template: \(error)")
        }
    }
    
    private func refreshTemplates() {
        _ = loadTemplates()
    }
    
    private func parseVideo() async {
        guard !videoUrl.isEmpty else { return }
        
        isParsingVideo = true
        parsingStatus = "正在解析链接..."
        
        do {
            parsingStatus = "正在获取视频信息..."
            let videoInfo = try await VideoParserService.shared.parseVideo(videoUrl)
            
            parsingStatus = "解析成功，正在打开编辑器..."
            if let section = try? TemplateStorage.shared.listLanguageSections().first(where: { $0.name == language }) {
                // 延迟一小段时间以显示成功状态
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
                
                // 清理状态并关闭弹窗
                parsingStatus = ""
                isParsingVideo = false
                showingVideoInputAlert = false
                
                // 导航到创建页面
                router.navigate(to: .createVideoTemplate(section.id ?? "", nil, videoInfo, videoUrl))
                videoUrl = ""
            }
        } catch let error as VideoParseError {
            parsingStatus = "解析失败：\(error.localizedDescription)"
            // 显示错误状态一段时间后重置
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
            parsingStatus = ""
            isParsingVideo = false
        } catch {
            parsingStatus = "解析失败：\(error.localizedDescription)"
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
            parsingStatus = ""
            isParsingVideo = false
        }
    }

    // 修改模板网格视图组件
    private func templateGalleryGrid<T: TemplateListItem & ReleaseContainer>(templates: [T], type: TemplateType) -> some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(templates) { template in
                NavigationLink(value: Route.templateDetail(template.getIdentifier(), type)) {
                    let templateRowInfo = TemplateRowInfo(
                        coverImage: template.coverImage,
                        title: template.title,
                        totalDuration: template.totalDuration,
                        tags: template.tags
                    )
                    GalleryTemplateRow(template: templateRowInfo)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    templateContextMenu(for: template)
                }
            }
        }
    }

    // 修改模板列表行组件
    private func templateListRows<T: TemplateListItem & ReleaseContainer>(templates: [T], type: TemplateType) -> some View {
        ForEach(templates) { template in
            NavigationLink(value: Route.templateDetail(template.getIdentifier(), type)) {
                let templateRowInfo = TemplateRowInfo(
                    coverImage: template.coverImage,
                    title: template.title,
                    totalDuration: template.totalDuration,
                    tags: template.tags
                )
                TemplateRow(template: templateRowInfo)
                    .id("\(template.getIdentifier())_\(template.updatedAt?.timeIntervalSince1970 ?? 0)")
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button {
                    templateToDelete = template.getIdentifier()
                    showingDeleteAlert = true
                    self.templateType = type
                } label: {
                    Label("删除", systemImage: "trash")
                }
                .tint(.red)
                
                editButton(for: template)
            }
        }
    }

    // 修改编辑按钮方法
    private func editButton<T: ReleaseContainer>(for template: T) -> some View {
        Button {
            if let section = try? TemplateStorage.shared.listLanguageSections().first(where: { $0.name == language }),
               let templateId = template.id {
                if let videoTemplate = template as? VideoTemplate,
                   let videoInfo = VideoInfo.fromJSONString(videoTemplate.videoInfo ?? "") {
                    router.navigate(to: .createVideoTemplate(section.id ?? "", templateId, videoInfo, nil))
                } else {
                    router.navigate(to: .createTemplate(section.id ?? "", templateId))
                }
            }
        } label: {
            Label("编辑", systemImage: "pencil")
        }
        .tint(.blue)
    }
}

