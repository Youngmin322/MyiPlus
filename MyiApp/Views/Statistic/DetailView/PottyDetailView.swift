//
//  PottyDetailView.swift
//  MyiApp
//
//  Created by 이민서 on 5/13/25.
//

import SwiftUI

struct PottyDetailView: View {
    
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
        .navigationTitle("배변 기록 분석")
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
                    DailyPottyChartView(
                        weekDates: generateWeekDates(from: selectedDate),
                        records: records
                    )
                    DailyPottyListView(records: records,  selectedDate: selectedDate)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if (selectedMode == "주") {
                    WeeklyPottyChartView(
                        selectedDate: selectedDate,
                        records: records
                    )
                    WeeklyPottyListView(records: records,  selectedDate: selectedDate)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    MonthlyPottyChartView(
                        selectedDate: selectedDate,
                        records: records
                    )
                    MonthlyPottyListView(records: records,  selectedDate: selectedDate)
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
struct DailyPottyChartView: View {
    let weekDates: [Date]
    let records: [Record]
    
    enum PottyType: String, CaseIterable {
        case pee = "소변"
        case poop = "대변"
    }
    
    var body: some View {
        VStack(spacing: 15) {
            ForEach(PottyType.allCases, id: \.self) { type in
                VStack(alignment: .leading) {
                    HStack(spacing: 6) {
                        Image(uiImage: iconImage(for: type))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                        Text(type.rawValue)
                            .font(.headline)
                    }
                    GeometryReader { geometry in
                        let totalWidth = geometry.size.width - 60 //막대 사이 너비가 10인것을 고려
                        let barWidth = totalWidth / CGFloat(weekDates.count)
                        
                        // 날짜별로 값 구해서
                        let values = weekDates.map { date in
                            pottyCount(type, on: date)
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
                .padding(.bottom, 20)
            }
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    func iconImage(for type: PottyType) -> UIImage {
        switch type {
        case .pee: return UIImage(named: "normalPee") ?? UIImage()
        case .poop: return UIImage(named: "normalPoop") ?? UIImage()
        }
    }
    
    func pottyCount(_ type: PottyType, on date: Date) -> Int {
        let calendar = Calendar.current
        let recordsForDate = records.filter {
            calendar.isDate($0.createdAt, inSameDayAs: date)
        }

        switch type {
        case .pee:
            // 소변 또는 대소변이면 소변 그래프 +1
            return recordsForDate.filter { $0.title == .pee || $0.title == .pottyAll }.count
        case .poop:
            // 대변 또는 대소변이면 대변 그래프 +1
            return recordsForDate.filter { $0.title == .poop || $0.title == .pottyAll }.count
        }
    }

    
    
    func shortDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
struct DailyPottyListView: View {
    
    let records: [Record]
    let selectedDate: Date
    var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
    }
    
    
    var body: some View {
        let pottyCount = countPottyTypes(in: records, on: selectedDate)
        let yesterdaypottyCount = countPottyTypes(in: records, on: yesterday)
        
        DetailPottyStatisticCardView(
            small: pottyCount.small,
            yesterdaysmall: yesterdaypottyCount.small,
            big: pottyCount.big,
            yesterdaybig: yesterdaypottyCount.big,
            mode : "daily",
            selectedDate : selectedDate
        )
    }
    // 소변,배변 횟수 따로 셀리기
    func countPottyTypes(in records: [Record], on date: Date) -> (small: Int, big: Int) {
        let calendar = Calendar.current

        var small = 0
        var big = 0

        for record in records {
            guard calendar.isDate(record.createdAt, inSameDayAs: date) else { continue }

            switch record.title {
            case .pee:
                small += 1
            case .poop:
                big += 1
            case .pottyAll:
                small += 1
                big += 1
            default:
                continue
            }
        }

        return (small, big)
    }
    
}
struct WeeklyPottyChartView: View {
    let selectedDate: Date
    let records: [Record]
    
    enum PottyType: String, CaseIterable {
        case pee = "소변"
        case poop = "대변"
    }
    
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
        VStack(spacing: 15) {
            ForEach(PottyType.allCases, id: \.self) { type in
                VStack(alignment: .leading) {
                    HStack(spacing: 6) {
                        Image(uiImage: iconImage(for: type))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                        Text(type.rawValue)
                            .font(.headline)
                    }
                    GeometryReader { geometry in
                        let totalWidth = geometry.size.width - 60 //막대 사이 너비가 10인것을 고려
                        let barWidth = totalWidth / 7
                        
                        let values = sixWeekStartDates.map { startDate in
                            let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
                            return pottyCount(type, from: startDate, to: endDate)
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
                .padding(.bottom, 20)
            }
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
        
    }
    func iconImage(for type: PottyType) -> UIImage {
        switch type {
        case .pee: return UIImage(named: "normalPee") ?? UIImage()
        case .poop: return UIImage(named: "normalPoop") ?? UIImage()
        }
    }
    func pottyCount(_ type: PottyType, from start: Date, to end: Date) -> Int {
        let recordsInRange = records.filter {
            $0.createdAt >= start && $0.createdAt < end
        }

        switch type {
        case .pee:
            return recordsInRange.filter { $0.title == .pee || $0.title == .pottyAll }.count
        case .poop:
            return recordsInRange.filter { $0.title == .poop || $0.title == .pottyAll }.count
        }
    }


    
    
    func shortWeekLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M/d ~"
        return formatter.string(from: date)
    }
}
struct WeeklyPottyListView: View {
    
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
        let pottyCount = countPottyTypes(in: records, within: thisWeekRange)
        let yesterdaypottyCount = countPottyTypes(in: records, within: lastWeekRange)
        
        DetailPottyStatisticCardView(
            small: pottyCount.small,
            yesterdaysmall: yesterdaypottyCount.small,
            big: pottyCount.big,
            yesterdaybig: yesterdaypottyCount.big,
            mode : "weekly",
            selectedDate : selectedDate
        )
    }
    // 소변,배변 횟수 따로 셀리기
    func countPottyTypes(in records: [Record], within range: DateInterval) -> (small: Int, big: Int) {
        var small = 0
        var big = 0

        for record in records {
            guard range.contains(record.createdAt) else { continue }

            switch record.title {
            case .pee:
                small += 1
            case .poop:
                big += 1
            case .pottyAll:
                small += 1
                big += 1
            default:
                continue
            }
        }

        return (small, big)
    }
}
struct MonthlyPottyChartView: View {
    let selectedDate: Date
    let records: [Record]
    
    enum PottyType: String, CaseIterable {
        case pee = "소변"
        case poop = "대변"
    }
    
    var sixMonthStartDates: [Date] {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        
        return (0..<7).map {
            let date = calendar.date(byAdding: .month, value: -5 + $0, to: selectedDate)!
            return calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        }
    }

    
    var body: some View {
        VStack(spacing: 15) {
            ForEach(PottyType.allCases, id: \.self) { type in
                VStack(alignment: .leading) {
                    HStack(spacing: 6) {
                        Image(uiImage: iconImage(for: type))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                        Text(type.rawValue)
                            .font(.headline)
                    }
                    GeometryReader { geometry in
                        let totalWidth = geometry.size.width - 60 //막대 사이 너비가 10인것을 고려
                        let barWidth = totalWidth / 7
                        
                        let values = sixMonthStartDates.map { startDate in
                            let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)!
                            return pottyCount(type, from: startDate, to: endDate)
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
                .padding(.bottom, 20)
            }
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
        
    }
    func iconImage(for type: PottyType) -> UIImage {
        switch type {
        case .pee: return UIImage(named: "normalPee") ?? UIImage()
        case .poop: return UIImage(named: "normalPoop") ?? UIImage()
        }
    }
    func pottyCount(_ type: PottyType, from start: Date, to end: Date) -> Int {
        let recordsInRange = records.filter {
            $0.createdAt >= start && $0.createdAt < end
        }
        
        switch type {
        case .pee:
            return recordsInRange.filter { $0.title == .pee || $0.title == .pottyAll }.count
        case .poop:
            return recordsInRange.filter { $0.title == .poop || $0.title == .pottyAll }.count
        }
    }
    
    
    func shortMonthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월"
        return formatter.string(from: date)
    }

}
struct MonthlyPottyListView: View {
    
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
        let pottyCount = countPottyTypes(in: records, within: thisMonthRange)
        let yesterdaypottyCount = countPottyTypes(in: records, within: lastMonthRange)
        
        DetailPottyStatisticCardView(
            small: pottyCount.small,
            yesterdaysmall: yesterdaypottyCount.small,
            big: pottyCount.big,
            yesterdaybig: yesterdaypottyCount.big,
            mode : "monthly",
            selectedDate : selectedDate
        )
    }
    // 소변,배변 횟수 따로 셀리기
    func countPottyTypes(in records: [Record], within range: DateInterval) -> (small: Int, big: Int) {
        var small = 0
        var big = 0

        for record in records {
            guard range.contains(record.createdAt) else { continue }

            switch record.title {
            case .pee:
                small += 1
            case .poop:
                big += 1
            case .pottyAll:
                small += 1
                big += 1
            default:
                continue
            }
        }

        return (small, big)
    }
}
