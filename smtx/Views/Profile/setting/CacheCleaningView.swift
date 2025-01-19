import SwiftUI

struct CacheCleaningView: View {
    @State private var isCleaningImage = false
    @State private var isCleaningRecording = false
    @State private var isCleaningTimeline = false
    @State private var isCleaningVideo = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var imageCacheSize: Int64 = 0
    @State private var recordingCacheSize: Int64 = 0
    @State private var timelineCacheSize: Int = 0
    @State private var videoCacheSize: Int64 = 0
    
    private func updateCacheSizes() {
        Task {
            // 获取图片缓存大小
            imageCacheSize = ImageCacheManager.shared.getCacheSize()
            
            // 获取未使用的视频缓存大小
            do {
                videoCacheSize = try TemplateStorage.shared.getUnusedVideoCacheSize()
            } catch {
                print("❌ 获取视频缓存大小失败: \(error)")
                videoCacheSize = 0
            }
        }
    }
    
    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    var body: some View {
        List {
            // 图片缓存
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("图片缓存")
                            .font(.headline)
                        Text("清理模板封面和时间轴图片缓存")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatSize(imageCacheSize))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        cleanImageCache()
                    } label: {
                        if isCleaningImage {
                            ProgressView()
                        } else {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(isCleaningImage)
                }
            }
            
            // 视频缓存
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("视频缓存")
                            .font(.headline)
                        Text("清理未使用的视频文件")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatSize(videoCacheSize))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        cleanVideoCache()
                    } label: {
                        if isCleaningVideo {
                            ProgressView()
                        } else {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(isCleaningVideo)
                }
            }
        }
        .navigationTitle("缓存清理")
        .toastManager()
        .onAppear {
            updateCacheSizes()
        }
    }
    
    private func cleanImageCache() {
        isCleaningImage = true
        
        Task {
            ImageCacheManager.shared.clearCache()
            
            await MainActor.run {
                isCleaningImage = false
                updateCacheSizes()
                ToastManager.shared.show("图片缓存已清理")
            }
        }
    }
    
    private func cleanVideoCache() {
        isCleaningVideo = true
        
        Task {
            do {
                try TemplateStorage.shared.cleanupUnusedVideos()
                
                await MainActor.run {
                    isCleaningVideo = false
                    updateCacheSizes()
                    ToastManager.shared.show("视频缓存已清理")
                }
            } catch {
                await MainActor.run {
                    isCleaningVideo = false
                    ToastManager.shared.show("视频缓存清理失败", type: .error)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CacheCleaningView()
    }
}
