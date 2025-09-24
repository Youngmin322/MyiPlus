//
//  NoteListenerService.swift
//  MyiApp
//
//  Created by Saebyeok Jang on 5/20/25.
//

import Foundation
import FirebaseFirestore
import Combine

class NoteListenerService: ObservableObject {
    @Published var notes: [Note] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private var listeners: [ListenerRegistration] = []
    
    @MainActor
    func startListening(babyId: String) {
        stopListening()
        isLoading = true
        
        setupListener(babyId: babyId, category: "일지")
        setupListener(babyId: babyId, category: "일정")
    }
    
    @MainActor
    private func setupListener(babyId: String, category: String) {
        let listener = Firestore.firestore()
            .collection("babies").document(babyId)
            .collection("records")
            .whereField("category", isEqualTo: category)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.error = "데이터 가져오기 실패: \(error.localizedDescription)"
                        self.isLoading = false
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.isLoading = false
                        return
                    }
                    
                    let newNotes = documents.compactMap { document -> Note? in
                        try? document.data(as: Note.self)
                    }
                    
                    let otherCategoryNotes = self.notes.filter { $0.category.rawValue != category }
                    self.notes = otherCategoryNotes + newNotes
                    self.notes.sort { $0.createdAt > $1.createdAt }
                    
                    self.isLoading = false
                }
            }
        
        listeners.append(listener)
    }
    
    func stopListening() {
        for listener in listeners {
            listener.remove()
        }
        listeners.removeAll()
    }
    
    deinit {
        stopListening()
    }
}
