//
//  Untitled.swift
//  markSnap
//
//  Created by 徐梦超 on 2025/11/27.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // 这是一个“发布者”，一旦位置更新，界面上订阅了它的地方就会自动刷新
    @Published var locationName: String = "正在定位..."
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder() // 用于把经纬度变成“北京市海淀区”这种文字
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest // 要最高精度的位置
        manager.requestWhenInUseAuthorization() // 弹窗请求权限
        manager.startUpdatingLocation() // 开始抓取位置
    }
    
    // 这里的代码是系统自动调用的：当手机获取到经纬度时
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 我们只需要获取一次，获取到了就让它停下来，省电
        manager.stopUpdatingLocation()
        
        // 开始“反向地理编码”：把难懂的经纬度变成人话
        getAddressFrom(location: location)
    }
    
    // 把经纬度变成文字的函数
    func getAddressFrom(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                print("获取地址失败: \(error.localizedDescription)")
                self.locationName = "无法获取位置"
                return
            }
            
            if let placemark = placemarks?.first {
                // 组合地址：城市 + 区县 (例如：Beijing, Haidian)
                let city = placemark.locality ?? ""
                let district = placemark.subLocality ?? ""
                let name = placemark.name ?? ""
                
                // 这里的逻辑是：如果有具体地名就用地名，没有就用城市
                DispatchQueue.main.async {
                    if !district.isEmpty {
                        self.locationName = "📍 \(city) \(district)"
                    } else {
                        self.locationName = "📍 \(name)"
                    }
                }
            }
        }
    }
    
    // 如果用户拒绝了权限，或者出错了
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("定位出错: \(error.localizedDescription)")
        self.locationName = "定位服务未开启"
    }
}
