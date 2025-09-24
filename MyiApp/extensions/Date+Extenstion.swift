//
//  Date+Extenstion.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-11.
//

import Foundation

extension Date {
    
    func to24HourTimeString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR") // 24시간제 보장
        formatter.dateFormat = "HH:mm" // 24시간제 포맷
        return formatter.string(from: self)
    }
    
    func formattedKoreanDateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        
        if Calendar.current.isDateInToday(self) {
            formatter.dateFormat = "MM월 dd일 '(오늘)'"
        } else {
            formatter.dateFormat = "MM월 dd일 (E)"
        }
        
        return formatter.string(from: self)
    }
    
    func formattedFullKoreanDateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일 (E)"
        return formatter.string(from: self)
    }
    
    func replacingDate(with date: Date) -> Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: self)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        var newComponents = DateComponents()
        newComponents.year = dateComponents.year
        newComponents.month = dateComponents.month
        newComponents.day = dateComponents.day
        newComponents.hour = timeComponents.hour
        newComponents.minute = timeComponents.minute
        newComponents.second = timeComponents.second
        newComponents.nanosecond = timeComponents.nanosecond
        
        return calendar.date(from: newComponents) ?? self
    }
}
