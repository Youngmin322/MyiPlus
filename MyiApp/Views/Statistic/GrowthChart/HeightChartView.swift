//
//  HeightChartView.swift
//  MyiApp
//
//  Created by 이민서 on 5/29/25.
//

import SwiftUI

struct HeightChartView: View {
    let data: [(date: Date, height: Double)]
    let startDate: Date
    let endDate: Date
    
    @Binding var selectedEntry: HeightEntry?
    @State private var selectedPosition: CGPoint? = nil

    var body: some View {
        GeometryReader { geometry in
            let filteredData = data.filter { $0.date >= startDate && $0.date <= endDate }
            let sortedData = filteredData.sorted { $0.date < $1.date }

            if let lastDate = sortedData.last?.date,
               let minHeight = sortedData.map({ $0.height }).min(),
               let maxHeight = sortedData.map({ $0.height }).max(),
               maxHeight > minHeight {

                let dateRangeInterval = endDate.timeIntervalSince(startDate)
                let intervalStep = dateRangeInterval / 9.0
                let desiredDates: [Date] = (0..<10).map {
                    startDate.addingTimeInterval(Double($0) * intervalStep)
                }

                let cappedData: [HeightEntry] = desiredDates.enumerated().compactMap { (idx, targetDate) in
                    sortedData.min(by: {
                        //절댓값
                        abs($0.date.timeIntervalSince(targetDate)) < abs($1.date.timeIntervalSince(targetDate))
                    }).map { entry in
                        HeightEntry(index: idx, date: entry.date, height: entry.height)
                    }
                }

                let firstDate = startDate
                let dateRange = endDate.timeIntervalSince(firstDate)
                let heightRange = maxHeight - minHeight
                let oneThirdDate = firstDate.addingTimeInterval(dateRange / 3)
                let twoThirdDate = firstDate.addingTimeInterval(dateRange * 2 / 3)
                let roundedMin = floor(minHeight)
                let roundedMax = ceil(maxHeight)
                GeometryReader { geo in
                    let width = geo.size.width
                    VStack() {
                        if let entry = selectedEntry {
                            let x = CGFloat(entry.date.timeIntervalSince(firstDate) / dateRange) * width
                            
                            let relativePosition = entry.date.timeIntervalSince(startDate) / dateRange
                            let xOffset: CGFloat = relativePosition < 0.2 ? 70 :
                                                   relativePosition > 0.8 ? -70 : 0
                            VStack(alignment: .leading) {
                                Text("날짜 : \(longDate(entry.date))")
                                    .font(.footnote)
                                Text("키 : \(String(format: "%.1f", entry.height))cm")
                                    .font(.footnote)
                            }
                            .padding(6)
                            .frame(minWidth: 150, minHeight: 80)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("buttonColor"), lineWidth: 1)
                            )
                            .position(x: x + xOffset , y: 40)
                            .zIndex(1)
                            
                        }
                        VStack(spacing: 8) {
                            
                            HStack(alignment: .top) {
                                VStack {
                                    Text("\(Int(roundedMax))")
                                    Spacer()
                                    Text("\(Int(roundedMax - heightRange * 1/3))")
                                    Spacer()
                                    Text("\(Int(roundedMax - heightRange * 2/3))")
                                    Spacer()
                                    Text("\(Int(roundedMin))")
                                }
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .frame(width: 30)
                                // 세로축 기준선
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 1)

                                ZStack(alignment: .topTrailing) {
                                    GeometryReader { geo in
                                        let width = geo.size.width
                                        let height = geo.size.height
                                        ZStack {

                                            // 선
                                            Path { path in
                                                for (index, entry) in cappedData.enumerated() {
                                                    let x = CGFloat(entry.date.timeIntervalSince(firstDate) / dateRange) * width
                                                    let y = height - ((CGFloat(entry.height - minHeight) / CGFloat(heightRange)) * height)
                                                    index == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
                                                }
                                            }
                                            .stroke(Color("buttonColor"), lineWidth: 2)
                                            //.stroke(Color.gray, lineWidth: 2)

                                            // 강조된 점
                                            ForEach(cappedData, id: \.id) { entry in
                                                let x = CGFloat(entry.date.timeIntervalSince(firstDate) / dateRange) * width
                                                let y = height - ((CGFloat(entry.height - minHeight) / CGFloat(heightRange)) * height)
                                                Circle()
                                                    //.fill(selectedEntry?.id == entry.id ? Color("buttonColor") : Color.gray)
                                                    .fill(Color("buttonColor"))
                                                    .frame(width: 10, height: 10)
                                                    .position(x: x, y: y)
                                                    .onTapGesture {
                                                        if selectedEntry?.id == entry.id {
                                                            selectedEntry = nil
                                                        } else {
                                                            selectedEntry = entry
                                                        }
                                                    }
                                                
                                            }
                                            // 선택된 점의 선
                                            if let entry = selectedEntry {
                                                let x = CGFloat(entry.date.timeIntervalSince(firstDate) / dateRange) * width
                                                let y = height + 50
                                                
                                                Rectangle()
                                                    //.fill(Color("buttonColor"))
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 1, height: y)
                                                    .position(x: x, y: y / 2 - 50)
                                                    .zIndex(-1)
                                            }

                                        }
                                        
                                    }
                                    
                                }
                            }
                            .frame(height: 200)
                            .padding(.leading, 4)
                            
                            

                            // 가로축 기준선
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)

                            HStack {
                                Text(shortDate(startDate))
                                Spacer()
                                Text(shortDate(oneThirdDate))
                                Spacer()
                                Text(shortDate(twoThirdDate))
                                Spacer()
                                Text(shortDate(lastDate))
                            }
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 4)
                            .padding(.leading, 35)
                        }
                        .padding()
                        .offset(y: selectedEntry == nil ? 0 : 100)
                        .animation(.easeInOut, value: selectedEntry)
                    }
                }
                
                
                
                
            } else {
                Text("데이터가 부족합니다.")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy. M. d"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    func longDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy년 M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}
