//
//  DailyFeedChartView.swift
//  MyiApp
//
//  Created by 이민서 on 5/30/25.
//

import SwiftUI

struct DailyFeedChartPDFView: View {
    let weekDates: [Date]
    let records: [Record]
    var selectedType: FeedingType? = nil
    
    enum FeedingType: String, CaseIterable {
        case formula = "분유"
        case pumpedMilk = "유축 수유"
        case breastfeeding = "모유 수유"
        case babyFood = "이유식"
    }
    
    var body: some View {
        VStack(spacing: 15) {
            ForEach(selectedType.map { [$0] } ?? FeedingType.allCases, id: \.self) { type in
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
                                    Text("평균 \(String(format: "%.2f", avgAmount))\(type == .breastfeeding ? "분" : "ml")")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                        .offset(x: -20, y: 85 - avgY),
                                    alignment: .topTrailing
                                )
                            HStack(alignment: .bottom, spacing: 10) {
                                ForEach(Array(zip(weekDates, values)), id: \.0) { date, value in
                                    VStack {
                                        if (maxAmount > 0) {
                                            Text("\(value)\(type == .breastfeeding ? "분" : "ml")")
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
                .padding(.bottom, 20)
                
            }
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    func iconImage(for type: FeedingType) -> UIImage {
        switch type {
        case .formula: return UIImage(named: "normalPowderedMilk") ?? UIImage()
        case .pumpedMilk: return UIImage(named: "normalPumpedMilk") ?? UIImage()
        case .breastfeeding: return UIImage(named: "normalBreastFeeding") ?? UIImage()
        case .babyFood: return UIImage(named: "normalBabyMeal") ?? UIImage()
        }
    }
    
    func titleCategory(of record: Record) -> FeedingType? {
        switch record.title {
        case .formula: return .formula
        case .pumpedMilk: return .pumpedMilk
        case .breastfeeding: return .breastfeeding
        case .babyFood: return .babyFood
        default: return nil
        }
    }
    
    func amountFor(_ type: FeedingType, on date: Date) -> Int {
        let calendar = Calendar.current
        let recordsForDate = records.filter {
            calendar.isDate($0.createdAt, inSameDayAs: date) &&
            titleCategory(of: $0) == type
        }
        
        if type == .breastfeeding {
            return recordsForDate.reduce(0) { total, record in
                total + (record.breastfeedingLeftMinutes ?? 0) + (record.breastfeedingRightMinutes ?? 0)
            }
        } else {
            return recordsForDate
                .compactMap { $0.mlAmount }
                .reduce(0, +)
        }
    }
    
    
    func shortDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
