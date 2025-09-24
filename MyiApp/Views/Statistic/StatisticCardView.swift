//
//  StatisticCardView.swift
//  MyiApp
//
//  Created by 이민서 on 5/12/25.
//

import SwiftUI

struct StatisticCardView: View {
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
    
    let baby: Baby
    
    let records: [Record]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(destination: destinationView(for: title, baby: baby)) {
                HStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            
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
    
}
//배변은 카드를 따로 만듦
struct PottyStatisticCardView: View {
    let small: Int
    let yesterdaysmall: Int
    let big: Int
    let yesterdaybig: Int
    let mode: String
    
    let baby: Baby
    
    let records: [Record]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(destination: destinationView(for: "배변 기록 분석", baby: baby)) {
                HStack {
                    Image(uiImage: .colorPotty)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                    Text("배변 기록 분석")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            VStack(alignment: .leading, spacing: 15) {
                
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
}

@ViewBuilder
func destinationView(for title: String, baby: Baby) -> some View {
    switch title {
    case "분유/수유/이유식 기록 분석":
        FoodDetailView(baby: baby)
    case "수면 기록 분석":
        SleepDetailView(baby: baby)
    case "목욕 기록 분석":
        BathDetailView(baby: baby)
    case "간식 기록 분석":
        SnackDetailView(baby: baby)
    case "배변 기록 분석":
        PottyDetailView(baby: baby)
    default:
        EmptyView()
    }
}
