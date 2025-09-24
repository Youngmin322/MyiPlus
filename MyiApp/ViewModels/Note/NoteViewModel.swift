//
//  NoteViewModel.swift
//  MyiApp
//
//  Created by Saebyeok Jang on 5/20/25.
//

import SwiftUI
import FirebaseFirestore
import Combine
import FirebaseStorage
import UIKit
import Kingfisher

@MainActor
class NoteViewModel: ObservableObject {
    private let db = Firestore.firestore()
    private let authService = AuthService.shared
    private let databaseService = DatabaseService.shared
    private let caregiverManager = CaregiverManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var selectedMonth: Date = Date()
    @Published var days: [CalendarDay] = []
    @Published var weekdays: [String] = ["일", "월", "화", "수", "목", "금", "토"]
    @Published var selectedDay: CalendarDay?
    
    @Published var events: [Date: [Note]] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var toastMessage: ToastMessage?
    
    var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: selectedMonth)
    }
    
    init() {
        fetchCalendarDays()
        
        caregiverManager.$notes
            .receive(on: RunLoop.main)
            .sink { [weak self] notes in
                self?.processNotes(notes)
            }
            .store(in: &cancellables)
    }
    
    private func processNotes(_ notes: [Note]) {
        var newEvents: [Date: [Note]] = [:]
        let calendar = Calendar.current
        
        for note in notes {
            let startOfDay = calendar.startOfDay(for: note.date)
            if var dayNotes = newEvents[startOfDay] {
                dayNotes.append(note)
                dayNotes.sort { $0.date < $1.date }
                newEvents[startOfDay] = dayNotes
            } else {
                newEvents[startOfDay] = [note]
            }
        }
        
        self.events = newEvents
        self.isLoading = false
    }
    
    func addNoteLocallyWithImages(_ note: Note, localImages: [UIImage]) {
        var noteWithLocalImages = note
        noteWithLocalImages.localImages = localImages
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: note.date)
        
        if var dayNotes = events[startOfDay] {
            dayNotes.append(noteWithLocalImages)
            dayNotes.sort { $0.date < $1.date }
            events[startOfDay] = dayNotes
        } else {
            events[startOfDay] = [noteWithLocalImages]
        }
    }
    
    func removeNoteLocally(_ noteId: UUID) {
        for (date, notes) in events {
            let filteredNotes = notes.filter { $0.id != noteId }
            if filteredNotes.count != notes.count {
                events[date] = filteredNotes.isEmpty ? nil : filteredNotes
                break
            }
        }
    }
    
    func saveNoteOptimistically(_ note: Note, images: [UIImage] = [], isEditing: Bool = false, imagesToDelete: [String] = []) async throws {
        if !images.isEmpty && note.category == .일지 {
            if isEditing {
                invalidateImageCache(for: note.imageURLs)
                
                updateNoteWithImagesAndDeletions(
                    note: note,
                    newImages: images,
                    imagesToDelete: imagesToDelete
                )
            } else {
                let uploadedURLs = try await uploadImagesAsync(images)
                var updatedNote = note
                updatedNote.imageURLs = uploadedURLs
                try await saveNoteToFirestoreOnly(updatedNote)
            }
        } else {
            if isEditing {
                invalidateImageCache(for: imagesToDelete)
                
                updateNoteWithDeletions(note: note, imagesToDelete: imagesToDelete)
            } else {
                try await saveNoteToFirestoreOnly(note)
            }
        }
    }
    
    private func invalidateImageCache(for urls: [String]) {
        urls.forEach { urlString in
            guard let url = URL(string: urlString) else { return }
            
            let resource = KF.ImageResource(downloadURL: url)
            KingfisherManager.shared.cache.removeImage(
                forKey: resource.cacheKey,
                fromMemory: true,
                fromDisk: true
            )
        }
    }
    
    func saveNoteToFirestoreOnly(_ note: Note) async throws {
        guard let baby = caregiverManager.selectedBaby else {
            throw NSError(domain: "BabyInfo", code: 0, userInfo: [NSLocalizedDescriptionKey: "아기 정보가 없습니다"])
        }
        
        let docRef = db.collection("babies").document(baby.id.uuidString)
            .collection("notes")
            .document(note.id.uuidString)
        
        let encoder = Firestore.Encoder()
        let data = try encoder.encode(note)
        try await docRef.setData(data)
    }
    
    private func uploadImagesAsync(_ images: [UIImage]) async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            uploadImages(images) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func updateNote(note: Note) {
        guard let baby = caregiverManager.selectedBaby else { return }
        
        isLoading = true
        
        let docRef = db.collection("babies").document(baby.id.uuidString)
            .collection("notes")
            .document(note.id.uuidString)
        
        do {
            let encoder = Firestore.Encoder()
            let data = try encoder.encode(note)
            
            docRef.setData(data, merge: true) { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if error != nil {
                        self.errorMessage = "노트 업데이트 실패"
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "노트 인코딩 실패"
            }
        }
    }
    
    func deleteNote(note: Note) {
        cancelNotificationForNote(note)
        
        guard let baby = caregiverManager.selectedBaby else { return }
        
        isLoading = true
        
        db.collection("babies").document(baby.id.uuidString)
            .collection("notes")
            .document(note.id.uuidString)
            .delete { [weak self] error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if error != nil {
                        self.errorMessage = "노트 삭제 실패"
                    }
                }
            }
    }
    
    func getEventsForDay(_ day: CalendarDay) -> [Note] {
        guard let date = day.date else { return [] }
        let startOfDay = Calendar.current.startOfDay(for: date)
        return (events[startOfDay] ?? []).sorted { $0.date < $1.date }
    }
    
    func fetchCalendarDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let startComponents = calendar.dateComponents([.year, .month], from: selectedMonth)
        guard let startDate = calendar.date(from: startComponents) else { return }
        guard let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) else { return }
        
        let firstWeekday = firstWeekdayOfMonth(for: startDate)
        
        var calendarDays: [CalendarDay] = []
        
        if firstWeekday > 1 {
            for day in 1..<firstWeekday {
                if let prevDate = calendar.date(byAdding: .day, value: -(firstWeekday - day), to: startDate) {
                    let dayNumber = String(calendar.component(.day, from: prevDate))
                    calendarDays.append(CalendarDay(
                        id: UUID(),
                        date: prevDate,
                        dayNumber: dayNumber,
                        isToday: calendar.isDate(prevDate, inSameDayAs: today),
                        isCurrentMonth: false
                    ))
                }
            }
        }
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: startDate)?.count ?? 0
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startDate) {
                let dayNumber = String(day)
                calendarDays.append(CalendarDay(
                    id: UUID(),
                    date: date,
                    dayNumber: dayNumber,
                    isToday: calendar.isDate(date, inSameDayAs: today),
                    isCurrentMonth: true
                ))
            }
        }
        
        let remainingDays = 42 - calendarDays.count
        for day in 1...remainingDays {
            if let nextDate = calendar.date(byAdding: .day, value: day, to: endDate) {
                let dayNumber = String(calendar.component(.day, from: nextDate))
                calendarDays.append(CalendarDay(
                    id: UUID(),
                    date: nextDate,
                    dayNumber: dayNumber,
                    isToday: calendar.isDate(nextDate, inSameDayAs: today),
                    isCurrentMonth: false
                ))
            }
        }
        
        self.days = calendarDays
    }
    
    func firstWeekdayOfMonth(for date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstDay = calendar.date(from: components) else { return 1 }
        return calendar.component(.weekday, from: firstDay)
    }
    
    func changeMonth(by amount: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: amount, to: selectedMonth) {
            selectedMonth = newMonth
            fetchCalendarDays()
            
            if let firstDay = days.first(where: { $0.isCurrentMonth && Calendar.current.component(.day, from: $0.date!) == 1 }) {
                selectedDay = firstDay
            }
        }
    }
    
    func isBirthday(_ date: Date?) -> Bool {
        guard let date = date, let birthDate = caregiverManager.selectedBaby?.birthDate else { return false }
        
        let calendar = Calendar.current
        let birthDay = calendar.component(.day, from: birthDate)
        let birthMonth = calendar.component(.month, from: birthDate)
        
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        
        return birthDay == day && birthMonth == month
    }
    
    func is100Days(_ date: Date?) -> Bool {
        guard let date = date, let birthDate = caregiverManager.selectedBaby?.birthDate else { return false }
        
        let calendar = Calendar.current
        if let hundredDaysDate = calendar.date(byAdding: .day, value: 99, to: birthDate) {
            return calendar.isDate(date, inSameDayAs: hundredDaysDate)
        }
        return false
    }
    
    func isFirstBirthday(_ date: Date?) -> Bool {
        guard let date = date, let birthDate = caregiverManager.selectedBaby?.birthDate else { return false }
        
        let calendar = Calendar.current
        if let firstBirthdayDate = calendar.date(byAdding: .year, value: 1, to: birthDate) {
            return calendar.isDate(date, inSameDayAs: firstBirthdayDate)
        }
        return false
    }
    
    func getAnniversaryType(_ date: Date?) -> AnniversaryType? {
        guard let date = date else { return nil }
        
        if isFirstBirthday(date) {
            return .firstBirthday
        }
        else if is100Days(date) {
            return .hundredDays
        }
        else if isBirthday(date) {
            return .birthday
        }
        
        return nil
    }
    
    func selectToday() {
        selectedMonth = Date()
        
        fetchCalendarDays()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            if let todayDay = self.days.first(where: { $0.isToday }) {
                self.selectedDay = todayDay
            }
        }
    }
    
    func refreshData() {
        selectToday()
    }
    
    func getNoteById(_ id: UUID) -> Note? {
        for (_, notes) in events {
            if let note = notes.first(where: { $0.id == id }) {
                return note
            }
        }
        return nil
    }
    
    func updateNoteNotification(noteId: UUID, enabled: Bool, time: Date?) {
        guard let note = getNoteById(noteId) else { return }
        
        let updatedNote = Note(
            id: noteId,
            title: note.title,
            description: note.description,
            date: note.date,
            category: note.category,
            imageURLs: note.imageURLs,
            notificationEnabled: enabled,
            notificationTime: time
        )
        
        updateNote(note: updatedNote)
    }
}

