//
//  BabyProfileViewModel.swift
//  MyiApp
//
//  Created by Yung Hak Lee on 5/20/25.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore


@MainActor
class BabyProfileViewModel: ObservableObject {
    @Published var baby: Baby
    @Published var babyImage: UIImage?
    @Published var selectedImage: PhotosPickerItem?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isProfileSaved: Bool = false
    
    private let originalBaby: Baby
    private let databaseService = DatabaseService.shared
    private let imageCache = NSCache<NSString, UIImage>()
    
    init(baby: Baby) {
        self.baby = baby
        self.originalBaby = baby
    }
    
    // 초기 프로필 이미지 데이터 로드
    func loadBabyProfileImage() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            if baby.photoURL == nil {
                if let url = try await databaseService.fetchBabyImage(babyID: baby.id.uuidString) {
                    baby.photoURL = url
                }
            }
            babyImage = nil
            guard let imageUrl = baby.photoURL, let url = URL(string: imageUrl) else {
                babyImage = nil
                return
            }
            if let cachedImage = imageCache.object(forKey: imageUrl as NSString) {
                babyImage = cachedImage
                return
            }
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
            }
            
            guard httpResponse.statusCode == 200 else {
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"])
            }
            
            guard let image = UIImage(data: data) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert data to image"])
            }
            
            self.imageCache.setObject(image, forKey: imageUrl as NSString)
            self.babyImage = image
        } catch {
            self.errorMessage = "Failed to load profile: \(error.localizedDescription) (Code: \((error as NSError).code))"
            self.babyImage = nil
        }
    }
    
    // 프로필 사진 선택 시 처리
    func loadSelectedBabyImage() async {
        guard let selectedImage = selectedImage else { return }
        do {
            if let data = try await selectedImage.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                self.babyImage = image
            }
            await saveBabyImage()
        } catch {
            self.errorMessage = "이미지 처리 실패: \(error.localizedDescription)"
        }
    }
    
    // 프로필 사진 저장
    func saveBabyImage() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let babyImage = babyImage {
                let imageUrl = try await databaseService.uploadBabyImage(babyID: baby.id.uuidString, image: babyImage)
                self.baby.photoURL = imageUrl
                await loadBabyProfileImage()
            } else {
                try await databaseService.deleteBabyImage(babyID: baby.id.uuidString)
                self.baby.photoURL = nil
            }
            self.errorMessage = nil
            self.isProfileSaved = true
        } catch {
            self.errorMessage = "프로필 저장 실패: \(error.localizedDescription)"
            self.isProfileSaved = false
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: date)
    }
    
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h시 mm분"
        return formatter.string(from: date)
    }
    
    // 프로필 변경
    func saveProfileEdits() async {
        isLoading = true
        defer { isLoading = false }
        
        let babyID = baby.id.uuidString
        let babyData: [String: Any] = [
            "name": baby.name,
            "birth_date": Timestamp(date: baby.birthDate),
            "gender": baby.gender.rawValue,
            "height": baby.height,
            "weight": baby.weight,
            "blood_type": baby.bloodType.rawValue,
        ]
        
        let trimmedName = baby.name.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty {
            await MainActor.run {
                self.errorMessage = "이름을 입력해주세요."
                self.isProfileSaved = false
                self.baby = self.originalBaby
            }
            return
        }
        await MainActor.run {
            self.isLoading = true
            self.isProfileSaved = false
        }
        do {
            try await databaseService.db.collection("babies").document(babyID).setData(babyData, merge: true)
            self.errorMessage = nil
            self.isProfileSaved = true
        } catch {
            self.errorMessage = "프로필 저장 실패: \(error.localizedDescription)"
            self.isProfileSaved = false
            self.baby = self.originalBaby
        }
    }
    
    // 프로필 편집 취소 기능
    func resetChanges() {
        baby = originalBaby
        babyImage = nil
        selectedImage = nil
        Task { await loadBabyProfileImage() }
    }
    
    //숫자 포맷팅
    func formatNumber(_ value: Double) -> String {
        if floor(value) == value {
            return String(format: "%.0f", value)
        } else {
            let formatted = String(format: "%.2f", value)
            return formatted.trimmingCharacters(in: CharacterSet(charactersIn: "0"))
        }
    }
    
    var displaySharkImage: UIImage {
        let birthDate = baby.birthDate
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
}
