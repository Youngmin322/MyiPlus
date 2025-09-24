//
//  HomeViewModel.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-08.
//

import Foundation
import SwiftUI
//import Combine
import FirebaseFirestore

class HomeViewModel: ObservableObject {
    @Published var baby: Baby?
    @Published var records: [Record] = []
    @Published var selectedDate: Date = Date()
    @Published var recordToEdit: Record?
    @Published var recordToDelete: Record?
    @Published var isPresented: Bool = false

    var displaySharkImage: UIImage {
        guard let birthDate = baby?.birthDate else {
            return UIImage(resource: .sharkNewBorn)
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        guard let months = calendar.dateComponents([.month], from: birthDate, to: now).month,
              let days = calendar.dateComponents([.day], from: birthDate, to: now).day else {
            return UIImage(resource: .sharkNewBorn)
        }
        
        switch months {
        case 0 where days < 28:
                return UIImage(resource: .sharkNewBorn)
        case 0...11:
                return UIImage(resource: .sharkInfant)
        case 12...35:
                return UIImage(resource: .sharkToddler)
        default:
                return UIImage(resource: .sharkChild)
        }
    }
    let caregiverManager = CaregiverManager.shared
    var displayName: String {
        baby?.name ?? "loading..."
    }
    var displayGender: UIImage {
        baby?.gender.rawValue == 1 ? .babyMale : .babyFemale
    }
    var displayBirthDate: String {
        guard let baby else { return "알 수 없음" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: baby.birthDate)
    }
    var displayBloodType: String {
        guard let baby else { return "알 수 없음" }
        return "\(baby.bloodType.rawValue) 형"
    }
    var displayHeightWeight: String {
        guard let baby else { return "알 수 없음" }
        let heightText = String(format: "%.1f", baby.height)
        let weightText = String(format: "%.1f", baby.weight)
        
        return "\(heightText) cm / \(weightText) kg"
    }
    var displayDevelopmentalStage: String {
        guard let birthDate = baby?.birthDate else { return "알 수 없음" }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.month, .day], from: birthDate, to: now)
        
        guard let months = components.month,
              let days = components.day else {
            return "알 수 없음"
        }
        
