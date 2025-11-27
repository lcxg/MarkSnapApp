//
//  ImageCompositor.swift
//  markSnap
//
//  Created by 徐梦超 on 2025/11/27.
//

import UIKit
import SwiftUI
import Photos

// MARK: - 1. Watermark Compositor (图像合成器)

class ImageCompositor {
    
    // 将水印绘制到照片上的核心函数
    static func composite(photo: UIImage, watermark: UIImage) -> UIImage {
        // 创建一个图形上下文，大小与原始照片一致
        let size = photo.size
        
        // 苹果官方推荐的图像渲染工具
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let finalImage = renderer.image { context in
            // 1. 先绘制原始照片 (放在底层)
            photo.draw(at: .zero)
            
            // 2. 计算水印的绘制区域
            // 我们假设水印图层（watermark）的宽高比与屏幕宽高比一致，且水印始终在左下角
            let watermarkWidth = size.width / 2.5 // 水印占照片宽度的 40%
            let watermarkRatio = watermark.size.height / watermark.size.width // 水印原图的高宽比
            let watermarkHeight = watermarkWidth * watermarkRatio
            
            // 绘制位置：左下角，留出少量边距
            let x = size.width * 0.05
            let y = size.height - watermarkHeight - size.height * 0.05
            
            let rect = CGRect(x: x, y: y, width: watermarkWidth, height: watermarkHeight)
            
            // 3. 绘制水印 (放在顶层)
            watermark.draw(in: rect)
        }
        
        return finalImage
    }
}

// MARK: - 2. Photo Saver (相册保存器)

class PhotoSaver: NSObject {
    // 保存最终图片到相册
    static func saveImageToAlbum(image: UIImage) {
        // 必须申请写入相册的权限
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("未获得相册写入权限")
                return
            }
            
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            print("照片已成功保存到相册！")
        }
    }
}

// MARK: - 3. SwiftUI 视图截图工具

// 这个扩展能把任何 SwiftUI 视图变成一个 UIImage
// ImageCompositor.swift (或 View 扩展所在的文件)

// ImageCompositor.swift (或 View 扩展所在的文件)

// ImageCompositor.swift (或 View 扩展所在的文件)

extension View {
    
    func asUIImage(scale: CGFloat = 1.0) -> UIImage {
        
        let controller = UIHostingController(rootView: self)
        
        // 1. 确保视图大小正确计算
        // 使用 .size 而不是 .bounds，避免歧义
        let size = controller.view.intrinsicContentSize
        controller.view.frame = CGRect(origin: .zero, size: size)
        
        // 2. 创建 Format 对象，明确设置比例尺
        // 使用一个更兼容的初始化方法
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale // 将传入的高分辨率比例尺应用到 format
        
        // 3. 使用 size 和 format 初始化渲染器
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        return renderer.image { context in
            // 确保视图在渲染前已更新
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
