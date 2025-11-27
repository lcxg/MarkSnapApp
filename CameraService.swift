//
//  Untitled.swift
//  markSnap
//
//  Created by 徐梦超 on 2025/11/27.
//
import Foundation // 基础库1
import UIKit // 基础 UI 元素，供 AVFoundation 使用
import Combine // 【关键修正】引入 Combine 框架，以便识别 @Published
import AVFoundation

// MARK: - CameraService

class CameraService: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    
    // 【新增 1】核心属性：AVCaptureSession，用于管理输入和输出
        let session = AVCaptureSession()
        
        // 【新增 2】核心属性：后台队列，用于安全地执行耗时的会话配置
        let sessionQueue = DispatchQueue(label: "com.marksnap.SessionQueue")
        

    
    // 【新增】回调函数：用于将捕获到的 UIImage 传回 ContentView
    var photoCaptureCompletion: ((UIImage?) -> Void)?
    
    @Published var isSessionRunning: Bool = false
    var captureSession: AVCaptureSession? = nil
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    // 【新增】照片输出管理
    var photoOutput : AVCapturePhotoOutput?
    
    override init() {
        super.init()
    }
    
    func startSession(completion: @escaping (Bool) -> Void) {
        sessionQueue.async {
            // --- 1. 配置输入 (Input) ---
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: device) else {
                print("--- ERROR: Cannot create video input. ---")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            self.session.beginConfiguration()
            
            // 移除旧输入并添加新输入
            if !self.session.inputs.isEmpty {
                self.session.inputs.forEach { self.session.removeInput($0) }
            }
            if self.session.canAddInput(videoInput) {
                self.session.addInput(videoInput)
            }
            
            // --- 2. 配置输出 (Output) ---
            let photoOutput = AVCapturePhotoOutput()
            // 移除旧输出并添加新输出
            if !self.session.outputs.isEmpty {
                self.session.outputs.forEach { self.session.removeOutput($0) }
            }
            if self.session.canAddOutput(photoOutput) {
                self.session.addOutput(photoOutput)
                self.photoOutput = photoOutput // 赋值给可选属性
            }
            
            self.session.commitConfiguration()
            
            // --- 3. 配置连接 (Connections) ---
            
            // 3a. 配置预览层 (在主线程添加)
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            self.previewLayer?.videoGravity = .resizeAspectFill
            if let connection = self.previewLayer?.connection, connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            
            // 3b. 配置照片输出连接 (解决 'No active and enabled video connection' 崩溃)
            if let connection = photoOutput.connection(with: .video), connection.isVideoOrientationSupported {
                connection.isEnabled = true
                connection.videoOrientation = .portrait
                print("--- DEBUG: Photo Output Connection successfully activated. ---")
            } else {
                 print("--- DEBUG: CRITICAL WARNING: Failed to find or configure Photo Output connection. ---")
                 // 即使失败，也尝试启动，但不保证拍照成功
            }
            
            // --- 4. 启动会话 ---
            self.session.startRunning()
            print("--- DEBUG: AVCaptureSession successfully started running. ---")
            
            // 将成功的信号发送回主线程
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
    
    // 【修正】拍照方法：发起捕获请求
    func capturePhoto() {
        // 【解包修复】确保 photoOutput 存在
        guard let photoOutput = self.photoOutput else {
            print("--- ERROR: Photo Output is nil, cannot capture photo. ---")
            return
        }
        
        let photoSettings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    // 【新增】对焦逻辑：处理对焦点设置
    // 【对焦逻辑】
    func focus(at point: CGPoint) {
        // ... (保持你现有的 focus 方法逻辑不变，它已经是正确的)
        // 它应该以 try device.lockForConfiguration() 开始
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("--- DEBUG: ERROR: Could not get back camera device. ---")
            return
        }
        
        do {
            try device.lockForConfiguration()
            // ... (设置对焦和曝光模式的代码保持不变)
            device.unlockForConfiguration()
            print("--- DEBUG: Focus and Exposure set successfully at: \(point) ---")
        } catch {
            print("--- DEBUG: CRITICAL ERROR: lockForConfiguration failed: \(error.localizedDescription) ---")
        }
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    
    // 【新增】当照片处理完成后，系统会自动调用这个方法
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("照片捕获错误: \(error.localizedDescription)")
            self.photoCaptureCompletion?(nil) // 捕获失败，传回 nil
            return
        }
        
        // 获取原始照片数据，并转换成 UIImage
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            self.photoCaptureCompletion?(nil)
            return
        }
        
        // 【关键】将捕获到的原始照片传回给 ContentView
        self.photoCaptureCompletion?(image)
    }
}
