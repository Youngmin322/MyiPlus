//
//  NoteEditorView.swift
//  MyiApp
//
//  Created by Saebyeok Jang on 5/13/25.
//

import SwiftUI
import PhotosUI
import Kingfisher

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: NoteViewModel
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var date: Date
    @State private var selectedCategory: NoteCategory = .일지
    @State private var selectedImages: [UIImage] = []
    @State private var showingPhotoPicker = false
    @State private var existingImageURLs: [String] = []
    @State private var isSaving = false
    
    @State private var imagesToDelete: Set<Int> = []
    
    @State private var isReminderEnabled: Bool = false
    @State private var reminderTime: Date
    @State private var reminderMinutesBefore: Int = 0
    @State private var showAlertMessage = false
    @State private var alertMessage = ""
    
    @FocusState private var isContentFieldFocused: Bool
    
    let isEditing: Bool
    let noteId: UUID?
    
    init(selectedDate: Date, note: Note? = nil) {
        let now = Date()
        if let note = note {
            _date = State(initialValue: note.date)
            _reminderTime = State(initialValue: note.date)
            _title = State(initialValue: note.title)
            _description = State(initialValue: note.description)
            _selectedCategory = State(initialValue: note.category)
            _existingImageURLs = State(initialValue: note.imageURLs)
            
            if let notificationEnabled = note.notificationEnabled, notificationEnabled {
                _isReminderEnabled = State(initialValue: true)
                if let notificationTime = note.notificationTime {
                    _reminderTime = State(initialValue: notificationTime)
                    let diffMinutes = Int(note.date.timeIntervalSince(notificationTime) / 60)
                    if diffMinutes > 0 {
                        _reminderMinutesBefore = State(initialValue: diffMinutes)
                    } else {
                        _reminderMinutesBefore = State(initialValue: 0)
                    }
                }
            } else {
                _isReminderEnabled = State(initialValue: false)
            }
            
            self.isEditing = true
            self.noteId = note.id
        } else {
            let calendar = Calendar.current
            let selectedDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            let currentTimeComponents = calendar.dateComponents([.hour, .minute], from: now)
            
            var combinedComponents = DateComponents()
            combinedComponents.year = selectedDateComponents.year
            combinedComponents.month = selectedDateComponents.month
            combinedComponents.day = selectedDateComponents.day
            combinedComponents.hour = currentTimeComponents.hour
            combinedComponents.minute = currentTimeComponents.minute
            
            let combinedDate = calendar.date(from: combinedComponents) ?? now
            _date = State(initialValue: combinedDate)
            _reminderTime = State(initialValue: combinedDate)
            _isReminderEnabled = State(initialValue: false)
            
            self.isEditing = false
            self.noteId = nil
        }
    }
    
    private var activeImages: [(Int, String)] {
        existingImageURLs.enumerated().compactMap { index, url in
            imagesToDelete.contains(index) ? nil : (index, url)
        }
    }
    
    private var deletedImages: [(Int, String)] {
        existingImageURLs.enumerated().compactMap { index, url in
            imagesToDelete.contains(index) ? (index, url) : nil
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("customBackgroundColor")
                    .ignoresSafeArea()
                
                Form {
                    categorySection
                    titleSection
                    dateSection
                    contentSection
                    
                    if selectedCategory == .일지 {
                        imageSection
                    }
                    
                    if selectedCategory == .일정 {
                        reminderSection
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .navigationTitle(isEditing ? "내용 수정" : "새 \(selectedCategory.rawValue) 작성")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") {
                            imagesToDelete.removeAll()
                            dismiss()
                        }
                        .disabled(isSaving)
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장") {
                            saveNote()
                        }
                        .disabled(title.isEmpty || isSaving)
                    }
                }
                .overlay(loadingOverlay)
                .alert("알림", isPresented: $showAlertMessage) {
                    Button("확인", role: .cancel) {}
                } message: {
                    Text(alertMessage)
                }
                .sheet(isPresented: $showingPhotoPicker) {
                    PhotoPicker(selectedImages: $selectedImages, selectionLimit: 10)
                }
            }
        }
    }
    
    private var categorySection: some View {
        Section(header: Text("카테고리")) {
            VStack(spacing: 8) {
                RadioButtonRow(
                    title: "일지",
                    icon: "note.text",
                    color: Color.button,
                    isSelected: selectedCategory == .일지
                ) {
                    selectedCategory = .일지
                    isReminderEnabled = false
                }
                
                RadioButtonRow(
                    title: "일정",
                    icon: "calendar",
                    color: Color.orange,
                    isSelected: selectedCategory == .일정
                ) {
                    selectedCategory = .일정
                    reminderTime = date
                    reminderMinutesBefore = 0
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var titleSection: some View {
        Section(header: Text("제목")) {
            TextField("제목을 입력하세요", text: $title)
        }
    }
    
    private var dateSection: some View {
        Section(header: Text("날짜 및 시간")) {
            DatePicker("날짜 및 시간", selection: $date)
                .datePickerStyle(.compact)
                .onChange(of: date) { _, newValue in
                    updateReminderTime(for: newValue)
                }
        }
    }
    
    private var contentSection: some View {
        Section(header: Text("내용")) {
            TextEditor(text: $description)
                .focused($isContentFieldFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button {
                            isContentFieldFocused.toggle()
                        } label: {
                            Text("완료")
                        }
                    }
                }
                .frame(minHeight: 150)
        }
    }
    
    private var imageSection: some View {
        Section(header: Text("이미지")) {
            VStack(alignment: .leading, spacing: 16) {
                if !activeImages.isEmpty {
                    activeImagesView
                }
                
                if !deletedImages.isEmpty {
                    deletedImagesView
                }
                
                if !selectedImages.isEmpty {
                    newImagesView
                }
                
                addImageButton
            }
        }
    }
    
    private var activeImagesView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("기존 이미지")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ActiveImagePreviewGrid(
                activeImages: activeImages,
                onDelete: { originalIndex in
                    _ = withAnimation(.easeInOut(duration: 0.3)) {
                        imagesToDelete.insert(originalIndex)
                    }
                }
            )
        }
    }
    
    private var deletedImagesView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("삭제 예정 이미지")
                .font(.subheadline)
                .foregroundColor(.red)
            
            DeletedImagePreviewGrid(
                deletedImages: deletedImages,
                onRestore: { originalIndex in
                    _ = withAnimation(.easeInOut(duration: 0.3)) {
                        imagesToDelete.remove(originalIndex)
                    }
                }
            )
        }
    }
    
    private var newImagesView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("추가할 이미지")
                .font(.subheadline)
                .foregroundColor(.green)
            
            ImagePreviewGrid(images: $selectedImages) { index in
                selectedImages.remove(at: index)
            }
        }
    }
    
    private var addImageButton: some View {
        Button(action: {
            showingPhotoPicker = true
        }) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                Text("이미지 추가")
            }
        }
    }
    
    private var reminderSection: some View {
        Section(header: Text("알림")) {
            NoteReminderView(
                isEnabled: $isReminderEnabled,
                reminderTime: $reminderTime,
                reminderMinutesBefore: $reminderMinutesBefore,
                eventDate: date
            )
        }
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        if isSaving {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .overlay(
                    CleanLoadingOverlay(
                        message: isEditing ? "수정 중..." : "저장 중...",
                        imageNames: ["sharkNewBorn", "sharkInfant", "sharkToddler"],
                        frameInterval: 0.5
                    )
                )
        }
    }
    
    private func updateReminderTime(for newValue: Date) {
        if isReminderEnabled {
            if reminderMinutesBefore == 0 {
                reminderTime = newValue
            } else {
                reminderTime = newValue.addingTimeInterval(TimeInterval(-reminderMinutesBefore * 60))
                
                if reminderTime < Date() {
                    let possibleTime = Date().addingTimeInterval(5 * 60)
                    if possibleTime < newValue {
                        reminderTime = possibleTime
                        let diffMinutes = Int(newValue.timeIntervalSince(possibleTime) / 60)
                        reminderMinutesBefore = diffMinutes
                    }
                }
            }
        }
    }
    
    private func saveNote() {
        if title.isEmpty { return }
        
        if selectedCategory == .일정 && isReminderEnabled {
            if reminderTime < Date() {
                alertMessage = "알림 시간은 현재 시간보다 이후여야 합니다."
                showAlertMessage = true
                return
            }
            
            if reminderTime >= date {
                alertMessage = "알림 시간은 일정 시작 시간보다 이전이어야 합니다."
                showAlertMessage = true
                return
            }
        }
        
        let noteId = self.noteId ?? UUID()
        
        var notificationEnabled: Bool? = nil
        var notificationTime: Date? = nil
        
        if selectedCategory == .일정 {
            if isReminderEnabled {
                let result = handleNotificationForEvent(noteId: noteId)
                
                if result.success, let time = result.time {
                    notificationEnabled = true
                    notificationTime = time
                } else {
                    notificationEnabled = false
                    
                    if !result.success {
                        alertMessage = result.message ?? "알림 설정에 실패했습니다."
                        showAlertMessage = true
                        return
                    }
                }
            } else {
                notificationEnabled = false
                if isEditing {
                    NotificationService.shared.cancelNotification(with: noteId.uuidString)
                }
            }
        }
        
        let finalImageURLs = existingImageURLs.enumerated().compactMap { index, url in
            imagesToDelete.contains(index) ? nil : url
        }
        
        let note = Note(
            id: noteId,
            title: title,
            description: description,
            date: date,
            category: selectedCategory,
            imageURLs: finalImageURLs,
            notificationEnabled: notificationEnabled,
            notificationTime: notificationTime
        )
        
        if !isEditing {
            viewModel.addNoteLocallyWithImages(note, localImages: selectedImages)
        }
        
        setSuccessToastMessage(withNotification: note.notificationEnabled == true)
        
        dismiss()
        
        Task {
            do {
                let imagesToDeleteURLs = Array(imagesToDelete).map { existingImageURLs[$0] }
                
                try await viewModel.saveNoteOptimistically(
                    note,
                    images: selectedImages,
                    isEditing: isEditing,
                    imagesToDelete: imagesToDeleteURLs
                )
                
            } catch {
                await MainActor.run {
                    if !isEditing {
                        viewModel.removeNoteLocally(noteId)
                    }
                    
                    viewModel.toastMessage = ToastMessage(
                        message: "저장에 실패했습니다: \(error.localizedDescription)",
                        type: .error
                    )
                }
            }
        }
    }
    
    private func handleNotificationForEvent(noteId: UUID) -> (success: Bool, time: Date?, message: String?) {
        if reminderTime < Date() {
            return (false, nil, "알림 시간은 현재 시간 이후여야 합니다.")
        }
        
        if reminderTime >= date {
            return (false, nil, "알림 시간은 일정 시작 시간보다 이전이어야 합니다.")
        }
        
        let timeDiff = reminderMinutesBefore == 0 ? 0 : max(1, Int(date.timeIntervalSince(reminderTime) / 60))
        
        let note = Note(
            id: noteId,
            title: title,
            description: description,
            date: date,
            category: .일정
        )
        
        let result = NotificationService.shared.scheduleNotification(
            for: note,
            minutesBefore: timeDiff
        )
        
        return result
    }
    
    private func setSuccessToastMessage(withNotification: Bool) {
        let messagePrefix = isEditing ? "" : "새 "
        let category = selectedCategory == .일지 ? "일지" : "일정"
        let action = isEditing ? "수정" : "저장"
        let particle = selectedCategory == .일지 ? "가" : "이"
        
        let notificationText = selectedCategory == .일정 && withNotification
        ? " 알림이 설정되었습니다."
        : ""
        
        viewModel.toastMessage = ToastMessage(
            message: "\(messagePrefix)\(category)\(particle) \(action)되었습니다.\(notificationText)",
            type: .success
        )
    }
}

