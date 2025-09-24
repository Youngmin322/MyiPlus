//
//  UserProfileViewModel.swift
//  MyiApp
//
//  Created by Yung Hak Lee on 5/13/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI

@MainActor
class AccountEditViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var profileImage: UIImage?
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isProfileSaved: Bool = false
    
    private let databaseService = DatabaseService.shared
    private let caregiverManager = CaregiverManager.shared
    private let imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }()
    
    static let shared = AccountEditViewModel()
    private init() {}
    
    // 초기 프로필 데이터 로드
    func loadProfile() async {
        await MainActor.run {
            self.isLoading = true
        }
        await caregiverManager.loadCaregiverInfo()
        await MainActor.run {
            self.name = self.caregiverManager.userName ?? self.caregiverManager.email ?? ""
        }
        await MainActor.run {
            self.isLoading = false
        }
    }
    
//    // 프로필 사진 선택 시 처리
//    func loadSelectedPhoto() async {
//        guard let selectedPhoto = selectedPhoto else { return }
//        do {
//            if let data = try await selectedPhoto.loadTransferable(type: Data.self),
//               let image = UIImage(data: data) {
//                await MainActor.run {
//                    self.profileImage = image
//                }
//            } else {
//                await MainActor.run {
//                    self.errorMessage = "Failed to load selected photo"
//                }
//            }
//        } catch {
//            await MainActor.run {
//                self.errorMessage = "Failed to load photo: \(error.localizedDescription)"
//            }
//        }
//    }
    
    // 프로필 저장
    func saveProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            await MainActor.run {
                self.errorMessage = "로그인된 사용자가 없습니다."
            }
            return
        }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty {
            await MainActor.run {
                self.errorMessage = "이름을 입력해주세요."
                self.isProfileSaved = false
            }
            return
        }
        await MainActor.run {
            self.isLoading = true
            self.isProfileSaved = false
        }
        do {
            let data: [String: Any] = [
                "name": trimmedName,
                "email": caregiverManager.email ?? "",
                "provider": caregiverManager.provider ?? ""
            ]
            try await databaseService.db.collection("users").document(uid).setData(data, merge: true)
            await MainActor.run {
                self.caregiverManager.userName = trimmedName
                self.caregiverManager.email = data["email"] as? String
                self.caregiverManager.provider = data["provider"] as? String
                self.isProfileSaved = true
            }
        } catch {
            await MainActor.run {
                self.caregiverManager.userName = self.name
                self.isProfileSaved = true
            }
        }
        await MainActor.run {
            self.isLoading = false
        }
    }
}
