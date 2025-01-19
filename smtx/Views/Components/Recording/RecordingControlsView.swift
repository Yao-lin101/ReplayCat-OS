import SwiftUI
import AVFoundation

struct RecordingControlsView: View {
    enum Mode {
        case recording
        case preview
    }
    
    let mode: Mode
    let isRecording: Bool
    let isPlaying: Bool
    let onRecordTap: () -> Void
    let onPlayTap: () -> Void
    let onBackward: () -> Void
    let onForward: () -> Void
    let onDelete: () -> Void
    let onDismiss: () -> Void
    var onUpload: (() -> Void)?
    let isUploading: Bool
    let showDeleteButton: Bool
    let showUploadButton: Bool
    
    var body: some View {
        HStack(spacing: 40) {
            if mode == .preview {
                Group {
                    // 删除按钮
                    if showDeleteButton {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // 后退10秒
                    Button(action: onBackward) {
                        Image(systemName: "gobackward.10")
                            .font(.title)
                    }
                    
                    // 播放/暂停按钮
                    Button(action: onPlayTap) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                    }
                    
                    // 前进10秒
                    Button(action: onForward) {
                        Image(systemName: "goforward.10")
                            .font(.title)
                    }
                    
                    // 完成按钮
                    if showUploadButton {
                        Button(action: {
                            if let onUpload = onUpload {
                                onUpload()
                            } else {
                                onDismiss()
                            }
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(isUploading ? .gray : .blue)
                        }
                        .disabled(isUploading)
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.3)
                        .combined(with: .opacity)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7)),
                    removal: .scale(scale: 0.3)
                        .combined(with: .opacity)
                        .animation(.easeOut(duration: 0.2))
                ))
            } else {
                // 录音按钮
                Button(action: onRecordTap) {
                    Circle()
                        .fill(isRecording ? .red : .accentColor)
                        .frame(width: 80, height: 80)
                        .overlay {
                            RoundedRectangle(cornerRadius: isRecording ? 4 : 40)
                                .fill(Color.white)
                                .frame(width: isRecording ? 30 : 30,
                                     height: isRecording ? 30 : 30)
                        }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.3)
                        .combined(with: .opacity)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7)),
                    removal: .scale(scale: 0.3)
                        .combined(with: .opacity)
                        .animation(.easeOut(duration: 0.2))
                ))
            }
        }
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8),
            value: mode
        )
    }
} 