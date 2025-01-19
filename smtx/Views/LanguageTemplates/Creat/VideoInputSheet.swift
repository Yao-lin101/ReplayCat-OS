import SwiftUI
// 添加一个视频链接输入表单视图
struct VideoInputSheet: View {
    @Binding var isPresented: Bool
    @Binding var videoUrl: String
    @Binding var isParsingVideo: Bool
    @Binding var parsingStatus: String
    let onSubmit: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("请输入视频链接", text: $videoUrl)
                        .disabled(isParsingVideo)
                } header: {
                    if isParsingVideo {
                        Text(parsingStatus)
                            .foregroundColor(.blue)
                    } else if !videoUrl.isEmpty {
                        if let platform = VideoParserService.shared.detectPlatform(videoUrl) {
                            switch platform {
                            case .bilibili:
                                Text("已识别为B站视频链接")
                            case .douyin:
                                Text("已识别为抖音视频链接")
                            case .kuaishou:
                                Text("已识别为快手视频链接")
                            }
                        } else {
                            Text("暂不支持该平台或链接无效")
                        }
                    } else {
                        Text("支持B站、抖音等平台的视频链接")
                    }
                }
            }
            .navigationTitle("输入视频链接")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        videoUrl = ""
                        parsingStatus = ""
                        isParsingVideo = false
                        isPresented = false
                    }
                    .disabled(isParsingVideo)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isParsingVideo {
                        Text("解析中...")
                            .foregroundColor(.secondary)
                    } else {
                        Button("确定") {
                            if !videoUrl.isEmpty {
                                onSubmit()
                            }
                        }
                        .disabled(videoUrl.isEmpty)
                    }
                }
            }
        }
    }
}
