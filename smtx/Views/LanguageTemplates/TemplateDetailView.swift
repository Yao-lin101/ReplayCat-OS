import SwiftUI
import CoreData

// 添加页签枚举
enum TemplateDetailTab: Int {
    case cloudRecordings = 0
    case local = 1
    case comments = 2
}


struct TemplateDetailView: View {
    let templateId: String
    let templateType: TemplateType
    @EnvironmentObject private var router: NavigationRouter
    @StateObject private var templateViewModel = LocalTemplateViewModel.shared
    @State private var refreshTrigger = UUID()
    @State private var showingDeleteAlert = false
    @State private var selectedTab = 1
    
    var body: some View {
        VStack(spacing: 0) {
            if templateViewModel.isLoading {
                ProgressView()
            } else {
                if let template = templateViewModel.templateContainer {
                    TemplateContent(
                        template: template,
                        selectedTab: $selectedTab,
                        templateId: templateId,
                        templateType: templateType
                    )
                }
            }
        }
        .navigationTitle(templateViewModel.templateContainer?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            templateViewModel.loadTemplateIfNeeded(templateId: templateId, templateType: templateType)
        }
        .toastManager()
    }
}

// MARK: - 共享的工具函数和视图
private struct SharedViews {
    static func coverImageSection(_ template: TemplateContainer) -> some View {
        Group {
            if let imageData = template.coverImage,
                let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    @MainActor
    static func recordListSection<T: RecordInterface>(
        _ records: [T],
        templateId: String,
        templateType: TemplateType,
        router: NavigationRouter,
        onDelete: @escaping (T) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(records.sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }, id: \.id) { record in
                        RecordRow(record: record)
                            .onTapGesture {
                                if let recordId = record.id {
                                    router.navigate(to: .recording(templateId, recordId, templateType))
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    onDelete(record)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - 标签页内容视图
private struct TabContentView: View {
    @Binding var selectedTab: Int
    let templateId: String
    let templateType: TemplateType
    @EnvironmentObject private var router: NavigationRouter
    let template: TemplateContainer?
    @State private var showingRecordingPreview = false
    @State private var showingCommentSheet = false
    @State private var newComment = ""
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        VStack {
            // 内容区域
            ScrollView {
                recordingContent
            }
        }
    }
    
    // 提取录音内容到单独的 View
    private var recordingContent: some View {
        VStack(spacing: 20) {
            localRecordingButton
            
            if let records = template?.records?.allObjects as? [Record],
               !records.isEmpty {
                SharedViews.recordListSection(
                    records,
                    templateId: templateId,
                    templateType: templateType,
                    router: router
                ) { record in
                    do {
                        try TemplateStorage.shared.deleteRecord(record.id ?? "")
                        refreshTrigger = UUID()
                    } catch {
                        print("❌ Failed to delete record: \(error)")
                    }
                }
            } else {
                Text("暂无本地记录")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .id(refreshTrigger)
    }
    
    private var localRecordingButton: some View {
        Button(action: {
            Task { @MainActor in
                router.navigate(to: .recording(templateId, nil, templateType))
            }
        }) {
            HStack {
                Image(systemName: "mic.circle.fill")
                    .font(.title2)
                Text("开始练习")
                    .font(.headline)
            }
            .foregroundColor(.accentColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}
// MARK: - 模板内容视图
private struct TemplateContent: View {
    let template: TemplateContainer
    @Binding var selectedTab: Int
    let templateId: String
    let templateType: TemplateType
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 封面图片
                SharedViews.coverImageSection(template)
                
                // 时间轴预览
                if let timelineItems = getTimelineItems() {
                    TimelinePreviewView(
                        timelineItems: timelineItems,
                        totalDuration: template.totalDuration
                    )
                }
                
                // 标签页和按钮
                TabContentView(
                    selectedTab: $selectedTab,
                    templateId: templateId,
                    templateType: templateType,
                    template: template
                )
            }
            .padding()
        }
    }
    
    private func getTimelineItems() -> [TimelineItemData]? {
        if let timelineItems = template.timelineItems?.allObjects as? [TimelineItem],
            !timelineItems.isEmpty {
            return timelineItems.map { item in
                TimelineItemData(
                    id: item.id ?? "",
                    script: item.script ?? "",
                    imageData: item.image,
                    timestamp: item.timestamp,
                    createdAt: item.createdAt ?? Date(),
                    updatedAt: item.updatedAt ?? Date()
                )
            }
        }
        return nil
    }
}
