import SwiftUI
import Combine
import PhotosUI // 【重要】确保 PhotosUI 引入

struct ContentView: View {
    // --- 1. 数据准备区 ---
    // 【新增】对焦指示器状态和位置
        @State private var focusIndicatorPosition: CGPoint? = nil
        @State private var showFocusIndicator: Bool = false
    
    // 引入之前的定位管家
    @StateObject var locationManager = LocationManager()
    @StateObject var cameraService = CameraService()
    
    // 创建一个变量，存储“现在”的时间。
    @State private var currentTime = Date()
    
    // 状态变量，用于控制相册查看器的显示
    @State private var showingPhotoLibrary = false
    
    // 创建一个定时器：每隔 1 秒触发一次
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // --- 2. 格式化工具 (把时间变成文字) ---
    
    // 用来显示日期：2025.11.27
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd" // 年.月.日
        return formatter
    }
    
    // 用来显示具体时间：11:11:05
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss" // 24小时制 时:分:秒
        return formatter
    }
    
    // ==========================================================
    // 【修正位置】watermarkView 必须放在 body 之前！
    // ==========================================================
    
    // 【用于截图的水印视图定义】
    // ContentView.swift

    // ... (在 struct ContentView 内部，var body 之前)

    // 【用于截图的水印视图定义】
    var watermarkView: some View {
        VStack(alignment: .leading, spacing: 8) { // 增加间距
            
            // 1. 时间：超大号、纯白、粗体、强阴影
            Text(timeFormatter.string(from: currentTime))
                .font(.system(size: 42, weight: .heavy, design: .monospaced)) // 字号从 32 增大到 42
                .foregroundColor(.white) // 保持白色
                // 【关键】增加强烈的黑色阴影，保证在任何亮色背景下都能看清
                .shadow(color: .black.opacity(0.8), radius: 4, x: 2, y: 2)
            
            // 2. 分隔线 (用于增强结构感)
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.white.opacity(0.7))
            
            // 3. 日期和地点：增大字号，添加阴影
            HStack {
                Text(dateFormatter.string(from: currentTime))
                
                Text(" / ")
                    .foregroundColor(.white.opacity(0.8))
                
                Text(locationManager.locationName)
                    .lineLimit(1)
            }
            .font(.system(size: 16, weight: .medium)) // 字号增大到 16
            .foregroundColor(.white) // 保持白色
            .shadow(color: .black.opacity(0.6), radius: 2, x: 1, y: 1) // 增加阴影
        }
        .padding(20) // 增加内边距
        // 使用稍微深色的背景材质 (.thinMaterial)，增加对比度
        .background(.thinMaterial)
        .cornerRadius(12) // 增加圆角，提升设计感
    }
    
    // --- 3. 界面布局区 (body) ---
    var body: some View {
        ZStack {
            // 背景层
            CameraView(service: cameraService) { screenPoint in
                // 当 CameraView 报告点击时，更新状态以显示指示器
                self.focusIndicatorPosition = screenPoint
                self.showFocusIndicator = true
                
                // 0.5 秒后隐藏指示器
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showFocusIndicator = false
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            // 相机取景区域（已注释，实际不需要显示）
            /*
            VStack {
                Spacer()
                Text("相机取景区域")
                    .foregroundColor(.gray)
                Spacer()
            }
             */
            // 【新增】对焦指示器视图
                if showFocusIndicator, let position = focusIndicatorPosition {
                    FocusIndicatorView()
                        .position(position) // 将指示器放置在点击位置
                        // 【关键】允许触摸事件穿透指示器本身
                        .allowsHitTesting(false)
                }
            // 实时显示水印层（作为预览）
            VStack {
                Spacer()
                
                HStack {
                    Spacer() // 推开左侧，保持在右下方
                    
                    self.watermarkView // 调用上面定义的水印视图
                        .padding(.trailing, 20)
                }
                .padding(.bottom, 150)
            }// 【关键修复 1】: 允许触摸事件穿透水印视图，到达下方的摄像头视图
            .allowsHitTesting(false)
            
            // 【最终按钮层】
            VStack {
                Spacer() // 将所有按钮推到屏幕底部
                
                // 使用 HStack 组织左 (相册)、中 (快门)、右 (占位符) 三个元素
                HStack {
                    
                    // 1. 左侧：相册按钮
                    Button(action: {
                        self.showingPhotoLibrary = true // 触发相册查看器的显示
                    }) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    .padding(.leading, 40) // 左侧边距
                    
                    Spacer() // 将相册按钮推开
                    
                    // 2. 中间：拍照按钮
                    Button(action: {
                        // 1. 捕获水印截图
                        let watermarkImage = self.watermarkView.asUIImage(scale: 18.0)
                        // 2. 设置照片捕获完成后的回调
                        cameraService.photoCaptureCompletion = { capturedImage in
                            
                            guard let capturedImage = capturedImage else { return }
                            
                            // 3. 合成图像
                            let finalImage = ImageCompositor.composite(
                                photo: capturedImage,
                                watermark: watermarkImage
                            )
                            
                            // 4. 保存到相册
                            PhotoSaver.saveImageToAlbum(image: finalImage)
                        }
                        
                        // 5. 触发摄像头捕获
                        cameraService.capturePhoto()
                    }) {
                        // 按钮 UI
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 72, height: 72)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 62, height: 62)
                        }
                    }
                    
                    Spacer() // 将快门按钮推开
                    
                    // 3. 右侧：占位符 (与左侧按钮保持对齐)
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 40, height: 40)
                }
                .padding(.bottom, 50) // 底部边距
            }
        }
        // 【相册查看器弹出修饰符】
        .sheet(isPresented: $showingPhotoLibrary) {
            PhotoLibraryView()
        }
        // 【定时器】
        .onReceive(timer) { input in
            self.currentTime = input
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