        if months == 0 && days < 30 {
            return "신생아기"
        } else if months < 12 {
            return "영아기"
        } else if months < 36 {
            return "유아기"
        } else {
            return "아동기"
        }
    }
    var displayDayCount: String {
        let days = Calendar.current.dateComponents([.day], from: baby?.birthDate ?? Date(), to: Date()).day ?? 0
        return "\(days + 1)일"
    }
    var filteredRecords: [Record] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        
        let filtered = records.compactMap { record -> Record? in
            // 기본적인 날짜 필터링
            let isInSelectedDay = record.createdAt >= startOfDay && record.createdAt < endOfDay
            
            // 수면 기록의 경우
            if record.title == .sleep,
               let sleepStart = record.sleepStart,
               let sleepEnd = record.sleepEnd {
                let sleepStartDay = calendar.startOfDay(for: sleepStart)
                let sleepEndDay = calendar.startOfDay(for: sleepEnd)
                
                // 시작 시간이 선택된 날짜인 경우
                if sleepStartDay == startOfDay {
                    return record
                }
                // 종료 시간이 선택된 날짜인 경우
                if sleepEndDay == startOfDay {
                    // 종료 시간을 기준으로 정렬하기 위해 새로운 Record 객체 생성
                    var newRecord = record
                    newRecord.createdAt = sleepEnd
                    return newRecord
                }
            }
            
            return isInSelectedDay ? record : nil
        }
        
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }
    var recentMeal: Record? {
        let mealCategories: [TitleCategory] = [.formula, .babyFood, .pumpedMilk, .breastfeeding]
        return records
            .filter { mealCategories.contains($0.title) }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    var recentPotty: Record? {
        let pottyCategories: [TitleCategory] = [.poop, .pee, .pottyAll]
        return records
            .filter { pottyCategories.contains($0.title) }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    var recentSnack: Record? {
        return records
            .filter { $0.title == .snack }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    var recentHealth: Record? {
        let healthCategories: [TitleCategory] = [.temperature, .medicine]
        return records
            .filter { healthCategories.contains($0.title) }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    init() {
        CaregiverManager.shared.$selectedBaby
            .assign(to: &$baby)
        CaregiverManager.shared.$records
            .assign(to: &$records)
    }
    
    func gridItemDidTap(title: TitleCategory) {
        switch title {
            case .breastfeeding:
                if let recentMeal {
                    let newRecord = Record(
                        id: UUID(),
                        createdAt: Date(),
                        title: recentMeal.title,
                        mlAmount: recentMeal.mlAmount,
                        breastfeedingLeftMinutes: recentMeal.breastfeedingLeftMinutes,
                        breastfeedingRightMinutes: recentMeal.breastfeedingRightMinutes
                    )
                    saveRecord(record: newRecord)
                } else {
                    saveRecord(record: Record(title: .breastfeeding))
                }
            case .diaper:
                saveRecord(record: Record(title: .diaper))
            case .pee:
                if let recentPotty = recentPotty {
                    let newRecord = Record(
                        id: UUID(),
                        createdAt: Date(),
                        title: recentPotty.title
                    )
                    saveRecord(record: newRecord)
                } else {
                    saveRecord(record: Record(title: .pee))
                }
            case .sleep:
                let calendar = Calendar.current
                let selectedDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                let currentTimeComponents = calendar.dateComponents([.hour, .minute, .second], from: Date())
                
                var combinedComponents = DateComponents()
                combinedComponents.year = selectedDateComponents.year
                combinedComponents.month = selectedDateComponents.month
                combinedComponents.day = selectedDateComponents.day
                combinedComponents.hour = currentTimeComponents.hour
                combinedComponents.minute = currentTimeComponents.minute
                combinedComponents.second = currentTimeComponents.second
                
                if let combinedDate = calendar.date(from: combinedComponents) {
                    saveRecord(record: Record(title: .sleep, sleepStart: combinedDate))
                }
            case .heightWeight:
                saveRecord(record: Record(title: .heightWeight))
            case .bath:
                saveRecord(record: Record(title: .bath))
            case .snack:
                if let recentSnack = recentSnack {
                    let newRecord = Record(
                        id: UUID(),
                        createdAt: Date(),
                        title: recentSnack.title,
                        content: recentSnack.content
                    )
                    saveRecord(record: newRecord)
                } else {
                    saveRecord(record: Record(title: .snack))
                }
            case .temperature:
                if let recentHealth = recentHealth {
                    let newRecord = Record(
                        id: UUID(),
                        createdAt: Date(),
                        title: recentHealth.title,
                        temperature: recentHealth.temperature,
                        content: recentHealth.content
                    )
                    saveRecord(record: newRecord)
                } else {
                    saveRecord(record: Record(title: .temperature, temperature: 36.5))
                }
            case .clinic:
                saveRecord(record: Record(title: .clinic))
            default:
                print(title)
        }
        
    }
    
    func saveRecord(record: Record) {
        guard let baby else { return }
        var recordToSave = record
        recordToSave.createdAt = Date().replacingDate(with: selectedDate)
        let _ = Firestore.firestore().collection("babies").document(baby.id.uuidString).collection("records").document(record.id.uuidString).setData(from: recordToSave)
    }
    
    func babyChangeButtonDidTap(baby: Baby) {
        caregiverManager.selectedBaby = baby
    }
    
    func deleteRecord(_ record: Record, completion: ((Error?) -> Void)? = nil) {
        guard let baby else { return }
        Firestore.firestore().collection("babies").document(baby.id.uuidString).collection("records").document(record.id.uuidString).delete { error in
            if let error = error {
                print("Error deleting record: \(error.localizedDescription)")
                completion?(error)
            } else {
                print("Record successfully deleted")
                completion?(nil)
            }
        }
    }
    
    func updateSelectedDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    func toggleBabyFullScreenCard() {
        isPresented.toggle()
    }
}


