//
//  BathDetailView.swift
//  MyiApp
//
//  Created by 이민서 on 5/13/25.
//

import SwiftUI

struct BathDetailView: View {
    
    let baby: Baby
    
    var records: [Record] {
        CaregiverManager.shared.records
    }
    
    @State private var selectedDate = Date()
    @State private var selectedMode = "일"
    let modes = ["일", "주", "월"]
    
    @Environment(\.dismiss) private var dismiss
    
    private var formattedDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        if selectedMode == "일" {
            if Calendar.current.isDateInToday(selectedDate) {
                formatter.dateFormat = "MM월 dd일 '(오늘)'"
            } else {
                formatter.dateFormat = "MM월 dd일 (E)"
            }
            return formatter.string(from: selectedDate)
        } else if selectedMode == "주" {
            let calendar = Calendar(identifier: .gregorian)
            var mondayStartCalendar = calendar
            mondayStartCalendar.firstWeekday = 2
            
            let startOfWeek = mondayStartCalendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
            let endOfWeek = mondayStartCalendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? selectedDate
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MM월 dd일"
            formatter.locale = Locale(identifier: "ko_KR")
            
            let startString = formatter.string(from: startOfWeek)
            let endString = formatter.string(from: endOfWeek)
            
            return "\(startString) ~ \(endString)"
            
        } else {
            formatter.dateFormat = "yyyy년 M월"
            return formatter.string(from: selectedDate)
        }
    }
    
    var body: some View {
        ZStack {
            Color("customBackgroundColor")
                .ignoresSafeArea()
            mainScrollView
        }
        .navigationTitle("목욕 기록 분석")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var mainScrollView: some View {
        ScrollView {
            VStack(spacing: 15) {
                VStack(spacing: 10) {
                    toggleMode
                    Spacer()
                    dateMove
                }
                .padding(.horizontal)
                
                if (selectedMode == "일") {
                    DailyBathChartView(
                        weekDates: generateWeekDates(from: selectedDate),
                        records: records
                    )
                    .padding(.vertical, 10)
                    .padding(.bottom, 20)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
                    DailyBathListView(records: records,  selectedDate: selectedDate)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if (selectedMode == "주") {
                    WeeklyBathChartView(
                        selectedDate: selectedDate,
                        records: records
                    )
                    .padding(.vertical, 10)
                    .padding(.bottom, 20)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
                    WeeklyBathListView(records: records,  selectedDate: selectedDate)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    MonthlyBathChartView(
                        selectedDate: selectedDate,
                        records: records
                    )
                    .padding(.vertical, 10)
                    .padding(.bottom, 20)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
                    MonthlyBathListView(records: records,  selectedDate: selectedDate)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
        }
        
    }
    private var toggleMode: some View {
        Picker("모드 선택", selection: $selectedMode) {
            ForEach(modes, id: \.self) { mode in
                Text(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding()
        .frame(width: 300, height: 50)
    }
    private var dateMove: some View {
        ZStack {
            HStack {
                Button(action: {
                    let calendar = Calendar.current
                    switch selectedMode {
                    case "일":
                        selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                    case "주":
                        selectedDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
                    case "월":
                        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                    default:
                        break
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "calendar")
                    .foregroundColor(.primary)
                
                Text(formattedDateString)
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    let calendar = Calendar.current
                    switch selectedMode {
                    case "일":
                        selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                    case "주":
                        selectedDate = calendar.date(byAdding: .day, value: 7, to: selectedDate) ?? selectedDate
                    case "월":
                        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                    default:
                        break
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                }
            }
            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .frame(width: 180, height: 30)
            .blendMode(.destinationOver)
        }
        
    }
    func generateWeekDates(from selectedDate: Date) -> [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
}
struct DailyBathChartView: View {
    let weekDates: [Date]
    let records: [Record]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(uiImage: UIImage(named: "colorBath") ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                Text("목욕")
                    .font(.headline)
            }
            GeometryReader { geometry in
                let totalWidth = geometry.size.width - 60 //막대 사이 너비가 10인것을 고려
                let barWidth = totalWidth / CGFloat(weekDates.count)
                
                // 날짜별로 값 구해서
                let values = weekDates.map { date in
                    bathCount(on: date)
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
    
    func bathCount(on date: Date) -> Int {
        let calendar = Calendar.current
        let recordsForDate = records.filter {
            calendar.isDate($0.createdAt, inSameDayAs: date) &&
            $0.title == .bath
        }
        
        return recordsForDate.count
    }
    
    
    func shortDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
struct DailyBathListView: View {
    
    let records: [Record]
    let selectedDate: Date
    var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
    }
    
    
    var body: some View {
        
        DetailStatisticCardView(
            title: "일별 기록 분석",
            image: .colorBath,
            color: Color("bath"),
            count: recordsCount(for: .bath, in: records, on: selectedDate),
            lastcount: recordsCount(for: .bath, in: records, on: yesterday),
            amount: nil,
            lastamount: nil,
            time: nil,
            lasttime: nil,
            mode : "daily",
            selectedDate : selectedDate
        )
    }
    // 카테고리 받아서 횟수 셀리기
    func recordsCount(for title: TitleCategory, in records: [Record], on date: Date) -> Int {
        let calendar = Calendar.current
        return records.filter {
            $0.title == title && calendar.isDate($0.createdAt, inSameDayAs: date)
        }.count
    }
    
}
struct WeeklyBathChartView: View {
    let selectedDate: Date
    let records: [Record]
    
    var sixWeekStartDates: [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysToSubtract = (weekday + 5) % 7 // selectedDate의 주 시작 월요일 구하기
        let thisWeekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: selectedDate)!
        
        return (0..<7).map {
            calendar.date(byAdding: .day, value: -7 * (5 - $0), to: thisWeekStart)!
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(uiImage: UIImage(named: "colorBath") ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                Text("목욕")
                    .font(.headline)
            }
            GeometryReader { geometry in
                let totalWidth = geometry.size.width - 60 //막대 사이 너비가 10인것을 고려
                let barWidth = totalWidth / 7
                
                let values = sixWeekStartDates.map { startDate in
                    let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
                    return bathCount(from: startDate, to: endDate)
                }
                
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
                        ForEach(Array(zip(sixWeekStartDates, values)), id: \.0) { startDate, value in
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
                                Text(shortWeekLabel(for: startDate))
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
    func bathCount(from start: Date, to end: Date) -> Int {
        let recordsInRange = records.filter {
            $0.createdAt >= start &&
            $0.createdAt < end &&
            $0.title == .bath
        }
        return recordsInRange.count
    }

    
    
    func shortWeekLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M/d ~"
        return formatter.string(from: date)
    }
}
struct WeeklyBathListView: View {
    
    let records: [Record]
    let selectedDate: Date
    var thisWeekRange: DateInterval {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        return DateInterval(start: startOfWeek, end: calendar.date(byAdding: .day, value: 1, to: endOfWeek)!)
    }
    
    var lastWeekRange: DateInterval {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let thisWeekStart = thisWeekRange.start
        let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart)!
        let lastWeekEnd = calendar.date(byAdding: .day, value: 6, to: lastWeekStart)!
        return DateInterval(start: lastWeekStart, end: calendar.date(byAdding: .day, value: 1, to: lastWeekEnd)!)
    }
    
    
    var body: some View {
        
        DetailStatisticCardView(
            title: "주별 기록 분석",
            image: .colorBath,
            color: Color("bath"),
            count: recordsCount(for: .bath, in: records, within: thisWeekRange),
            lastcount: recordsCount(for: .bath, in: records, within: lastWeekRange),
            amount: nil,
            lastamount: nil,
            time: nil,
            lasttime: nil,
            mode : "weekly",
            selectedDate : selectedDate
        )
    }
    // 카테고리 받아서 횟수 셀리기
    func recordsCount(for title: TitleCategory, in records: [Record], within range: DateInterval) -> Int {
        return records.filter {
                $0.title == title && range.contains($0.createdAt)
            }.count
    }
}
struct MonthlyBathChartView: View {
    let selectedDate: Date
    let records: [Record]
    
    var sixMonthStartDates: [Date] {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        
        return (0..<7).map {
            let date = calendar.date(byAdding: .month, value: -5 + $0, to: selectedDate)!
            return calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        }
    }

    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(uiImage: UIImage(named: "colorBath") ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                Text("목욕")
                    .font(.headline)
            }
            GeometryReader { geometry in
                let totalWidth = geometry.size.width - 60 //막대 사이 너비가 10인것을 고려
                let barWidth = totalWidth / 7
                
                let values = sixMonthStartDates.map { startDate in
                    let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)!
                    return bathCount(from: startDate, to: endDate)
                }
                
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
                        ForEach(Array(zip(sixMonthStartDates, values)), id: \.0) { startDate, value in
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
                                Text(shortMonthLabel(for: startDate))
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
    
    func bathCount(from start: Date, to end: Date) -> Int {
        let recordsInRange = records.filter {
            $0.createdAt >= start &&
            $0.createdAt < end &&
            $0.title == .bath
        }
        
        return recordsInRange.count
    }
    
    
    func shortMonthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월"
        return formatter.string(from: date)
    }

}
struct MonthlyBathListView: View {
    
    let records: [Record]
    let selectedDate: Date
    var thisMonthRange: DateInterval {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        return DateInterval(start: startOfMonth, end: endOfMonth)
    }
    
    var lastMonthRange: DateInterval {
        let calendar = Calendar.current
        let startOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfThisMonth)!
        let endOfLastMonth = calendar.date(byAdding: .month, value: 1, to: startOfLastMonth)!
        return DateInterval(start: startOfLastMonth, end: endOfLastMonth)
    }
    
    
    var body: some View {
        
        DetailStatisticCardView(
            title: "월별 기록 분석",
            image: .colorBath,
            color: Color("bath"),
            count: recordsCount(for: .bath, in: records, within: thisMonthRange),
            lastcount: recordsCount(for: .bath, in: records, within: lastMonthRange),
            amount: nil,
            lastamount: nil,
            time: nil,
            lasttime: nil,
            mode : "monthly",
            selectedDate : selectedDate
        )
    }
    // 카테고리 받아서 횟수 셀리기
    func recordsCount(for title: TitleCategory, in records: [Record], within range: DateInterval) -> Int {
        return records.filter {
                $0.title == title && range.contains($0.createdAt)
            }.count
    }
}
