//
//  OceanView.swift
//  ToDivers-iOS
//
//  Created by Neon on 3/25/26.
//

import SwiftUI

import AVFAudio

struct OceanView: View {
    
    ///물 높이
    @State private var progress: CGFloat = 0.6
    @State private var startAnimation: CGFloat = 0
    @StateObject private var monitor = SoundLevelMonitor()
    
    var normalizedLevel: CGFloat {
        let level = CGFloat(monitor.decibels)
        return min(max(level / 100, 0), 1)
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            
            let normalized = min(max(CGFloat(monitor.decibels) / 100, 0), 1)
            let smooth = normalized * 0.1 + (1 - 0.1) * progress
            
            ZStack {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.6),
                        Color.indigo.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                Color.white
                    .opacity(0.5)
                    .blur(radius: 30)
                
//                WaterWave(progress: progress, waveHeight: 0.05, offset: startAnimation)
                WaterWave(
                    progress: progress,
                    waveHeight: 0.05,
                    offset: startAnimation,
                    level: smooth
                )
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.6),
                                Color.indigo.opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        Color.white
                            .opacity(0.5)
                            .blur(radius: 30)
                    }
                
                VStack(alignment: .center) {
                    Text("바다가 아직 고요하지 않아요")
                        .font(Font.custom("[KIM]sonmas", size: 30))
                        .foregroundStyle(Color.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)
            }
            .ignoresSafeArea()
            .onAppear {
                requestMicrophonePermission { granted in
                    if granted {
                        monitor.startMonitoring()
                    } else {
                        print("권한 없음")
                    }
                }
            }
            .task {
                while true {
                    let normalized = min(max(CGFloat(monitor.decibels) / 100, 0), 1)
                    let smooth = normalized * 0.1 + (1 - 0.1) * progress
                    
                    print("🔥 decibels:", monitor.decibels)
                    
                    startAnimation += 1 + smooth * 5
                    
                    try? await Task.sleep(nanoseconds: 16_000_000) // ~60fps
                }
            }
        }
    }
}

extension OceanView {
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            completion(granted)
        }
    }
}

struct WaterWave: Shape {
    var progress: CGFloat
    /// 진촉
    var waveHeight: CGFloat
    /// 좌우 흐름
    var offset: CGFloat
    var level: CGFloat
    var animatableData: CGFloat {
        get {offset}
        set {offset = newValue}
    }
    
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: .zero)
            
            let progressHeight: CGFloat = (1 - progress) * rect.height
            let height = waveHeight * rect.height 
            
            for value in stride(from: 0, through: rect.width, by: 2) {
                let x: CGFloat = value
                let frequency = 0.3 + (level * 1.2)
                /// 파도의 높이 계산
                let sine: CGFloat = sin(Angle(degrees: value * frequency + offset).radians)
                let y: CGFloat = progressHeight + (height * sine)
                
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
        }
    }
}