struct RadioButtonRow: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                ZStack {
                    Circle()
                        .stroke(color, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(color)
                            .frame(width: 14, height: 14)
                    }
                }
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActiveImagePreviewGrid: View {
    let activeImages: [(Int, String)]
    let onDelete: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(activeImages, id: \.0) { originalIndex, url in
                    ZStack(alignment: .topTrailing) {
                        KFImage(URL(string: url))
                            .placeholder {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.1))
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                }
                            }
                            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 200)))
                            .scaleFactor(UIScreen.main.scale)
                            .fade(duration: 0.25)
                            .cacheMemoryOnly()
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Button(action: {
                            onDelete(originalIndex)
                        }) {
                            Circle()
                                .fill(Color.red.opacity(0.9))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                        .padding(5)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 120)
    }
}

struct DeletedImagePreviewGrid: View {
    let deletedImages: [(Int, String)]
    let onRestore: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(deletedImages, id: \.0) { originalIndex, url in
                    ZStack {
                        KFImage(URL(string: url))
                            .placeholder {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.1))
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                }
                            }
                            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 200)))
                            .scaleFactor(UIScreen.main.scale)
                            .fade(duration: 0.25)
                            .cacheMemoryOnly()
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .opacity(0.3)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.4))
                            .frame(width: 100, height: 100)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "trash.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                                    
                                    Text("삭제됨")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.red.opacity(0.8), lineWidth: 2)
                            )
                        
                        VStack {
                            Spacer()
                            
                            Button(action: {
                                onRestore(originalIndex)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 10, weight: .semibold))
                                    Text("복원")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.blue)
                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                )
                            }
                            .padding(.bottom, 8)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 120)
    }
}
