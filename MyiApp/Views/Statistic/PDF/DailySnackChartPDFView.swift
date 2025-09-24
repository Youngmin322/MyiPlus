//
//  DailySnackChartPDFView.swift
//  MyiApp
//
//  Created by 이민서 on 5/30/25.
//

import SwiftUI

struct DailySnackChartPDFView: View {
    let weekDates: [Date]
    let records: [Record]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geometry in
                let totalWidth = geometry.size.width - 60 //막대 사이 너비가 10인것을 고려
                let barWidth = totalWidth / CGFloat(weekDates.count)
                
                // 날짜별로 값 구해서
                let values = weekDates.map { date in
                    snackCount(on: date)
                }
                
                // 최대값 구하기
                let maxAmount = values.max() ?? 0
                let avgAmount = Double(values.reduce(0, +)) / Double(values.count)
                let avgY: CGFloat = maxAmount == 0 ? 0 : CGFloat(avgAmount) / CGFloat(maxAmount) * 100
                
                ZStack(alignment: .topLeading) {
                    
                    Rectangle()
                        .fill(Color.red.opacity(0.4))
                        .frame(width: totalWidth + 60, height: 1)
                        .offset(y: 100 - avgY)
                        .overlay(
                            Text("평균 \(String(format: "%.2f", avgAmount))회")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .offset(x: -20, y: 85 - avgY),
                            alignment: .topTrailing
                        )
                    HStack(alignment: .bottom, spacing: 10) {
                        ForEach(Array(zip(weekDates, values)), id: \.0) { date, value in
                            VStack {
                                if (maxAmount > 0) {
                                    Text("\(value)회")
                                        .font(.caption2)
                                        .foregroundColor(.primary)
                                        .frame(height: 12)
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(
                                            width: barWidth,
                                            height: CGFloat(value) / CGFloat(maxAmount) * 100
                                        )
                                        .cornerRadius(4)
                                } else if (maxAmount == 0) {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(
                                            width: barWidth,
                                            height: 100
                                        )
                                        .cornerRadius(4)
                                    Text("\(value)회")
                                        .font(.caption2)
                                        .foregroundColor(.primary)
                                        .frame(height: 12)
                                }
                                
                                Text(shortDateString(for: date))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
            }
            .frame(height: 120)
            
        }
        .padding()
    }
    
    func snackCount(on date: Date) -> Int {
        let calendar = Calendar.current
        let recordsForDate = records.filter {
            calendar.isDate($0.createdAt, inSameDayAs: date) &&
            $0.title == .snack
        }
        
        return recordsForDate.count
    }
    
    
    func shortDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
