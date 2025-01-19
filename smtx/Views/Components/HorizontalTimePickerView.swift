import SwiftUI
import UIKit

struct HorizontalTimePickerView: View {
    @Binding var selectedSeconds: Double
    let maxDuration: Double
    let step: Double
    let markedPositions: [Double]
    
    var body: some View {
        TimePickerRepresentable(
            selectedSeconds: $selectedSeconds,
            maxDuration: maxDuration,
            step: step,
            markedPositions: markedPositions
        )
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .id(markedPositions.hashValue)
    }
}

// 添加一个容器视图来限制触摸区域
private class PickerContainerView: UIView {
    let pickerView: UIPickerView
    
    init(pickerView: UIPickerView) {
        self.pickerView = pickerView
        super.init(frame: .zero)
        addSubview(pickerView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        pickerView.frame = bounds
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        // 只有当触摸点在容器视图内部时才响应
        return view == self ? pickerView : view
    }
}

private struct TimePickerRepresentable: UIViewRepresentable {
    @Binding var selectedSeconds: Double
    let maxDuration: Double
    let step: Double
    let markedPositions: [Double]
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let picker = UIPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.transform = CGAffineTransform(rotationAngle: -(.pi / 2))
        
        // 设置初始选中位置
        let initialRow = Int(selectedSeconds / step)
        picker.selectRow(initialRow, inComponent: 0, animated: false)
        
        // 使用容器视图包装 UIPickerView
        let containerView = PickerContainerView(pickerView: picker)
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let containerView = uiView as? PickerContainerView else { return }
        let picker = containerView.pickerView
        
        // 强制刷新所有行
        picker.reloadAllComponents()
        
        let targetRow = Int(selectedSeconds / step)
        if targetRow != picker.selectedRow(inComponent: 0) {
            picker.selectRow(targetRow, inComponent: 0, animated: true)
        }
    }
    
    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        private let parent: TimePickerRepresentable
        
        init(_ parent: TimePickerRepresentable) {
            self.parent = parent
        }
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return Int(parent.maxDuration / parent.step) + 1
        }
        
        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let seconds = Double(row) * parent.step
            let label = UILabel()
            label.text = formatTime(seconds)
            label.textAlignment = .center
            label.transform = CGAffineTransform(rotationAngle: .pi / 2)
            label.font = .monospacedDigitSystemFont(ofSize: 16, weight: .medium)
            
            // 如果当前时间点有内容，设置为蓝色
            if parent.markedPositions.contains(seconds) {
                label.textColor = UIColor.systemBlue
            } else {
                label.textColor = UIColor.label
            }
            
            return label
        }
        
        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            return 50
        }
        
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            let seconds = Double(row) * parent.step
            parent.selectedSeconds = min(seconds, parent.maxDuration)
        }
        
        private func formatTime(_ seconds: Double) -> String {
            let minutes = Int(seconds) / 60
            let remainingSeconds = Int(seconds) % 60
            return String(format: "%02d:%02d", minutes, remainingSeconds)
        }
    }
}

#Preview {
    VStack {
        HorizontalTimePickerView(
            selectedSeconds: .constant(previewSelectedSeconds),
            maxDuration: 300,
            step: 1,
            markedPositions: [0, 30, 75, 120, 180]
        )
        .padding()
    }
}

private var previewSelectedSeconds: Double = 75
