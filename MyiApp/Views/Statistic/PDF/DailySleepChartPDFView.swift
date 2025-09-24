//
//  DailySleepChartPDFView.swift
//  MyiApp
//
//  Created by 이민서 on 5/30/25.
//

import SwiftUI

struct DailySleepChartPDFView: View {
    let weekDates: [Date]
    let records: [Record]
    var selectedType: SleepType? = nil
    
    enum SleepType: String, CaseIterable {
        case count = "횟수"
        case time = "시간"
    }
    
    var body: some View {
        VStack(spacing: 15) {
            ForEach(selectedType.map { [$0] } ?? SleepType.allCases, id: \.self) { type in
                VStack(alignment: .leading) {
                    GeometryReader { geometry in
                        let totalWidth = geometry.size.width - 60 //막대 사이 너비가 10인것을 고려
                        let barWidth = totalWidth / CGFloat(weekDates.count)
                        
                        // 날짜별로 값 구해서
                        let values = weekDates.map { date in
                            amountFor(type, on: date)
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
                                    Text("평균 \(String(format: "%.2f", avgAmount))\(type == .count ? "회" : "분")")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                        .offset(x: -20, y: 85 - avgY),
                                    alignment: .topTrailing
                                )
                            HStack(alignment: .bottom, spacing: 10) {
                                ForEach(Array(zip(weekDates, values)), id: \.0) { date, value in
                                    VStack {
                                        if (maxAmount > 0) {
                                            Text("\(value)\(type == .count ? "회" : "분")")
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
                                            Text("\(value)\(type == .count ? "회" : "분")")
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
                .padding(.bottom, 20)
            }
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    func amountFor(_ type: SleepType, on date: Date) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let filtered = records.filter { $0.title == .sleep }
        
        switch type {
        case .count:
            return recordsCount(for: .sleep, in: records, on: date)
            
        case .time:
            let totalMinutes = filtered.compactMap { record -> Int? in
                guard let start = record.sleepStart, let end = record.sleepEnd else { return nil }
                let clippedStart = max(start, startOfDay)
                let clippedEnd = min(end, endOfDay)
                let interval = clippedEnd.timeIntervalSince(clippedStart)
                return interval > 0 ? Int(interval / 60) : nil
            }.reduce(0, +)
            
            return totalMinutes
        }
    }
    func recordsCount(for title: TitleCategory, in records: [Record], on date: Date) -> Int {
        let calendar = Calendar.current
        return records.filter {
            $0.title == title && calendar.isDate($0.createdAt, inSameDayAs: date)
        }.count
    }
    
    func shortDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
