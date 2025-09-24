//
//  ProgressComparisonBar.swift
//  MyiApp
//
//  Created by 이민서 on 5/12/25.
//

import SwiftUI

struct ProgressComparisonBar: View {
    let today: Int?
    let yesterday: Int?
    let color: Color
    let unit: String
    let mode: String

    var body: some View {
        GeometryReader { geometry in
            let barHeight: CGFloat = 6
            let maxWidth = geometry.size.width
            
            let (todayRatio, yesterdayRatio) = ratios(today: today, yesterday: yesterday)
            
            let todayWidth = todayRatio * maxWidth
            let yesterdayX = yesterdayRatio * maxWidth

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: barHeight)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: todayWidth, height: barHeight)
                
                Rectangle()
                    .foregroundColor(.gray)
                    .frame(width: 1, height: barHeight + 4)
                    .offset(x: yesterdayX)
                
                if let y = yesterday {
                    if (mode == "daily") {
                        Text("어제 \(y)\(unit)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .offset(x: min(yesterdayX + 4, maxWidth - 50), y: 10)
                    } else if (mode == "weekly") {
                        Text("지난주 \(y)\(unit)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .offset(x: min(yesterdayX + 4, maxWidth - 50), y: 10)
                    } else {
                        Text("지난달 \(y)\(unit)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .offset(x: min(yesterdayX + 4, maxWidth - 50), y: 10)
                    }
                    
                }
            }
        }
        .frame(height: 20)
    }

    private func ratios(today: Int?, yesterday: Int?) -> (CGFloat, CGFloat) {
        guard let today = today, let yesterday = yesterday else {
            return (0, 0)
        }
        let base = max(CGFloat(today), CGFloat(yesterday), 1)
        let todayRatio = CGFloat(today) / base
        let yesterdayRatio = CGFloat(yesterday) / base
        return (todayRatio, yesterdayRatio)
    }

}
