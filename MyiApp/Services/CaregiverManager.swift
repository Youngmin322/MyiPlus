//
//  CaregiverManager.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-14.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine

class CaregiverManager: ObservableObject {
    @Published var caregiver: Caregiver?
    @Published var babies: [Baby] = []
    @Published var selectedBaby: Baby? {
        didSet {
            if let selectedBaby = selectedBaby {
                Task {
                    await updateLastSelectedBaby(selectedBaby.id.uuidString)
                }
            }
            cancellables.removeAll()
            subscribeToRecords()
            subscribeToNotes()
            subscribeToVoiceRecords()
        }
    }
    private let db = Firestore.firestore()
    private var cancellables: Set<AnyCancellable> = []
    static let shared = CaregiverManager()
    @Published var userName: String? = nil
    @Published var email: String? = nil
    @Published var provider: String? = nil
    @Published var records: [Record] = []
    @Published var voiceRecords: [VoiceRecord] = []
    @Published var notes: [Note] = []
    private init() { }
    
    
    func loadCaregiverInfo() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        if let caregiver = await loadCaregiver(uid: uid) {
            let userRef = db.collection("users").document(uid)
            let invalidBabyRefs: [DocumentReference] = []
            let babies = await loadBabies(from: caregiver.babies)
            
            // 유효하지 않은 아기 참조 제거
            Task {
                if !invalidBabyRefs.isEmpty {
                    try? await userRef.updateData([
                        "babies": FieldValue.arrayRemove(invalidBabyRefs)
                    ])
                    print("유효하지 않은 아기 참조 제거: \(invalidBabyRefs.map { $0.documentID })")
                }
            }
            
            await MainActor.run {
                self.caregiver = caregiver
                self.babies = babies
                
                // 마지막으로 선택된 아기 ID 불러오기
                if let lastSelectedBabyId = caregiver.lastSelectedBabyId,
                   let lastSelectedBaby = babies.first(where: { $0.id.uuidString == lastSelectedBabyId }) {
                    self.selectedBaby = lastSelectedBaby
                } else {
                    self.selectedBaby = babies.first
                }
                
                self.userName = caregiver.name
                self.email = caregiver.email
                self.provider = caregiver.provider
            }
        } else {
            print("Error from CaregiverManager.loadCaregiverInfo")
            await saveCaregiverInfo()
        }
    }
    
    @MainActor
    func saveCaregiverInfo() async {
        guard let user = Auth.auth().currentUser else { return }
        let userRef = db.collection("users").document(user.uid)
        if let existingCaregiver = try? await userRef.getDocument().data(as: Caregiver.self) {
            // 기존 데이터 존재하면 유지
            self.caregiver = existingCaregiver
            self.userName = existingCaregiver.name
            self.email = existingCaregiver.email
            self.provider = existingCaregiver.provider
        } else {
            // 신규 사용자 데이터 저장
            let caregiver = Caregiver(
                id: user.uid,
                name: user.displayName,
                email: user.email,
                provider: user.providerData.first?.providerID,
                babies: []
            )
            let _ = userRef.setData(from: caregiver)
            self.caregiver = caregiver
            self.userName = caregiver.name
            self.email = caregiver.email
            self.provider = caregiver.provider
        }
    }
    
    private func subscribeToRecords() {
        guard let babyId = selectedBaby?.id else { return }
        db.collection("babies").document(babyId.uuidString).collection("records")
            .order(by: "createdAt", descending: true)
            .snapshotPublisher()
            .map { snapshot in
                snapshot.documents.compactMap { try? $0.data(as: Record.self) }
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: \.records, on: self)
            .store(in: &cancellables)
    }
    
    private func subscribeToNotes() {
        guard let babyId = selectedBaby?.id else { return }
        db.collection("babies").document(babyId.uuidString).collection("notes")
            .order(by: "createdAt", descending: true)
            .snapshotPublisher()
            .map { snapshot in
                snapshot.documents.compactMap { try? $0.data(as: Note.self) }
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: \.notes, on: self)
            .store(in: &cancellables)
    }
    
    private func subscribeToVoiceRecords() {
        guard let babyId = selectedBaby?.id else { return }
        db.collection("babies").document(babyId.uuidString).collection("voiceRecords")
            .order(by: "createdAt", descending: true)
            .snapshotPublisher()
            .map { snapshot in
                snapshot.documents.compactMap { try? $0.data(as: VoiceRecord.self) }
            }
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .assign(to: \.voiceRecords, on: self)
            .store(in: &cancellables)
    }
    
    private func loadCaregiver(uid: String) async -> Caregiver? {
        try? await Firestore.firestore().collection("users")
            .document(uid).getDocument().data(as: Caregiver.self)
    }
    
    private func loadBabies(from refs: [DocumentReference]) async -> [Baby] {
        await withTaskGroup(of: Baby?.self) { group in
            for ref in refs {
                group.addTask {
                    try? await ref.getDocument().data(as: Baby.self)
                }
            }
            var babies: [Baby] = []
            for ref in refs {
                if let baby = try? await ref.getDocument().data(as: Baby.self) {
                    babies.append(baby)
                }
            }
            return babies
        }
    }
    
    @MainActor
    func logout() {
        caregiver = nil
        babies = []
        selectedBaby = nil
        records = []
        voiceRecords = []
        notes = []
        userName = nil
        email = nil
        provider = nil
    }
    
    // 회원탈퇴 시 회원 데이터 삭제
    func deleteUserData(uid: String) async throws {
        let userRef = db.collection("users").document(uid)
        let document = try await userRef.getDocument()
        
        guard document.exists, let caregiver = try? document.data(as: Caregiver.self) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "사용자 데이터를 찾을 수 없거나 디코딩 실패"])
        }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for babyRef in caregiver.babies {
                group.addTask {
                    let babyDoc = try await babyRef.getDocument()
                    guard let babyData = babyDoc.data(),
                          let caregivers = babyData["caregivers"] as? [DocumentReference],
                          let mainCaregiverId = babyData["mainCaregiver"] as? String else {
                        return
                    }
                    
                    let babyId = babyRef.documentID
                    
                    if mainCaregiverId == uid {
                        try await babyRef.delete()
                        let babyId = babyRef.documentID
                        let collections = ["records", "notes", "voiceRecords"]
                        for collection in collections {
                            let querySnapshot = try await self.db.collection("babies").document(babyId).collection(collection).getDocuments()
                            for document in querySnapshot.documents {
                                try await document.reference.delete()
                            }
                        }
                        
                        for caregiverRef in caregivers where caregiverRef.documentID != uid {
                            try await caregiverRef.updateData([
                                "babies": FieldValue.arrayRemove([babyRef])
                            ])
                            
                            let caregiverDoc = try await caregiverRef.getDocument()
                            if let caregiverData = caregiverDoc.data(),
                               let lastSelected = caregiverData["lastSelectedBabyId"] as? String,
                               lastSelected == babyId {
                                try await caregiverRef.updateData([
                                    "lastSelectedBabyId": FieldValue.delete()
                                ])
                            }
                        }
                    } else {
                        
                        // 메인 보호자가 아닌 경우: 참조만 제거
                        try await babyRef.updateData([
                            "caregivers": FieldValue.arrayRemove([userRef])
                        ])
                        
                        try await userRef.updateData([
                            "babies": FieldValue.arrayRemove([babyRef])
                        ])
                        
                        // 호출자의 lastSelectedBabyId 확인 및 삭제
                        if caregiver.lastSelectedBabyId == babyId {
                            try await userRef.updateData([
                                "lastSelectedBabyId": FieldValue.delete()
                            ])
                        }
                    }
                }
            }
            try await group.waitForAll()
        }
        try await userRef.delete()
        await logout()
        
        print("회원 데이터 및 관련 아기 데이터 삭제 성공")
    }
    
    // 아기 데이터 삭제
    func deleteBaby(_ baby: Baby) async throws {
        guard Auth.auth().currentUser != nil else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "로그인 상태가 아닙니다."])
        }
        let babyRef = db.collection("babies").document(baby.id.uuidString)
        
        do {
            // 아기 문서에서 caregivers 배열 가져오기
            let babyDoc = try await babyRef.getDocument()
            guard let babyData = babyDoc.data(), let caregivers = babyData["caregivers"] as? [DocumentReference] else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "아기 데이터를 찾을 수 없습니다."])
            }
            // caregiverId: lastSelectedBabyId
            var caregiverLastSelected: [String: String?] = [:]
            for caregiverRef in caregivers {
                let caregiverDoc = try await caregiverRef.getDocument()
                if let caregiverData = caregiverDoc.data(),
                   let lastSelected = caregiverData["lastSelectedBabyId"] as? String {
                    caregiverLastSelected[caregiverRef.documentID] = lastSelected
                } else {
                    caregiverLastSelected[caregiverRef.documentID] = nil
                }
            }
            
            // 트랜잭션으로 아기 데이터와 모든 보호자의 참조 제거
            _ = try await db.runTransaction { transaction, errorPointer in
                transaction.deleteDocument(babyRef)
                // 모든 보호자의 babies 배열과 lastSelectedBabyId 업데이트
                for caregiverRef in caregivers {
                    transaction.updateData([
                        "babies": FieldValue.arrayRemove([babyRef])
                    ], forDocument: caregiverRef)
                    // lastSelectedBabyId가 삭제된 아기 UID와 일치하면 제거
                    if caregiverLastSelected[caregiverRef.documentID] ?? nil == baby.id.uuidString {
                        transaction.updateData([
                            "lastSelectedBabyId": FieldValue.delete()
                        ], forDocument: caregiverRef)
                    }
                }
                
                return nil
            }
            let collections = ["records", "notes", "voiceRecords"]
            for collection in collections {
                let querySnapshot = try await babyRef.collection(collection).getDocuments()
                for document in querySnapshot.documents {
                    try await document.reference.delete()
                }
            }
            await MainActor.run {
                self.babies.removeAll { $0.id == baby.id }
                if self.selectedBaby?.id == baby.id {
                    self.selectedBaby = self.babies.first
                }
            }
            print("아기 데이터 삭제 성공: \(baby.name)")
        } catch {
            print("아기 데이터 삭제 실패: \(error)")
            throw error
        }
    }
    
    private func updateLastSelectedBaby(_ babyId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("users").document(uid)
        try? await userRef.updateData(["lastSelectedBabyId": babyId])
    }
    
    func registerBabyUUID(_ babyId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let babyRef = db.collection("babies").document(babyId)
        let userRef = db.collection("users").document(userId)
        
        guard let baby = try? await babyRef.getDocument().data(as: Baby.self) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "해당 코드를 가진 아기를 찾을 수 없습니다."])
        }
        
        if babies.contains(where: { $0.id.uuidString == babyId }) {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "이미 등록된 아기입니다."])
        }
        
        try await userRef.updateData([
            "babies": FieldValue.arrayUnion([babyRef])
        ])
        try await babyRef.updateData([
            "caregivers": FieldValue.arrayUnion([userRef])
        ])
        
        await MainActor.run {
            self.babies.append(baby)
            if self.selectedBaby == nil {
                self.selectedBaby = baby
            }
        }
    }
    
    // 사용자와 아이 연결 끊기
    func disconnectFromBaby(_ baby: Baby) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "로그인 상태가 아닙니다."])
        }
        
        let babyRef = db.collection("babies").document(baby.id.uuidString)
        let userRef = db.collection("users").document(currentUserId)
        
        do {
            // 트랜잭션으로 연결 해제 처리
            _ = try await db.runTransaction { transaction, errorPointer in
                // 아기 문서에서 현재 사용자 참조 제거
                transaction.updateData([
                    "caregivers": FieldValue.arrayRemove([userRef])
                ], forDocument: babyRef)
                
                // 사용자 문서에서 아기 참조 제거
                transaction.updateData([
                    "babies": FieldValue.arrayRemove([babyRef])
                ], forDocument: userRef)
                
                // 마지막 선택된 아기가 현재 아기인 경우 제거
                if self.caregiver?.lastSelectedBabyId == baby.id.uuidString {
                    transaction.updateData([
                        "lastSelectedBabyId": FieldValue.delete()
                    ], forDocument: userRef)
                }
                
                return nil
            }
            
            // 로컬 상태 업데이트
            await MainActor.run {
                self.babies.removeAll { $0.id == baby.id }
                if self.selectedBaby?.id == baby.id {
                    self.selectedBaby = self.babies.first
                }
            }
            
            print("아이와의 연결 해제 성공: \(baby.name)")
        } catch {
            print("아이와의 연결 해제 실패: \(error)")
            throw error
        }
    }
    
    // 사용자와 아이 연결 끊기
    func removeCaregiver(baby: Baby, caregiverId: String) async throws {
        guard (Auth.auth().currentUser?.uid) != nil else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "로그인 상태가 아닙니다."])
        }
        
        let babyRef = db.collection("babies").document(baby.id.uuidString)
        let caregiverRef = db.collection("users").document(caregiverId)
        
        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                transaction.updateData([
                    "caregivers": FieldValue.arrayRemove([caregiverRef])
                ], forDocument: babyRef)
                transaction.updateData([
                    "babies": FieldValue.arrayRemove([babyRef])
                ], forDocument: caregiverRef)
                return nil
            }
            
            await MainActor.run {
                if let index = self.babies.firstIndex(where: { $0.id == baby.id }) {
                    self.babies[index].caregivers.removeAll { $0.documentID == caregiverId }
                }
            }
        }
    }
}
