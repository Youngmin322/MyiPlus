//
//  TimelineRow.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-12.
//

import SwiftUI
import FirebaseFirestore

struct TimelineRow: View {
    let record: Record
    let index: Int
    let totalCount: Int
    
    var showTopLine: Bool {
        if totalCount == 1 { return false }
        return index != 0
    }
    
    var showBottomLine: Bool {
        if totalCount == 1 { return false }
        return index != totalCount - 1
    }
    
    private var iconName: UIImage {
        switch record.title {
            case .formula: return .normalPowderedMilk
            case .babyFood: return .normalBabyMeal
            case .pumpedMilk: return .normalPumpedMilk
            case .breastfeeding: return .normalBreastFeeding
            case .diaper: return .colorDiaper
            case .sleep: return .colorSleep
            case .heightWeight: return .colorHeightWeight
            case .bath: return .colorBath
            case .snack: return .colorSnack
            case .temperature: return .normalTemperature
            case .medicine: return .normalMedicine
            case .clinic: return .colorCheckList
            case .poop: return .normalPoop
            case .pee: return .normalPee
            case .pottyAll: return .normalPotty
        }
    }
    private var title: String {
        switch record.title {
            case .formula:
                "분유"
            case .babyFood:
                "이유식"
            case .pumpedMilk:
                "유축수유"
            case .breastfeeding:
                "모유수유"
            case .diaper:
                "기저귀 교체"
            case .sleep:
                "수면"
            case .heightWeight:
                "키/몸무게"
            case .bath:
                "목욕"
            case .snack:
                "간식"
            case .temperature:
                "체온"
            case .medicine:
                "투약"
            case .clinic:
                "메모"
            case .poop:
                "대변"
            case .pee:
                "소변"
            case .pottyAll:
                "대소변"
        }
    }
    private var subtitle: String {
        switch record.title {
            case .formula, .pumpedMilk, .babyFood:
                return "\(record.mlAmount ?? 0)ml"
            case .breastfeeding:
                let left = record.breastfeedingLeftMinutes ?? 0
                let right = record.breastfeedingRightMinutes ?? 0
                return "왼쪽 \(left)분, 오른쪽 \(right)분"
            case .sleep:
                if let start = record.sleepStart, let end = record.sleepEnd {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MM/dd"
                    
                    let startDateStr = dateFormatter.string(from: start)
                    let endDateStr = dateFormatter.string(from: end)
                    let startTimeStr = start.to24HourTimeString()
                    let endTimeStr = end.to24HourTimeString()
                    
                    if startDateStr == endDateStr {
                        // 같은 날: 05/10 22:30 - 01:20
                        return "\(startDateStr) \(startTimeStr) - \(endTimeStr)"
                    } else {
                        // 다른 날: 05/10 22:30 - 05/11 01:20
                        return "\(startDateStr) \(startTimeStr) - \(endDateStr) \(endTimeStr)"
                    }
                } else if let start = record.sleepStart {
                    return "\(start.to24HourTimeString()) - (종료 기록 없음)"
                } else if let end = record.sleepEnd {
                    return "(시작 기록 없음) - \(end.to24HourTimeString())"
                } else {
                    return "시간 미기록"
                }
            case .heightWeight:
                if let height = record.height, let weight = record.weight {
                    return "키 \(String(format: "%.1f", height))cm, 몸무게 \(String(format: "%.1f", weight))kg"
                } else if let height = record.height {
                    return "키 \(String(format: "%.1f", height))cm"
                } else if let weight = record.weight {
                    return "몸무게 \(String(format: "%.1f", weight))kg"
                } else {
                    return "미기록"
                }
            case .temperature:
                if let temp = record.temperature {
                    return "\(String(format: "%.1f", temp))°C"
                }
                return "미기록"
            case .medicine, .clinic, .snack:
                return record.content ?? "메모 없음"
            case .poop, .pee, .pottyAll, .diaper, .bath:
                return record.content ?? "기록 완료"
        }
    }
    private var circleColor: Color {
        switch record.title {
            case .formula, .babyFood, .pumpedMilk, .breastfeeding: return .food
            case .diaper: return .diaper
            case .sleep: return .sleep
            case .heightWeight: return .heightWeight
            case .bath: return .bath
            case .snack: return .snack
            case .temperature, .medicine: return .health
            case .clinic: return .diaper
            case .pottyAll, .poop, .pee: return .potty
        }
    }
    
    var body: some View {
            HStack(alignment: .center, spacing: 12) {
                Text(record.createdAt.to24HourTimeString())
                    .font(.subheadline)
                    .frame(width: 50, alignment: .leading)
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(showTopLine ? Color.gray.opacity(0.4) : Color(uiColor: .tertiarySystemBackground))
                        .frame(width: 2, height: 25)
                    Circle()
                        .fill(circleColor)
                        .frame(width: 10, height: 10)
                    Rectangle()
                        .fill(showBottomLine ? Color.gray.opacity(0.4) : Color(uiColor: .tertiarySystemBackground))
                        .frame(width: 2, height: 25)
                }
                HStack(spacing: 8) {
                    Image(uiImage: iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(10)
            .contentShape(Rectangle())
            .padding(.trailing)
        }
}

#Preview {
    //    TimelineRow(record: Record.mockRecords[0])
}
