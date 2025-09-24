//
//  DailyChartView.swift
//  MyiApp
//
//  Created by 이민서 on 5/12/25.
//

import SwiftUI

struct DailyChartView: View {
    let baby: Baby
    let records: [Record]
    
    var birthDate: Date {
        baby.birthDate
    }
    let selectedDate: Date
    let selectedCategories: [String]
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width * 0.8
            let lineWidth = size * 0.4
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size / 2 + lineWidth / 2 + 10
            
            ZStack {
                // 그래프 바탕
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
                    .frame(width: size, height: size)
                    .position(center)
                
                // 숫자 표기
                ForEach(0..<24) { hour in
                    let angle = Angle(degrees: Double(hour) / 24 * 360 - 90)
                    let x = center.x + cos(angle.radians) * radius
                    let y = center.y + sin(angle.radians) * radius
                    
                    if (hour % 2 == 0) {
                        Text("\(hour)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .position(x: x, y: y)
                    } else {
                        Text("·")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .position(x: x, y: y)
                    }
                    
                }
                
                // 그래프 표기
                ForEach(recordsWithTimeSpan, id: \.id) { record in
                    CircleSegmentShape(startHour: record.startHour, endHour: record.endHour)
                        .stroke(record.color, lineWidth: lineWidth)
                        .frame(width: size, height: size)
                        .position(center)
                    
                }
                
                //가운데 정보
                let months = Calendar.current.dateComponents([.month, .day], from: baby.birthDate, to: Date()).month ?? 0
                let days = (Calendar.current.dateComponents(
                    [.day],
                    from: Calendar.current.date(byAdding: .month, value: months, to: baby.birthDate) ?? Date(),
                    to: Date()
                ).day ?? 0) + 1
                
                Text("\(months)개월 \(days)일")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .position(center)
            }
        }
        .padding()
    }
    
    // 그래프 그릴 거 크기 조정
    private var recordsWithTimeSpan: [TimedRecord] {
        let calendar = Calendar.current
        let filteredRecords = records.filter { record in
            // 몸무게/키와 건강관리는 제외
            guard record.title != .heightWeight && record.title != .temperature && record.title != .medicine && record.title != .clinic && record.title != .diaper else { return false }
            
            guard selectedCategories.contains(record.title.displayName) else {
                return false
            }

            if record.title == .sleep, let start = record.sleepStart, let end = record.sleepEnd {
                return calendar.isDate(start, inSameDayAs: selectedDate)
                    || calendar.isDate(end, inSameDayAs: selectedDate)
            } else {
                return calendar.isDate(record.createdAt, inSameDayAs: selectedDate)
            }
        }
    

        
        return filteredRecords.flatMap { record in
            guard record.title != .heightWeight && record.title != .temperature && record.title != .medicine && record.title != .clinic else {
                return [] as [TimedRecord]
            }
            
            // 수면일 경우: 분할 필요
            if record.title == .sleep,
               let start = record.sleepStart,
               let end = record.sleepEnd {

                let startOfSelected = calendar.startOfDay(for: selectedDate)
                let endOfSelected = calendar.date(byAdding: .day, value: 1, to: startOfSelected)!

                let overlapStart = max(start, startOfSelected)
                let overlapEnd = min(end, endOfSelected)

                // 겹치는 구간이 존재할 때만 추가
                if overlapStart < overlapEnd {
                    return [TimedRecord(
                        id: UUID(),
                        startHour: hourDecimal(from: overlapStart),
                        endHour: hourDecimal(from: overlapEnd),
                        color: color(for: record.title)
                    )]
                } else {
                    return []
                }
            }


            guard calendar.isDate(record.createdAt, inSameDayAs: selectedDate) else {
                return []
            }
            
            let start = record.createdAt
            let end = calendar.date(byAdding: .minute, value: 30, to: start) ?? start.addingTimeInterval(1800)
            
            return [TimedRecord(
                id: record.id,
                startHour: hourDecimal(from: start),
                endHour: hourDecimal(from: end),
                color: color(for: record.title)
            )]
        }

    }
}

// 예: 13:30 -> 13.5
private func hourDecimal(from date: Date) -> Double {
    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
    let hour = Double(components.hour ?? 0)
    let minute = Double(components.minute ?? 0)
    return hour + (minute / 60)
}

private func color(for title: TitleCategory) -> Color {
    switch title {
    case .formula: return Color("food")
    case .babyFood: return Color("food")
    case .pumpedMilk: return Color("food")
    case .breastfeeding: return Color("food")
    case .diaper: return Color("diaper")
    case .pee: return Color("potty")
    case .poop: return Color("potty")
    case .pottyAll: return Color("potty")
    case .sleep: return Color("sleep")
    case .heightWeight: return Color("heightWeight")
    case .bath: return Color("bath")
    case .snack: return Color("snack")
    case .temperature: return Color("health")
    case .medicine: return Color("health")
    case .clinic: return Color("health")
    }
}

struct TimedRecord: Identifiable {
    let id: UUID
    let startHour: Double
    let endHour: Double
    let color: Color
}

struct CircleSegmentShape: Shape {
    let startHour: Double
    let endHour: Double
    
    func path(in rect: CGRect) -> Path {
        let correctedEndHour = endHour >= startHour ? endHour : endHour + 24
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        let startAngle = Angle(degrees: (startHour / 24) * 360 - 90)
        let endAngle = Angle(degrees: (correctedEndHour / 24) * 360 - 90)
        
        var path = Path()
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)
        return path
    }
}
