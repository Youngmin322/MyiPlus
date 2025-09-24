//
//  ConnectedUserView.swift
//  MyiApp
//
//  Created by Yung Hak Lee on 6/8/25.
//

import SwiftUI
import FirebaseFirestore

struct ConnectedUserView: View {
    let baby: Baby
    @State private var caregivers: [Caregiver] = []
    @State private var selectedCaregiver: Caregiver?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Form {
            if caregivers.isEmpty {
                ProgressView()
            } else {
                ForEach(caregivers, id: \.id) { caregiver in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(caregiver.name ?? "이름 없음")
                                .font(.headline)
                            if let email = caregiver.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        if caregiver.id == baby.mainCaregiver {
                            Image(systemName: "crown.fill")
                                .font(.headline)
                                .foregroundColor(.yellow)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if caregiver.id != baby.mainCaregiver && CaregiverManager.shared.caregiver?.id == baby.mainCaregiver {
                            Button(role: .destructive) {
                                selectedCaregiver = caregiver
                                showingDeleteAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.customBackground)
        .navigationTitle("연결된 사용자")
        .onAppear {
            loadCaregivers()
        }
        .alert("보호자 삭제", isPresented: $showingDeleteAlert) {
            Button("삭제", role: .destructive) {
                if let caregiver = selectedCaregiver {
                    Task {
                        try await CaregiverManager.shared.removeCaregiver(baby: baby, caregiverId: caregiver.id)
                        caregivers.removeAll { $0.id == caregiver.id }
                        selectedCaregiver = nil
                    }
                }
            }
            Button("취소", role: .cancel) {
                selectedCaregiver = nil
            }
        } message: {
            Text("'\(selectedCaregiver?.name ?? "알 수 없음")' 님을 보호자 목록에서 삭제합니다.")
        }
    }
    
    private func loadCaregivers() {
        let mainCaregiverId = baby.mainCaregiver
        Task {
            do {
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(mainCaregiverId)
                let userDoc = try await userRef.getDocument()
                
                guard let userData = userDoc.data(),
                      let babiesRefs = userData["babies"] as? [DocumentReference] else {
                    print("메인 보호자의 babies 배열 없음")
                    return
                }
                
                let babyRef = db.collection("babies").document(baby.id.uuidString)
                let babyDoc = try await babyRef.getDocument()
                guard let babyData = babyDoc.data(),
                      let caregiverRefs = babyData["caregivers"] as? [DocumentReference] else {
                    print("아기의 caregivers 배열 없음")
                    return
                }
                
                var loadedCaregivers: [Caregiver] = []
                let caregiverIds = caregiverRefs.map { $0.documentID }
                
                for babyRef in babiesRefs {
                    let babyDoc = try await babyRef.getDocument()
                    if let babyData = babyDoc.data(),
                       let caregivers = babyData["caregivers"] as? [DocumentReference] {
                        for caregiverRef in caregivers {
                            if caregiverIds.contains(caregiverRef.documentID),
                               !loadedCaregivers.contains(where: { $0.id == caregiverRef.documentID }) {
                                if let caregiver = try? await caregiverRef.getDocument().data(as: Caregiver.self) {
                                    loadedCaregivers.append(caregiver)
                                }
                            }
                        }
                    }
                }
                
                // UI 업데이트
                await MainActor.run {
                    self.caregivers = loadedCaregivers
                }
            } catch {
                print("보호자 로드 실패: \(error.localizedDescription)")
            }
        }
    }
}
