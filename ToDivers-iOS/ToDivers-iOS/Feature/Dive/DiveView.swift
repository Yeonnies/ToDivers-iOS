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
    var body: some View {
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
        }
    }
}
