import SwiftUI
import FirebaseFirestore

class EditRecordViewModel: ObservableObject {
    @Published var record: Record
    @Published var isLeftMinutesPickerActionSheetPresent = false
    @Published var isRightMinutesPickerActionSheetPresent = false
    @Published var isMLPickerActionSheetPresent = false
    @Published var isTMPickerActionSheetPresent = false
    @Published var showDeleteAlert = false
    let caregiverManager = CaregiverManager.shared
    
    init(record: Record) {
        self.record = record
    }
    
    var navigationTitle: String {
        switch record.title {
            case .formula, .babyFood, .pumpedMilk, .breastfeeding:
                return "수유/이유식 기록"
            case .diaper:
                return "기저귀 기록"
            case .sleep:
                return "수면 기록"
            case .heightWeight:
                return "키/몸무게 기록"
            case .bath:
                return "목욕 기록"
            case .snack:
                return "간식 기록"
            case .temperature, .medicine:
                return "건강 관리 기록"
            case .poop, .pee, .pottyAll:
                return "배변 기록"
            case .clinic:
                return "메모"
        }
    }

    func updateRecordTitle(_ title: TitleCategory) {
        record.title = title
        record.content = nil
        record.mlAmount = nil
        record.breastfeedingLeftMinutes = nil
        record.temperature = nil
        record.weight = nil
        record.height = nil
        if record.title == .temperature {
            record.temperature = 36.5
        }
    }
    
    func saveRecord() {
        let babyId = caregiverManager.selectedBaby?.id.uuidString ?? ""
        if record.title == .sleep {
            record.createdAt = record.sleepStart!
        }
        let _ = Firestore.firestore().collection("babies").document(babyId).collection("records").document(record.id.uuidString).setData(from: record)
        if record.title == .heightWeight {
            saveHeightWeight()
        }
    }
    
    func deleteRecord() {
        let babyId = caregiverManager.selectedBaby?.id.uuidString ?? ""
        let _ = Firestore.firestore().collection("babies").document(babyId).collection("records").document(record.id.uuidString).delete { error in
            print(error ?? "")
        }
    }
    
    func saveHeightWeight() {
        guard let babyId = caregiverManager.selectedBaby?.id.uuidString else { return }
                let records = caregiverManager.records.filter { $0.title == .heightWeight }
        if let latestRecord = records.first,
           latestRecord.createdAt > record.createdAt {
            return
        }
        
        var updateData: [String: Any] = [:]
        if let height = record.height {
            updateData["height"] = height
        }
        if let weight = record.weight {
            updateData["weight"] = weight
        }
        let _ = Firestore.firestore().collection("babies").document(babyId).updateData(updateData)
        Task {
           await caregiverManager.loadCaregiverInfo()
        }
    }
}
