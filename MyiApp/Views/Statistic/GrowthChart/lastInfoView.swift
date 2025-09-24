//
//  lastInfoView.swift
//  MyiApp
//
//  Created by 이민서 on 5/29/25.
//

import SwiftUI

struct lastHeightInfoView: View {
    let data: [(date: Date, height: Double)]
    
    var body: some View {
        if let recent = data.sorted(by: { $0.date > $1.date }).first {
            VStack(spacing: 4) {
                Text("최근 키 측정")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Text("\(longDate(recent.date)) / \(String(format: "%.1f", recent.height))cm")
                    .font(.subheadline)
            }
        }
    }
    func longDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy년 M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}
struct lastWeightInfoView: View {
    let data: [(date: Date, weight: Double)]
    
    var body: some View {
        if let recent = data.sorted(by: { $0.date > $1.date }).first {
            VStack(spacing: 4) {
                Text("최근 몸무게 측정")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Text("\(longDate(recent.date)) / \(String(format: "%.1f", recent.weight))kg")
                    .font(.subheadline)
            }
        }
    }
    func longDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy년 M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}
