//
//  DiveView.swift
//  ToDivers-iOS
//
//  Created by Neon on 3/29/26.
//

import SwiftUI

struct DiveView: View {
    
    @State private var depthLevel: CGFloat = 0.0 // 0 ~ 1
    
    @State private var animate1 = false
    @State private var animate2 = false
    
    @State private var dbHistory: [CGFloat] = []
    
    @ObservedObject var monitor: SoundLevelMonitor
    
    /// 가이딩 문구
    @State private var showGuideText = false
    @State private var hasShownIntro = false
    @State private var isResetting = false
    
    func oceanColor(depth: CGFloat) -> (top: Color, mid: Color, bottom: Color) {
        
        let top = Color(
            hue: 0.55,
            saturation: 0.4 + depth * 0.3,
            brightness: 1.0 - depth * 0.5
        )
        
        let mid = Color(
            hue: 0.58,
            saturation: 0.5 + depth * 0.4,
            brightness: 0.9 - depth * 0.6
        )
        
        let bottom = Color(
            hue: 0.60,
            saturation: 0.6 + depth * 0.4,
            brightness: 0.8 - depth * 0.7
        )
        
        return (top, mid, bottom)
    }
    
    var meshColors: [Color] {
        let c = oceanColor(depth: depthLevel)
        
        return [
            c.top, c.mid, c.top,
            c.mid, c.bottom, c.mid,
            c.top, c.mid, c.bottom
        ]
    }
    
    var body: some View {
        ZStack {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0, 0],
                    [animate2 ? 0.45 : 0.55, 0],
                    [1, 0],
                    
                    [0, 0.5],
                    [animate1 ? 0.48 : 0.52, animate1 ? 0.55 : 0.45],
                    [1, animate1 ? 0.55 : 0.45],
                    
                    [0, 1],
                    [animate2 ? 0.48 : 0.52, 1],
                    [1, 1]
                ],
                colors: meshColors
            )
            .ignoresSafeArea()
            
            LinearGradient(
                colors: [
                    Color.white.opacity(0.35 * (1 - depthLevel)),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
            
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.blue.opacity(0.2 * depthLevel),
                    Color.black.opacity(0.6 * depthLevel)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .blendMode(.multiply)
            
            VStack {
                Spacer()
                if showGuideText {
                    Spacer()
                    Text(depthLevel < 1 ? "ⓘ 호흡할 때마다 더 깊은 곳으로 잠수해요." : "ⓘ 가장 깊은 곳까지 도달했어요. \n다시 수면위로 올라갑니다.")
                        .font(Font.custom("[KIM]sonmas", size: 16))
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 100)
        }
        .animation(.easeInOut(duration: 0.6), value: depthLevel)
        
        // MARK: - 애니메이션
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3)
                .repeatForever(autoreverses: true)
            ) {
                animate1.toggle()
            }
            
            withAnimation(
                .easeInOut(duration: 6)
                .repeatForever(autoreverses: true)
            ) {
                animate2.toggle()
            }
            
            if !hasShownIntro {
                hasShownIntro = true
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.5)){
                            showGuideText = true
                        }
                    }
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.5)){
                            showGuideText = false
                        }
                    }
                }
            }
        }
        
        // MARK: - 호흡
        .task {
            while !Task.isCancelled {
                let current = CGFloat(monitor.decibels)
                
                dbHistory.append(current)
                if dbHistory.count > 10 {
                    dbHistory.removeFirst()
                }
                
                guard dbHistory.count >= 2 else {
                    try? await Task.sleep(nanoseconds: 16_000_000)
                    continue
                }
                
                let prev = dbHistory[dbHistory.count - 2]
                let diff = abs(current - prev)
                
                if diff >= 7 {
                    withAnimation(.easeInOut(duration: 1.2)) {
                        depthLevel += 0.1
                        depthLevel = min(depthLevel, 1.0)
                    }
                    
                    print("🌊 depth:", depthLevel)
                }
                
                try? await Task.sleep(nanoseconds: 16_000_000)
                
                if depthLevel >= 1.0 && !isResetting {
                    isResetting = true
                    
                    Task {
                        await MainActor.run {
                            withAnimation {
                                showGuideText = true
                            }
                        }
                        
                        try? await Task.sleep(nanoseconds: 4_000_000_000)
                        
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 5.0)) {
                                depthLevel = 0
                            }
                        }
                        
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        
                        await MainActor.run {
                            withAnimation {
                                showGuideText = false
                            }
                            isResetting = false
                        }
                    }
                }
            }
        }
    }
}
