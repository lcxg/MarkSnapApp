//
//  CameraView.swift
//  markSnap
//
//  Created by 徐梦超 on 2025/11/27.
//

// CameraView.swift

import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    @ObservedObject var service: CameraService
    
    // 【新增】回调，用于将点击位置传回 ContentView
        var onTap: (CGPoint) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: CameraView
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            print("--- DEBUG: handleTap triggered! ---")
            
            guard let previewLayer = parent.service.previewLayer,
                  let view = gesture.view else {
                print("--- DEBUG: ERROR: previewLayer or view is nil! ---"); return
            }
            
            let point = gesture.location(in: view)
            
            // 关键：将视图坐标转换为摄像头标准化坐标
            // 确保使用的 previewLayer.frame 是正确的，通常它应该占满整个 view
            let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
            
            // 调试输出：检查转换后的坐标是否在 0.0 到 1.0 的范围内
            print("--- DEBUG: Tap Point (View): \(point.x), \(point.y)")
            print("--- DEBUG: Tap Point (Device Normalized): \(devicePoint.x), \(devicePoint.y) ---")
            
            // 【关键】执行回调，将屏幕坐标传回 ContentView
                        self.parent.onTap(point)
            
            self.parent.service.focus(at: devicePoint)
        }
    }
    
    // CameraView.swift

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.isUserInteractionEnabled = true
        
        // 【修改】调用 startSession，并在回调中添加预览层
        service.startSession(completion: { success in
            if success {
                // 【核心修复点】确保在主线程上执行 UI 操作
                DispatchQueue.main.async {
                    if let previewLayer = self.service.previewLayer {
                        previewLayer.frame = view.bounds // 设置大小
                        view.layer.addSublayer(previewLayer) // 添加图层
                        print("--- DEBUG: Preview Layer successfully added to UIView. ---")
                    }
                }
            }
        })
        
        // 注意：这里的 if let previewLayer = service.previewLayer 语句被移除了
        
        // 添加手势识别器
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }

    // ...
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
