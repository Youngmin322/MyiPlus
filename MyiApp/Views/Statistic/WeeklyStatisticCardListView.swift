//
//  DailyStatisticCardListView.swift
//  MyiApp
//
//  Created by 이민서 on 5/12/25.
//

import SwiftUI

struct WeeklyStatisticCardListView: View {
    
    let baby: Baby
    let records: [Record]
    
    var birthDate: Date {
        baby.birthDate
    }
    
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
        
        Group {
            StatisticCardView(
                title: "분유/수유/이유식 기록 분석",
                image: .colorMeal,
                color: Color("food"),
                count: combinedFeedCount(in: records, within: thisWeekRange),
                lastcount: combinedFeedCount(in: records, within: lastWeekRange),
                amount: totalMlAmount(in: records, within: thisWeekRange),
                lastamount: totalMlAmount(in: records, within: lastWeekRange),
                time: totalBreastfeedingMinutes(in: records, within: thisWeekRange),
                lasttime: totalBreastfeedingMinutes(in: records, within: lastWeekRange),
                mode : "weekly",
                baby: baby,
                records: records
            )
            PottyStatisticCardView(
                small: pottyCount.small,
                yesterdaysmall: yesterdaypottyCount.small,
                big: pottyCount.big,
                yesterdaybig: yesterdaypottyCount.big,
                mode : "weekly",
                baby: baby,
                records: records
            )
            
            StatisticCardView(
                title: "수면 기록 분석",
                image: .colorSleep,
                color: Color("sleep"),
                count: recordsCount(for: .sleep, in: records, within: thisWeekRange),
                lastcount: recordsCount(for: .sleep, in: records, within: lastWeekRange),
                amount: nil,
                lastamount: nil,
                time: totalSleepMinutes(in: records, within: thisWeekRange),
                lasttime: totalSleepMinutes(in: records, within: lastWeekRange),
                mode : "weekly",
                baby: baby,
                records: records
            )
            
            StatisticCardView(
                title: "목욕 기록 분석",
                image: .colorBath,
                color: Color("bath"),
                count: recordsCount(for: .bath, in: records, within: thisWeekRange),
                lastcount: recordsCount(for: .bath, in: records, within: lastWeekRange),
                amount: nil,
                lastamount: nil,
                time: nil,
                lasttime: nil,
                mode : "weekly",
                baby: baby,
                records: records
            )
            
            StatisticCardView(
                title: "간식 기록 분석",
                image: .colorSnack,
                color: Color("snack"),
                count: recordsCount(for: .snack, in: records, within: thisWeekRange),
                lastcount: recordsCount(for: .snack, in: records, within: lastWeekRange),
                amount: nil,
                lastamount: nil,
                time: nil,
                lasttime: nil,
                mode : "weekly",
                baby: baby,
                records: records
            )
        }
    }
    // 카테고리 받아서 횟수 셀리기
    func recordsCount(for title: TitleCategory, in records: [Record], within range: DateInterval) -> Int {
        return records.filter {
                $0.title == title && range.contains($0.createdAt)
            }.count
    }
    // ml 총계
    func totalMlAmount(in records: [Record], within range: DateInterval) -> Int {
        return records
            .filter {
                [.formula, .babyFood, .pumpedMilk].contains($0.title) &&
                range.contains($0.createdAt)
            }
            .compactMap { $0.mlAmount }
            .reduce(0, +)
    }
    // 모유 수유 시간 총계
    func totalBreastfeedingMinutes(in records: [Record], within range: DateInterval) -> Int {
        return records
            .filter {
                $0.title == .breastfeeding && range.contains($0.createdAt)
            }
            .reduce(0) { total, record in
                let left = record.breastfeedingLeftMinutes ?? 0
                let right = record.breastfeedingRightMinutes ?? 0
                return total + left + right
            }
    }
    // 밥먹은 횟수 따로 셀리기
    func combinedFeedCount(in records: [Record], within range: DateInterval) -> Int {
        return records.filter {
            [.formula, .pumpedMilk, .breastfeeding, .babyFood].contains($0.title) &&
            range.contains($0.createdAt)
        }.count
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
    // 수면 시간 총계
    func totalSleepMinutes(in records: [Record], within range: DateInterval) -> Int? {
        let totalMinutes = records
            .filter { $0.title == .sleep }
            .compactMap { record -> Int? in
                guard let start = record.sleepStart, let end = record.sleepEnd else { return nil }

                // 수면이 지정된 범위를 넘는 경우 잘라서 계산
                let clippedStart = max(start, range.start)
                let clippedEnd = min(end, range.end)

                let interval = clippedEnd.timeIntervalSince(clippedStart)
                return interval > 0 ? Int(interval / 60) : nil
            }
            .reduce(0, +)

        return totalMinutes >= 0 ? totalMinutes : nil
    }

}
