import SwiftUI
import PhotosUI
import UIKit
import CoreData

struct VideoTimelineEditorView: View {
    let templateId: String
    let totalDuration: Double
    let videoUrl: URL
    @Environment(\.dismiss) private var dismiss
    @Binding var timelineItems: [TimelineItemData]
    
    // 编辑状态
    @State private var currentTime: Double = 0
    @State private var beforeTime: Double = -1
    @State private var hasOldItem = false
    @State private var script = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var previewImage: Image?
    @State private var originalImage: UIImage?
    @State private var originalImageData: Data?
    @State private var tempUIImage: UIImage?
    @State private var isEditing = false
    @State private var pickerUpdateId = UUID()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 表单区域
                VStack(spacing: 12) {
                    // 替换原来的图片选择器为视频播放器
                    VideoPlayerView(
                        url: videoUrl,
                        currentTime: $currentTime,
                        aspectRatio: 16/9
                    )
                    
                    // 台词输入框
                    TextField("输入台词", text: $script)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)
                
                // 时间轴
                HStack {
                    Spacer()
                    HorizontalTimePickerView(
                        selectedSeconds: $currentTime,
                        maxDuration: totalDuration,
                        step: 1,
                        markedPositions: timelineItems.map { $0.timestamp }.sorted()
                    )
                    Spacer()
                }
                .padding(.horizontal)
                
                // 添加/更新/编辑按钮区域
                HStack(spacing: 16) {
                    if hasOldItem {
                        if isEditing {
                            // 更新按钮
                            Button(action: addOrUpdateTimelineItem) {
                                Text("更新")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(script.isEmpty && originalImage == nil)
                        } else {
                            // 编辑按钮
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isEditing = true
                                    beforeTime = currentTime
                                }
                            }) {
                                Text("编辑")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        // 添加按钮
                        Button(action: addOrUpdateTimelineItem) {
                            Text("添加")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(script.isEmpty && originalImage == nil)
                    }
                }
                .padding(.horizontal)
                
                // 已添加内容列表
                List {
                    ForEach(timelineItems.sorted(by: { $0.timestamp < $1.timestamp })) { item in
                        TimelineItemRow(
                            item: item,
                            isSelected: item.timestamp == currentTime
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            currentTime = item.timestamp
                            loadTimelineItem(item)
                            isEditing = false
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: deleteTimelineItem)
                }
                .listStyle(.plain)
            }
            .navigationTitle("编辑时间轴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedImage) { newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        tempUIImage = uiImage
                        selectedImage = nil
                    }
                }
            }
            .onChange(of: currentTime) { newTime in
                if !isEditing{
                    // 时间轴滑动时，加载对应时间点的内容
                    if let item = timelineItems.first(where: { $0.timestamp == newTime }) {
                        // 加载现有项目的内容
                        loadTimelineItem(item)
                        isEditing = false
                        hasOldItem = true
                    } else {
                        // 清空表单内容
                        clearForm()
                        hasOldItem = false
                    }
                }

            }
            .onAppear {
                // 检查 0.0 秒位置是否有内容
                if let initialItem = timelineItems.first(where: { $0.timestamp == 0.0 }) {
                    loadTimelineItem(initialItem)
                    isEditing = false
                    hasOldItem = true
                }
            }
            .toastManager()
        }
    }
    
    private func loadTimelineItem(_ item: TimelineItemData) {
        // 清空之前的状态
        clearForm()
        
        // 加载新的内容
        script = item.script
        if let imageData = item.imageData {
            // 保存原始图片数据
            originalImageData = imageData
            if let uiImage = UIImage(data: imageData) {
                originalImage = uiImage
                previewImage = Image(uiImage: uiImage)
            }
        }
    }
    
    private func clearForm() {
        script = ""
        originalImage = nil
        originalImageData = nil
        previewImage = nil
    }
    
    private func addOrUpdateTimelineItem() {
        do {
            _ = try TemplateStorage.shared.loadVideoTemplate(templateId: templateId)
            
            // 获取当前时间点的视频帧
            let frameImage = VideoFileManager.shared.getVideoFrame(from: videoUrl.path, at: currentTime)
            let frameData = frameImage?.jpegData(compressionQuality: 0.1)
            
            // 如果是更新现有项目
            if let index = timelineItems.firstIndex(where: { $0.timestamp == beforeTime }) {
                var updatedItem = timelineItems[index]
                
                //检查是否时间点是否有其他项目
                let otherItems = timelineItems.filter { $0.timestamp == currentTime }
                if otherItems.count > 0 && otherItems[0].id != updatedItem.id {
                    ToastManager.shared.show("一个时间点只能有一个项目")
                    currentTime = beforeTime
                    return
                }

                // 检查脚本是否变化
                if updatedItem.script != script {
                    updatedItem.script = script
                    updatedItem.updatedAt = Date()
                }
                
                // 更新视频帧图片
                if let newFrameData = frameData {
                    updatedItem.imageData = newFrameData
                    updatedItem.imageUpdatedAt = Date()
                }

                // 检查时间节点是否变化
                if updatedItem.timestamp != currentTime {
                    updatedItem.timestamp = currentTime
                    updatedItem.updatedAt = Date()
                }
                
                timelineItems[index] = updatedItem
            } else {
                // 添加新项目
                let newItem = TimelineItemData(
                    id: UUID().uuidString,
                    script: script,
                    imageData: frameData,
                    timestamp: currentTime,
                    createdAt: Date(),
                    updatedAt: Date(),
                    imageUpdatedAt: frameData != nil ? Date() : nil
                )
                timelineItems.append(newItem)
            }
            
            // 强制视图刷新
            timelineItems = timelineItems.sorted { $0.timestamp < $1.timestamp }
            pickerUpdateId = UUID()
            
            // 检查是否在最后1秒内
            let isLastSecond = totalDuration - currentTime <= 0
            
            if !isLastSecond{
                // 如果不在最后1秒，清空表单
                clearForm()
                // 计算下一个时间点（当前时间+3秒，但不超过总时长）
                let nextTime = min(currentTime + 3, totalDuration)
                // 如果下一个时间点和当前时间不同，才更新
                if nextTime != currentTime {
                    currentTime = nextTime
                }
            }else{
                hasOldItem = true
            }
            isEditing = false
            beforeTime = -1
        } catch {
            print("Error saving timeline item: \(error)")
        }
    }
    
    private func deleteTimelineItem(at offsets: IndexSet) {
        let sortedItems = timelineItems.sorted(by: { $0.timestamp < $1.timestamp })
        for index in offsets {
            let item = sortedItems[index]
            if let itemIndex = timelineItems.firstIndex(where: { $0.id == item.id }) {
                timelineItems.remove(at: itemIndex)
            }
        }
        pickerUpdateId = UUID()
    }
    
    // 时间轴项目行视图
    private struct TimelineItemRow: View {
        let item: TimelineItemData
        var isSelected: Bool
        
        var body: some View {
            HStack(spacing: 12) {
                // 左侧：图片
                if let imageData = item.imageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 68) // 16:9 比例
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 120, height: 68)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        }
                }
                
                // 右侧：台词和时间节点
                VStack(alignment: .leading, spacing: 4) {
                    if !item.script.isEmpty {
                        Text(item.script)
                            .font(.body)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Text(String(format: "%.1f秒", item.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 0)
            }
            .frame(height: 80) // 固定行高
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(UIColor.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
    }
    
    private func getImageForCurrentTime() -> UIImage? {
        // 在视频模式下，这个方法可能不再需要
        // 或者可以修改为从视频中提取当前帧
        return nil
    }
}
