//
//  FocusIndicatorView.swift
//  markSnap
//
//  Created by 徐梦超 on 2025/11/27.
//

import SwiftUI

// FocusIndicatorView.swift 或在 ContentView.swift 底部

struct FocusIndicatorView: View {
    @State private var scale: CGFloat = 1.5 // 初始放大
    
    var body: some View {
        // 一个黄色的边框方框，作为对焦指示器
        Rectangle()
            .stroke(Color.yellow, lineWidth: 2)
            .frame(width: 70, height: 70)
            .scaleEffect(scale)
            .opacity(0.8)
            // 动画效果：闪烁/缩小
            .onAppear {
                // 启动动画，让方框从大到小，然后淡出
                withAnimation(.easeOut(duration: 0.2)) {
                    scale = 1.0 // 恢复到正常大小
                }
                // 1 秒后自动消失
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        scale = 0.5 // 消失时的淡出效果
                    }
                }
            }
    }
}
