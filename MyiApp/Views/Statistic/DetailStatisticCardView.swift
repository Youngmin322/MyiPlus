//
//  StatisticCardView.swift
//  MyiApp
//
//  Created by 이민서 on 5/12/25.
//

import SwiftUI

struct DetailStatisticCardView: View {
    let title: String
    let image: UIImage
    let color: Color
    let count: Int
    let lastcount : Int
    let amount: Int?
    let lastamount : Int?
    let time: Int?
    let lasttime: Int?
    let mode : String
    let selectedDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if (mode == "daily") {
                    Text("\(formattedDate(selectedDate))")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                } else if (mode == "weekly") {
                    Text("\(formattedDate(weekStartDate(from: selectedDate))) ~ \(formattedDate(weekEndDate(from: selectedDate)))")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                } else {
                    Text("\(formattedMonth(selectedDate))")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                }
            }
            comparisonMessage(for: image, count: count, lastCount: lastcount)
            
            Divider()
            
            //횟수 수유 기저귀 수면 목욕 간식
            //용량 수유
            //시간 수유 수면
            VStack(alignment: .leading, spacing: 15) {
                Text("횟수 \(count)회")
                ProgressComparisonBar(today: count, yesterday: lastcount, color: color, unit: "회", mode: mode)
                
                // 수유/이유식일경우
                if (image == .colorMeal) {
                    if let amount = amount, let yesterdayamount = lastamount {
                        
                        Text("용량 \(amount)ml")
                        ProgressComparisonBar(today: amount, yesterday: yesterdayamount, color: color, unit: "ml", mode: mode)
                        
                        Text("시간 \(formattedTime(from: time))")
                        
                        ProgressComparisonBar(today: time, yesterday: lasttime, color: color, unit: "분", mode: mode)
                    }
                }
                
                // 수면일경우
                if (image == .colorSleep) {
                    Text("시간 \(formattedTime(from: time))")
                    ProgressComparisonBar(today: time, yesterday: lasttime, color: color, unit: "분", mode: mode)
                }
                
            }
            .font(.subheadline)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
    func formattedTime(from minutes: Int?) -> String {
        guard let m = minutes else { return "-시간-분" }
        let h = m / 60
        let min = m % 60
        return h > 0 ? "\(h)시간 \(min)분" : "\(min)분"
    }
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }
    func weekStartDate(from date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }
    func weekEndDate(from date: Date) -> Date {
        let startOfWeek = weekStartDate(from: date)
        return Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? date
    }
    func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: date)
    }

    func comparisonMessage(for image: UIImage, count: Int, lastCount: Int) -> Text {
        switch image {
        case UIImage.colorMeal:
            return feedingComparisonMessage(count: count, lastCount: lastCount)
        case UIImage.colorSleep:
            return sleepComparisonMessage(count: count, lastCount: lastCount)
        case UIImage.colorBath:
            return bathComparisonMessage(count: count, lastCount: lastCount)
        case UIImage.colorSnack:
            return snackComparisonMessage(count: count, lastCount: lastCount)
        default:
            return Text("") // 기본값
        }
    }
    
    func feedingComparisonMessage(count: Int, lastCount: Int) -> Text {
        let label: String
        switch mode {
        case "daily":
            label = "어제보다"
        case "weekly":
            label = "지난주보다"
        default:
            label = "지난달보다"
        }
        
        let text = count > lastCount
        ? "\(label) 수유 횟수가 증가하였습니다."
        : "\(label) 수유 횟수가 감소하였습니다."
        
        return Text(text)
            .font(.subheadline)
            .foregroundColor(.gray)
        
    }
    func sleepComparisonMessage(count: Int, lastCount: Int) -> Text {
        if let time = time, let lasttime = lasttime {
            let label: String
            switch mode {
            case "daily":
                label = "어제보다"
            case "weekly":
                label = "지난주보다"
            default:
                label = "지난달보다"
            }
            
            let text = time > lasttime
            ? "\(label) 수면 시간이 증가하였습니다."
            : "\(label) 수면 시간이 감소하였습니다."
            
            return Text(text)
                .font(.subheadline)
                .foregroundColor(.gray)
        } else {
            return Text("수면 시간 정보를 확인할 수 없습니다.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }

    }
    func bathComparisonMessage(count: Int, lastCount: Int) -> Text {
        let label: String
        switch mode {
        case "daily":
            label = "어제보다"
        case "weekly":
            label = "지난주보다"
        default:
            label = "지난달보다"
        }
        
        let text = count > lastCount
        ? "\(label) 목욕 횟수가 증가하였습니다."
        : "\(label) 목욕 횟수가 감소하였습니다."
        
        return Text(text)
            .font(.subheadline)
            .foregroundColor(.gray)
    }
    func snackComparisonMessage(count: Int, lastCount: Int) -> Text {
        let label: String
        switch mode {
        case "daily":
            label = "어제보다"
        case "weekly":
            label = "지난주보다"
        default:
            label = "지난달보다"
        }
        
        let text = count > lastCount
        ? "\(label) 간식을 먹은 횟수가 증가하였습니다."
        : "\(label) 간식을 먹은 횟수가 감소하였습니다."
        
        return Text(text)
            .font(.subheadline)
            .foregroundColor(.gray)
    }

}
//배변은 카드를 따로 만듦
struct DetailPottyStatisticCardView: View {
    let small: Int
    let yesterdaysmall: Int
    let big: Int
    let yesterdaybig: Int
    let mode: String
    let selectedDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(uiImage: .colorPotty)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                if (mode == "daily") {
                    Text("일별 기록 분석")
                        .font(.headline)
                        .foregroundColor(.primary)
                } else if (mode == "weekly") {
                    Text("주별 기록 분석")
                        .font(.headline)
                        .foregroundColor(.primary)
                } else {
                    Text("월별 기록 분석")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                Spacer()
                if (mode == "daily") {
                    Text("\(formattedDate(selectedDate))")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                } else if (mode == "weekly") {
                    Text("\(formattedDate(weekStartDate(from: selectedDate))) ~ \(formattedDate(weekEndDate(from: selectedDate)))")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                } else {
                    Text("\(formattedMonth(selectedDate))")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                }
            }
            pottyComparisonMessage(small: small, yesterdaysmall: yesterdaysmall, big: big, yesterdaybig: yesterdaybig)
            
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                
                Text("소변 \(small)회")
                ProgressComparisonBar(today: small, yesterday: yesterdaysmall, color: Color("potty"), unit: "회", mode: mode)
                
                Text("대변 \(big)회")
                ProgressComparisonBar(today: big, yesterday: yesterdaybig, color: Color("potty"), unit: "회", mode: mode)
                
            }
            .font(.subheadline)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
    func formattedTime(from minutes: Int?) -> String {
        guard let m = minutes else { return "-시간-분" }
        let h = m / 60
        let min = m % 60
        return h > 0 ? "\(h)시간 \(min)분" : "\(min)분"
    }
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }
    func weekStartDate(from date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }
    func weekEndDate(from date: Date) -> Date {
        let startOfWeek = weekStartDate(from: date)
        return Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? date
    }
    func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: date)
    }
    func pottyComparisonMessage(small: Int, yesterdaysmall: Int, big: Int, yesterdaybig: Int) -> Text {
        let label: String
        switch mode {
        case "daily":
            label = "어제보다"
        case "weekly":
            label = "지난주보다"
        default:
            label = "지난달보다"
        }
        
        let smallText = small > yesterdaysmall
        ? "\(label) 소변 횟수가 증가,"
        : "\(label) 소변 횟수가 감소,"
        
        let bigText = big > yesterdaybig
        ? " 대변 횟수가 증가하였습니다."
        : " 대변 횟수가 감소하였습니다."
        
        return Text(smallText + bigText)
            .font(.subheadline)
            .foregroundColor(.gray)
        
    }
}
