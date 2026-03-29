//
//  OceanView.swift
//  ToDivers-iOS
//
//  Created by Neon on 3/25/26.
//

import SwiftUI

import AVFAudio

enum OceanState {
    case noisy
    case calm
}

struct OceanView: View {
    
    ///물 높이
    @State private var progress: CGFloat = 0.6
    @State private var startAnimation: CGFloat = 0
    @StateObject private var monitor = SoundLevelMonitor()
    @State private var oceanState: OceanState = .noisy
    
    var normalizedLevel: CGFloat {
        let db = CGFloat(monitor.decibels)
        guard db >= 53 else { return 0 }
        return min(max((db - 53) / 27, 0), 1)
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
                        
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
                    level: normalizedLevel
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
                    Group {
                            if oceanState == .noisy {
                                Text("바다가 아직 고요하지 않아요")
                            } else {
                                Text("이제 더 깊은 곳으로 내려가 볼게요.")
                            }
                        }
                        .font(Font.custom("[KIM]sonmas", size: 30))
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 150)
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
            .onDisappear {
                monitor.stopMonitoring()
            }
            .task {
                var time: CGFloat = 0
                let clock = ContinuousClock()
                
                while !Task.isCancelled {
//                    print("🔥 decibels:", monitor.decibels)
                    
                    startAnimation += 1.5 + normalizedLevel * 4.0
                    
                    do {
                        try await clock.sleep(for: .milliseconds(16))
                    } catch {
                        break
                    }
                    
                    if monitor.decibels <= 53 {
                        time += 0.016
                    } else {
                        time = max(time - 0.05, 0)
                    }
                    
                    let newState: OceanState = (time >= 5) ? .calm : .noisy

                    if newState != oceanState {
                        withAnimation(.easeInOut(duration: 1.5)) {
                            oceanState = newState
                        }
                    }
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
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(offset, level) }
        set {
            offset = newValue.first
            level = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: .zero)
            
            let progressHeight: CGFloat = (1 - progress) * rect.height
            let height = waveHeight * rect.height * (1.0 + level * 2.0)
            
            for value in stride(from: 0, through: rect.width, by: 2) {
                let x: CGFloat = value
                let frequency = 0.4 + (level * 1.2)
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
