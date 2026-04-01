//
//  DiveView.swift
//  ToDivers-iOS
//
//  Created by Neon on 3/29/26.
//

import SwiftUI

enum DiveViewType {
    case smallDive
    case mediumDive
    case bigDive
    case superBigDive
}

struct DiveView: View {
    
    var meshColors: [Color] {
        switch currentType {
        case .smallDive:
            return [
                Color(red: 0.75, green: 0.90, blue: 1.0),
                Color(red: 0.65, green: 0.85, blue: 1.0),
                Color(red: 0.75, green: 0.90, blue: 1.0),

                Color(red: 0.55, green: 0.78, blue: 0.98),
                Color(red: 0.48, green: 0.70, blue: 0.95),
                Color(red: 0.55, green: 0.78, blue: 0.98),
                Color(red: 0.35, green: 0.60, blue: 0.90),
                Color(red: 0.42, green: 0.68, blue: 0.93),
                Color(red: 0.35, green: 0.60, blue: 0.90)
            ]
        case .mediumDive:
            return [
                Color(red: 0.38, green: 0.58, blue: 0.90),
                Color(red: 0.32, green: 0.52, blue: 0.86),
                Color(red: 0.38, green: 0.58, blue: 0.90),
                Color(red: 0.28, green: 0.48, blue: 0.82),
                Color(red: 0.22, green: 0.40, blue: 0.76),
                Color(red: 0.28, green: 0.48, blue: 0.82),
                Color(red: 0.18, green: 0.35, blue: 0.70),
                Color(red: 0.22, green: 0.40, blue: 0.76),
                Color(red: 0.18, green: 0.35, blue: 0.70)
            ]
        case .bigDive:
            return [
                Color(red: 0.12, green: 0.25, blue: 0.58),
                Color(red: 0.10, green: 0.20, blue: 0.52),
                Color(red: 0.12, green: 0.25, blue: 0.58),
                Color(red: 0.08, green: 0.16, blue: 0.45),
                Color(red: 0.06, green: 0.12, blue: 0.38),
                Color(red: 0.08, green: 0.16, blue: 0.45),
                Color(red: 0.04, green: 0.08, blue: 0.30),
                Color(red: 0.06, green: 0.12, blue: 0.38),
                Color(red: 0.04, green: 0.08, blue: 0.30)
            ]
        case .superBigDive:
            return [
                Color(red: 0.04, green: 0.08, blue: 0.30),
                Color(red: 0.06, green: 0.12, blue: 0.38),
                Color(red: 0.03, green: 0.06, blue: 0.22),
                Color(red: 0.01, green: 0.03, blue: 0.14),
                Color(red: 0.01, green: 0.02, blue: 0.10),
                Color(red: 0.01, green: 0.03, blue: 0.14),
                Color(red: 0.005, green: 0.01, blue: 0.08),
                Color(red: 0.01, green: 0.02, blue: 0.10),
                Color(red: 0.005, green: 0.01, blue: 0.08)
            ]
        }
    }
    
    
    @State private var animate1 = false
    @State private var animate2 = false
    
    /// 호흡
    @State private var dbHistory: [CGFloat] = []
    @State private var lastDirection: Int = 0
    @State private var breathCount: Int = 0

    @State private var currentType: DiveViewType = .smallDive
    
    @ObservedObject var monitor: SoundLevelMonitor
    
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0],
                [animate2 ? 0.25 : 0.75, 0],
                [1, 0],
                
                [0, 0.5],
                [animate1 ? 0.35 : 0.75, animate1 ? 0.55 : 0.25],
                [1, animate1 ? 0.55 : 0.25],
                
                [0, 1],
                [animate2 ? 0.35 : 1, 1],
                [1, 1]
            ],
            colors: meshColors
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 1), value: currentType)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3)
                .repeatForever(autoreverses: true)
            ) {
                animate1.toggle()
            }
            withAnimation(
                .easeInOut(duration: 9)
                .repeatForever(autoreverses: true)
            ) {
                animate2.toggle()
            }
        }
        .task {
            while !Task.isCancelled {
                let current = CGFloat(monitor.decibels)
                
                /// dbHistory에 매 16ms마다 현재 데시벨을 배열에 쌓도록, 20개 이상이 될 경우 가장 오래된 데이터를 지움
                dbHistory.append(current)
                if dbHistory.count > 20 {
                    dbHistory.removeFirst()
                }
                
                guard dbHistory.count >= 2 else {
                    try? await Task.sleep(nanoseconds: 16_000_000)
                    continue
                }
                
                let prev = dbHistory[dbHistory.count - 2]
                let diff = abs(current - prev)
                
                if diff >= 7 {
                    breathCount += 1
                    print("🌬 호흡", diff)
                }
                
                if breathCount >= 3 {
                    breathCount = 0
                    
                    withAnimation(.easeInOut(duration: 1.5)){
                        switch currentType {
                        case .smallDive: currentType = .mediumDive
                        case .mediumDive: currentType = .bigDive
                        case .bigDive: currentType = .superBigDive
                        case .superBigDive: break
                        }
                    }
                }
                                
                try? await Task.sleep(nanoseconds: 16_000_000)
            }
        }
    }
}
