import SwiftUI

struct LocalRecordingView: View {
    let templateId: String
    let recordId: String?
    let templateType: TemplateType
    @StateObject private var templateViewModel = LocalTemplateViewModel.shared
    
    var body: some View {
        Group {
            switch templateType {
                case .localTextImage:
                    if let template = templateViewModel.template {
                        BaseRecordingView(
                            timelineProvider: LocalTimelineProvider(template: template),
                            delegate: LocalRecordingDelegate(template: template),
                            recordId: recordId,
                            isUploading: false
                        )
                    } else {
                        ProgressView()
                    }
                case .localVideo: 
                    if let template = templateViewModel.videoTemplate,
                       let videoPath = template.videoUrlLocal {
                        let videoUrl = VideoFileManager.shared.getVideoUrl(for: videoPath)
                        BaseRecordingView(
                            timelineProvider: LocalVideoTimelineProvider(template: template),
                            delegate: LocalVideoRecordingDelegate(template: template),
                            recordId: recordId,
                            isUploading: false,
                            isVideo: true,
                            videoUrl: videoUrl
                        )
                    } else {
                        ProgressView()
                    }
            }
        }
        .onAppear {
            templateViewModel.loadTemplateIfNeeded(
                templateId: templateId, 
                templateType: templateType,
                loadMethod: .normal
            )
        }
    }
}
