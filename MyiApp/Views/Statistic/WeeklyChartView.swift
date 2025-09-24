//
//  DailyChartView.swift
//  MyiApp
//
//  Created by 이민서 on 5/12/25.
//

import SwiftUI

struct WeeklyChartView: View {
    let baby: Baby
    let records: [Record]
    
    var birthDate: Date {
        baby.birthDate
    }
    
    let selectedDate: Date
    let selectedCategories: [String]
    
    private var weekDates: [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let dayWidth = geometry.size.width / 8
            let hourHeight = geometry.size.height / 25
            
            ZStack(alignment: .topLeading) {
                // 그래프 그리기
                Path { path in
                    for i in 1...7 {
                        let x = CGFloat(i) * dayWidth
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height - hourHeight))
                    }
                    
                    for i in 0...24 {
                        let y = CGFloat(i) * hourHeight
                        path.move(to: CGPoint(x: dayWidth, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                
                // 시간 그리기
                ForEach(0..<25) { hour in
                    let y = CGFloat(hour) * hourHeight
                    Text(hour % 3 == 0 ? "\(hour)" : "")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .position(x: 20, y: y)
                }
                
                // 날짜 그리기
                ForEach(weekDates.indices, id: \ .self) { index in
                    let date = weekDates[index]
                    let xOffset = dayWidth * CGFloat(index + 1)
                    let dateFormatter: DateFormatter = {
                        let df = DateFormatter()
                        df.locale = Locale(identifier: "ko_KR")
                        df.dateFormat = "d일"
                        return df
                    }()
                    let dateString = dateFormatter.string(from: date)
                    
                    Text(dateString)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .frame(width: dayWidth)
                        .position(x: xOffset + dayWidth / 2, y: geometry.size.height)
                }
                
                // 그래프 그리기
                ForEach(weeklyTimedRecords, id: \ .id) { record in
                    let x = CGFloat(record.dayIndex + 1) * dayWidth
                    let y = CGFloat(record.startHour) * hourHeight
                    let height = CGFloat(record.endHour - record.startHour) * hourHeight

                    
                    ZStack {
                        Rectangle()
                            .fill(record.color)
                            .frame(width: dayWidth * 0.6, height: max(height, 0.1))
                            .position(x: x + dayWidth / 2, y: y + height / 2)

                        
                    }
                }
            }
        }
        .frame(height: 500)
    }
    
    private var weeklyTimedRecords: [TimedWeeklyRecord] {
        let calendar = Calendar.current

        return records
            .filter { record in
                guard record.title != .heightWeight,
                      record.title != .temperature,
                      record.title != .medicine,
                      record.title != .clinic,
                      record.title != .diaper else {
                    return false
                }
                
                return selectedCategories.contains(record.title.displayName)
            }
            .flatMap { record in
                // 수면시간은 나눠서 관리
                if record.title == .sleep,
                   let start = record.sleepStart,
                   let end = record.sleepEnd {
                    
                    var result: [TimedWeeklyRecord] = []

                    for (index, day) in weekDates.enumerated() {
                        let startOfDay = calendar.startOfDay(for: day)
                        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }
                        
                        if max(start, startOfDay) < min(end, endOfDay) {
                            let clippedStart = max(start, startOfDay)
                            let clippedEnd = min(end, endOfDay)
                            
                            let startHourDecimal = hourDecimal(from: clippedStart)
                            var endHourDecimal = hourDecimal(from: clippedEnd)

                            if calendar.isDate(clippedEnd, equalTo: endOfDay, toGranularity: .minute) {
                                endHourDecimal = 24.0
                            }
                            
                            result.append(TimedWeeklyRecord(
                                id: UUID(),
                                dayIndex: index,
                                startHour: startHourDecimal,
                                endHour: endHourDecimal,
                                color: color(for: record.title)
                            ))
                        }
                    }

                    return result
                }

                // 일반 기록 처리
                guard let dayIndex = weekDates.firstIndex(where: {
                    calendar.isDate($0, inSameDayAs: record.createdAt)
                }) else {
                    return []
                }

                let start = record.createdAt
                let end = calendar.date(byAdding: .minute, value: 30, to: start) ?? start.addingTimeInterval(1800)

                let result = [
                    TimedWeeklyRecord(
                        id: record.id,
                        dayIndex: dayIndex,
                        startHour: hourDecimal(from: start),
                        endHour: hourDecimal(from: end),
                        color: color(for: record.title)
                    )
                ]

                return result

            }
    }

    
}

struct TimedWeeklyRecord: Identifiable {
    let id: UUID
    let dayIndex: Int
    let startHour: Double
    let endHour: Double
    let color: Color
}
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
    case .poop: return Color("potty")
    case .pee: return Color("potty")
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
