//
//  PhotoLibraryView.swift
//  markSnap
//
//  Created by 徐梦超 on 2025/11/27.
//

import SwiftUI
import PhotosUI

// 【新增】相册查看器（使用系统自带的 PHPickerViewController）
struct PhotoLibraryView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1 // 限制用户只能选择一张 (这里我们只是展示相册)
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PhotoLibraryView
        
        init(_ parent: PhotoLibraryView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // 用户点击取消或选择照片后，关闭视图
            picker.dismiss(animated: true)
        }
    }
}
