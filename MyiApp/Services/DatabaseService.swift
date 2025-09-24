//
//  DatabaseService.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-10.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

@MainActor
class DatabaseService: ObservableObject {
    @Published var hasBabyInfo: Bool? = false
    let auth = AuthService.shared
    let db = Firestore.firestore()
    let storage = Storage.storage()
    static let shared = DatabaseService()
    
    private init() {
        let settings = Firestore.firestore().settings
        settings.cacheSettings = MemoryCacheSettings()
        Firestore.firestore().settings = settings
    }
    
    func checkBabyInfo() async -> Bool {
        guard let uid = auth.user?.uid else { return false }
        do {
            let document = try await db.collection("users").document(uid).getDocument(source: .server)
            return (document.get("babies") as? [DocumentReference])?.isEmpty == false
        } catch {
            return false
        }
    }
    
    func saveBabyInfo(baby: Baby) async throws {
        let babyRef = db.collection("babies").document(baby.id.uuidString)
        // Codable을 사용해 Baby 객체를 직렬화
        let encoder = Firestore.Encoder()
        let data = try encoder.encode(baby)
        try await babyRef.setData(data)
        
        // 사용자 문서에 아기 참조 추가
        guard let uid = auth.user?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        let userDocRef = db.collection("users").document(uid)
        try await userDocRef.setData([
            "id": uid,
            "babies": FieldValue.arrayUnion([babyRef])
        ], merge: true)
        
        // 아기 문서에 보호자 참조 추가
        try await babyRef.setData([
            "caregivers": FieldValue.arrayUnion([userDocRef])
        ], merge: true)
        
        // 아기 정보가 추가되었으므로 hasBabyInfo 갱신
        self.hasBabyInfo = true
    }
    
    // 사용자 프로필 정보 저장
    func saveUserProfile(name: String, imageUrl: String?) async throws {
        guard let uid = auth.user?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        var data: [String: Any] = ["name": name]
        if let imageUrl = imageUrl, URL(string: imageUrl) != nil {
            data["imageUrl"] = imageUrl
        } else {
            data["imageUrl"] = FieldValue.delete()
        }
        try await db.collection("users").document(uid).setData(data, merge: true)
    }
    
    // 사용자 프로필 정보 가져오기
    func fetchUserProfile() async throws -> (name: String?, imageUrl: String?) {
        guard let uid = auth.user?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        let document = try await db.collection("users").document(uid).getDocument(source: .server)
        let name = document.get("name") as? String
        let imageUrl = document.get("imageUrl") as? String
        
        if let urlString = imageUrl, !urlString.isEmpty, URL(string: urlString) != nil {
            let storageRef = storage.reference(forURL: urlString)
            do {
                _ = try await storageRef.getMetadata()
                return (name, imageUrl)
            } catch {
                return (name, nil)
            }
        }
        return (name, nil)
    }
    
    // 사용자 프로필 사진 업로드
    func uploadProfileImage(_ image: UIImage) async throws -> String {
        guard let uid = auth.user?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        let storageRef = storage.reference().child("profile_images/\(uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadUrl = try await storageRef.downloadURL()
        return downloadUrl.absoluteString
    }
    
    // 아기 프로필 사진 업로드
    func uploadBabyImage(babyID: String, image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        let uuid = UUID().uuidString
        let ref = storage.reference().child("babyImages/\(babyID).\(uuid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let url = try await ref.downloadURL()
        try await db.collection("babies").document(babyID).updateData(["photoURL": url.absoluteString])
        return url.absoluteString
    }
    
    // 아기 프로필 사진 가져오기
    func fetchBabyImage(babyID: String) async throws -> String? {
        let docRef = Firestore.firestore().collection("babies").document(babyID)
        let snapshot = try await docRef.getDocument()
        
        guard let data = snapshot.data(),
                  let photoURL = data["photoURL"] as? String else {
                return nil
            }
        return photoURL
    }
    
    // 아기 프로필 사진 삭제
    func deleteBabyImage(babyID: String) async throws {
        let docRef = Firestore.firestore().collection("babies").document(babyID)
        try await docRef.updateData([
            "photoURL": FieldValue.delete()
        ])
    }
}
