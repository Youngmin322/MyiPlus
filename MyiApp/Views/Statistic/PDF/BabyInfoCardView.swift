//
//  BabyInfoCardView.swift
//  MyiApp
//
//  Created by 이민서 on 5/30/25.
//

import SwiftUI

struct BabyInfoCardView: View {
    let baby: Baby
    let records: [Record]
    var heightweightRecords: [Record] {
        records.filter { $0.title == .heightWeight }
    }
    var heightData: [(date: Date, height: Double)] {
        heightweightRecords.compactMap { record in
            guard let height = record.height else { return nil }
            return (record.createdAt, height)
        }
    }
    var weightData: [(date: Date, weight: Double)] {
        heightweightRecords.compactMap { record in
            guard let weight = record.weight else { return nil }
            return (record.createdAt, weight)
        }
    }
    let selectedDate: Date
    @State private var startDate: Date
    @State private var endDate: Date
    init(baby: Baby, records: [Record], selectedDate: Date) {
        self.baby = baby
        self.records = records
        self.selectedDate = selectedDate
        
        let calendar = Calendar(identifier: .gregorian)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
        components.weekday = 2
        
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: .day, value: 6, to: start)!
        
        _startDate = State(initialValue: start)
        _endDate = State(initialValue: end)
    }
    @State private var selectedHeightEntry: HeightEntry? = nil
    @State private var selectedWeightEntry: WeightEntry? = nil
    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("\(formattedDate(date: selectedDate)) \(baby.name)의 기록 분석")
                .font(.title2)
                .bold()
                .padding(.top, 30)
                .padding(.bottom, 30)
            Spacer()
            chartComparisonSection()
                .frame(height: 550)
            Spacer(minLength: 10)
            chartfoodSection()
                .frame(height: 450)
            sectionGroup(title: "배변 기록 분석", items: ["소변", "대변"])
                .frame(height: 200)
            Spacer(minLength: 10)
            sectionGroup(title: "수면 기록 분석", items: ["수면 횟수", "수면 시간"])
                .frame(height: 200)
            Spacer(minLength: 10)
            sectionGroup(title: "기타 관리", items: ["목욕", "간식"])
                .frame(height: 200)
            Spacer(minLength: 20)
        }
        .padding()
        .background(Color("customBackgroundColor"))
        
    }
    private func chartfoodSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("수유 / 이유식 기록 분석")
                .font(.headline)
            
            HStack(alignment: .top, spacing: 15) {
                VStack(spacing: 15) {
                    sectionCard(title: "분유")
                    sectionCard(title: "모유 수유")
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 15) {
                    sectionCard(title: "유축 수유")
                    sectionCard(title: "이유식")
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    private func chartComparisonSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("기록 비교")
                .font(.headline)
            
            HStack(alignment: .top, spacing: 15) {
                VStack(spacing: 15) {
                    sectionCard(title: "일별")
                    sectionCard(title: "키")
                    sectionCard(title: "몸무게")
                }
                .frame(maxWidth: .infinity)
                
                sectionCard(title: "주별")
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func sectionGroup(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack(alignment: .top, spacing: 15) {
                ForEach(items, id: \.self) { item in
                    sectionCard(title: item)
                        .frame(maxWidth: .infinity)
                }
                
            }
        }
    }
    
    private func sectionCard(title: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            if title == "일별" {
                DailyChartView(baby: baby, records: records,  selectedDate: selectedDate, selectedCategories: ["수유/이유식", "기저귀", "배변", "수면", "목욕", "간식"])
                    .scaleEffect(0.4, anchor: .center)
                    .frame(width: 320, height: 130)
                    .padding()
            } else if title == "주별" {
                WeeklyChartView(baby: baby, records: records,  selectedDate: selectedDate, selectedCategories: ["수유/이유식", "기저귀", "배변", "수면", "목욕", "간식"])
                    .frame(height: 505)
                    .padding(.vertical)
            } else if title == "키" {
                HeightChartView(
                    data: heightData,
                    startDate: startDate,
                    endDate: endDate,
                    selectedEntry: $selectedHeightEntry
                )
                .frame(width: 450, height: 300)
                .scaleEffect(0.5, anchor: .center)
                .frame(width: 320, height: 100)
                .padding()
            } else if title == "몸무게" {
                WeightChartView(
                    data: weightData,
                    startDate: startDate,
                    endDate: endDate,
                    selectedEntry: $selectedWeightEntry
                )
                .frame(width: 450, height: 300)
                .scaleEffect(0.5, anchor: .center)
                .frame(width: 320, height: 100)
                .padding()

            } else if title == "분유" {
                DailyFeedChartPDFView(
                    weekDates: generateWeekDates(from: selectedDate),
                    records: records,
                    selectedType: .formula
                )
                .frame(width: 450, height: 300)
                .scaleEffect(0.7, anchor: .center)
                .frame(width: 320, height: 100)
                .padding()

            } else if title == "모유 수유" {
                DailyFeedChartPDFView(
                    weekDates: generateWeekDates(from: selectedDate),
                    records: records,
                    selectedType: .breastfeeding
                )
                .frame(width: 450, height: 300)
                .scaleEffect(0.7, anchor: .center)
                .frame(width: 320, height: 100)
                .padding()

            } else if title == "유축 수유" {
                DailyFeedChartPDFView(
                    weekDates: generateWeekDates(from: selectedDate),
                    records: records,
                    selectedType: .pumpedMilk
                )
                .frame(width: 450, height: 300)
                .scaleEffect(0.7, anchor: .center)
                .frame(width: 320, height: 100)
                .padding()

            } else if title == "이유식" {
                DailyFeedChartPDFView(
                    weekDates: generateWeekDates(from: selectedDate),
                    records: records,
                    selectedType: .babyFood
                )
                .frame(width: 450, height: 300)
                .scaleEffect(0.7, anchor: .center)
                .frame(width: 320, height: 100)
                .padding()

            } else if title == "소변" {
                DailyPottyChartPDFView(
                    weekDates: generateWeekDates(from: selectedDate),
                    records: records,
                    selectedType: .pee
                )
                .frame(width: 450, height: 300)
                .scaleEffect(0.7, anchor: .center)
                .frame(width: 320, height: 100)
                .padding()

            } else if title == "대변" {
                DailyPottyChartPDFView(
                    weekDates: generateWeekDates(from: selectedDate),
                    records: records,
                    selectedType: .poop
                )
                .frame(width: 450, height: 300)
                .scaleEffect(0.7, anchor: .center)
                .frame(width: 320, height: 100)
                .padding()

            } else if title == "수면 횟수" {
                DailySleepChartPDFView(
                    weekDates: generateWeekDates(from: selectedDate),
                    records: records,
                    selectedType: .count
                )
                .frame(width: 450, height: 300)
                .scaleEffect(0.7, anchor: .center)
                .frame(width: 320, height: 100)
                .padding()

            } else if title == "수면 시간" {
                DailySleepChartPDFView(
                    weekDates: generateWeekDates(from: selectedDate),
                    records: records,
                    selectedType: .time
                )
                .frame(width: 450, height: 300)
                .scaleEffect(0.7, anchor: .center)
                .frame(width: 320, height: 100)
                .padding()

            } else if title == "목욕" {
                DailyBathChartPDFView(
                    weekDates: generateWeekDates(from: selectedDate),
                    records: records
                )
                .frame(width: 450, height: 300)
                .scaleEffect(0.7, anchor: .center)
                .frame(width: 320, height: 100)
                .padding()

            } else if title == "간식" {
                DailySnackChartPDFView(
                    weekDates: generateWeekDates(from: selectedDate),
                    records: records
                )
                .frame(width: 450, height: 300)
                .scaleEffect(0.7, anchor: .center)
                .frame(width: 320, height: 100)
                .padding()

            }
        }
        .padding(.top)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: date)
    }
    func generateWeekDates(from selectedDate: Date) -> [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 월요일 시작
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
}