// MARK: - Image Upload Extension
extension NoteViewModel {
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "이미지 변환 실패"])))
            return
        }
        
        guard authService.user != nil, let babyId = caregiverManager.selectedBaby?.id else {
            completion(.failure(NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "인증 정보가 없음"])))
            return
        }
        
        let filename = UUID().uuidString + ".jpg"
        let storageRef = Storage.storage().reference().child("images/\(babyId.uuidString)/\(filename)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            guard metadata != nil else {
                completion(.failure(error ?? NSError(domain: "UploadError", code: 0, userInfo: [NSLocalizedDescriptionKey: "업로드 실패"])))
                return
            }
            
            storageRef.downloadURL { url, error in
                guard let url = url else {
                    completion(.failure(error ?? NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "URL 가져오기 실패"])))
                    return
                }
                
                completion(.success(url.absoluteString))
            }
        }
    }
    
    func uploadImages(_ images: [UIImage], completion: @escaping (Result<[String], Error>) -> Void) {
        var uploadedURLs: [String] = []
        let group = DispatchGroup()
        
        for image in images {
            group.enter()
            
            uploadImage(image) { result in
                switch result {
                case .success(let url):
                    uploadedURLs.append(url)
                case .failure(_):
                    print("이미지 업로드 실패")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if !uploadedURLs.isEmpty {
                completion(.success(uploadedURLs))
            } else if !images.isEmpty {
                completion(.failure(NSError(domain: "UploadError", code: 0, userInfo: [NSLocalizedDescriptionKey: "이미지 업로드 실패"])))
            } else {
                completion(.success([]))
            }
        }
    }
    
    func updateNoteWithImagesAndDeletions(note: Note, newImages: [UIImage], imagesToDelete: [String]) {
        isLoading = true
        
        uploadImages(newImages) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let newImageURLs):
                    var updatedNote = note
                    updatedNote.imageURLs.append(contentsOf: newImageURLs)
                    
                    self.updateNote(note: updatedNote)
                    self.deleteImagesFromStorage(imageURLs: imagesToDelete)
                    
                    self.invalidateImageCache(for: note.imageURLs)
                    self.refreshNoteInUI(noteId: note.id)
                    
                    self.isLoading = false
                    let category = note.category == .일지 ? "일지" : "일정"
                    let particle = note.category == .일지 ? "가" : "이"
                    self.toastMessage = ToastMessage(
                        message: "\(category)\(particle) 수정되었습니다.",
                        type: .success
                    )
                    
                case .failure(let error):
                    self.isLoading = false
                    self.errorMessage = "이미지 업로드 실패: \(error.localizedDescription)"
                    
                    self.updateNote(note: note)
                    self.deleteImagesFromStorage(imageURLs: imagesToDelete)
                    
                    self.toastMessage = ToastMessage(
                        message: "이미지 업로드 실패, 내용은 수정되었습니다.",
                        type: .error
                    )
                }
            }
        }
    }
    
    private func refreshNoteInUI(noteId: UUID) {
        objectWillChange.send()
        
        NotificationCenter.default.post(
            name: Notification.Name("NoteImageUpdated"),
            object: noteId
        )
    }
    
    func updateNoteWithDeletions(note: Note, imagesToDelete: [String]) {
        isLoading = true
        
        updateNote(note: note)
        deleteImagesFromStorage(imageURLs: imagesToDelete)
        
        DispatchQueue.main.async {
            self.isLoading = false
            let category = note.category == .일지 ? "일지" : "일정"
            let particle = note.category == .일지 ? "가" : "이"
            self.toastMessage = ToastMessage(
                message: "\(category)\(particle) 수정되었습니다.",
                type: .success
            )
        }
    }
    
    private func deleteImagesFromStorage(imageURLs: [String]) {
        for imageURL in imageURLs {
            if let url = URL(string: imageURL),
               let path = url.path.components(separatedBy: "o/").last?.removingPercentEncoding?.components(separatedBy: "?").first {
                let storageRef = Storage.storage().reference().child(path)
                storageRef.delete { error in
                    if let error = error {
                        print("Firebase Storage에서 이미지 삭제 실패: \(error.localizedDescription)")
                    } else {
                        print("이미지 삭제 성공: \(imageURL)")
                    }
                }
            }
        }
    }
}

// MARK: - Notification Extension
extension NoteViewModel {
    func scheduleNotificationForNote(_ note: Note, minutesBefore: Int) -> Bool {
        guard note.category == .일정 else { return false }
        
        if NotificationService.shared.authorizationStatus == .authorized {
            let notificationResult = NotificationService.shared.scheduleNotification(
                for: note,
                minutesBefore: minutesBefore
            )
            
            if notificationResult.success == false {
                self.toastMessage = ToastMessage(
                    message: notificationResult.message ?? "알림 설정에 실패했습니다.",
                    type: .error
                )
                return false
            }
            return true
        } else {
            self.toastMessage = ToastMessage(
                message: "알림 권한이 필요합니다. 설정에서 권한을 허용해주세요.",
                type: .error
            )
            return false
        }
    }
    
    func cancelNotificationForNote(_ note: Note) {
        if note.category == .일정 {
            NotificationService.shared.cancelNotification(with: note.id.uuidString)
        }
    }
}
