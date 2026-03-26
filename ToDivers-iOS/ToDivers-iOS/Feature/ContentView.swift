//
//  ContentView.swift
//  ToDivers-iOS
//
//  Created by Neon on 3/25/26.
//

import SwiftUI
import UIKit

struct ContentView: View {
    
    @State var progress: CGFloat = 0.5
    @State var startAnimation: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
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
                
                WaterWave(progress: 0.5, waveHeight: 0.05, offset: startAnimation)
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
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)){
                    startAnimation = 360
                }
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
    }
}

struct WaterWave: Shape {
    var progress: CGFloat
    var waveHeight: CGFloat
    var offset: CGFloat
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
                /// 파도의 높이 계산
                let sine: CGFloat = sin(Angle(degrees: value * 0.4 + offset).radians)
                let y: CGFloat = progressHeight + (height * sine)
                
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
        }
    }
}

#Preview {
    ContentView()
}
