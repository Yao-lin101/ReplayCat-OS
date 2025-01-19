import SwiftUI

struct VideoInfoSectionView: View {
	let videoInfo: VideoInfo?

	var body: some View {
		Group {
			if let videoInfo = videoInfo {
				VStack(alignment: .leading, spacing: 8) {
					Text("视频信息")
						.font(.subheadline)
						.foregroundColor(.secondary)
					
					VStack(alignment: .leading, spacing: 4) {
						HStack {
							Text("平台：")
								.foregroundColor(.secondary)
							switch videoInfo.platform {
							case .bilibili:
								Text("哔哩哔哩")
							case .douyin:
								Text("抖音")
							case .kuaishou:
								Text("快手")
							}
						}
						
						if let authorName = videoInfo.authorName {
							HStack {
								Text("作者：")
									.foregroundColor(.secondary)
								Text(authorName)
							}
						}
						
						HStack {
							Text("视频ID：")
								.foregroundColor(.secondary)
							Text(videoInfo.originalId)
						}
					}
					.font(.footnote)
					.padding(12)
					.frame(maxWidth: .infinity, alignment: .leading)
					.background(Color(.systemBackground))
					.cornerRadius(8)
				}
			}
		}
	}
}