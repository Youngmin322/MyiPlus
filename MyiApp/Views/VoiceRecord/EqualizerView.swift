//
//  EqualizerView.swift
//  MyiApp
//
//  Created by 조영민 on 5/12/25.
//

import SwiftUI

struct EqualizerView: View {
    @State private var heights: [CGFloat] = Array(repeating: 10, count: 8) // 각 막대의 높이 상대값
    
    let numberOfBars = 8 // 이퀄라이저 막대 개수
    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            ForEach(0..<numberOfBars, id: \.self) { index in
                Capsule()
                    .fill(Color("buttonColor"))
                    .frame(width: 8, height: heights[index])
            }
        }
        .frame(height: 100)
        .onAppear {
            startAnimation()
        }
    }
    
    func startAnimation() {
        // 0.2초 간격으로 타이머 반복 재생
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            // 애니메이션 효과로 막대 높이 변경
            withAnimation(.easeInOut(duration: 0.2)) {
                heights = (0..<numberOfBars).map { index in
                    let center = CGFloat(numberOfBars - 1) / 2 // 중앙 막대 위치
                    let distance = abs(CGFloat(index) - center) // 중앙으로부터의 거리
                    let falloff = cos(distance * .pi / CGFloat(numberOfBars)) // 중심부가 더 크게 움직이게 하는 완하 값(미적 요소)
                    let base = 20 + 20 * falloff // 최소 높이 설정
                    return CGFloat.random(in: base...(base + 60)) // 높이를 랜덤으로 부여
                }
            }
        }
    }
}

#Preview {
    EqualizerView()
}
