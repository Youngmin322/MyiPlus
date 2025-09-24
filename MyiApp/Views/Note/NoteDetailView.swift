//
//  NoteDetailView.swift
//  MyiApp
//
//  Created by Saebyeok Jang on 5/13/25.
//

import SwiftUI

struct NoteDetailView: View {
    let event: Note
    @EnvironmentObject private var viewModel: NoteViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var hasNotification = false
    @State private var notificationTime: String?
    @State private var refreshTrigger = false
    @State private var currentImageIndex = 0
    
    // MARK: - 바디
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                
                headerSection
                
                if event.category == .일지 && !event.imageURLs.isEmpty {
                    imageGallery
                }
                
                contentSection
                
                if event.category == .일정 {
                    reminderSection
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color("customBackgroundColor"))
        .navigationTitle(event.category == .일지 ? "일지 상세" : "일정 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(Color.button)
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet, onDismiss: {
            if event.category == .일정 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    refreshTrigger.toggle()
                    checkNotificationStatus()
                }
            }
            
            if viewModel.toastMessage != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }) {
            NoteEditorView(selectedDate: event.date, note: event)
                .environmentObject(viewModel)
        }
        .alert(Text(event.category == .일지 ?
                    "일지를 삭제합니다" :
                        "일정을 삭제합니다"), isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                deleteNote()
            }
        } message: {
            Text(event.category == .일지 ?
                 "이 일지는 영구적으로 삭제되며,\n복구할 수 없습니다." :
                    "이 일정은 영구적으로 삭제되며,\n복구할 수 없습니다.")
        }
        .onAppear {
            if event.category == .일정 {
                checkNotificationStatus()
            }
        }
        .onChange(of: refreshTrigger) { _, _ in
            if event.category == .일정 {
                checkNotificationStatus()
            }
        }
    }
    
    // MARK: - 헤더 섹션
    private var headerSection: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: categoryIcon(for: event.category))
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text(event.category.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(categoryColor(for: event.category).opacity(0.15))
                )
                .foregroundColor(categoryColor(for: event.category))
                
                Spacer()
                
                Text(event.date.formattedFullKoreanDateString())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 16)
            
            Text(event.title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.vertical, 8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
        .padding(.horizontal)
    }
    
    // MARK: - 이미지 갤러리
    private var imageGallery: some View {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    TabView(selection: $currentImageIndex) {
                        ForEach(0..<event.imageURLs.count, id: \.self) { index in
                            CustomAsyncImageView(imageUrlString: event.imageURLs[index])
                                .scaledToFill()
                                .tag(index)
                        }
                    }
                    .frame(height: UIScreen.main.bounds.width * 0.8)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    if event.imageURLs.count > 1 {
                        Text("\(currentImageIndex + 1)/\(event.imageURLs.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.black.opacity(0.6)))
                            .padding(.trailing, 12)
                            .padding(.top, 8)
                    }
                }
                .cornerRadius(10)
                
                if event.imageURLs.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<event.imageURLs.count, id: \.self) { index in
                            Circle()
                                .fill(currentImageIndex == index ?
                                      Color(.button) : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut(duration: 0.2), value: currentImageIndex)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
            }
            .padding(.horizontal)
        }
    
    // MARK: - 내용 섹션
    private var contentSection: some View {
        VStack(alignment: .leading) {
            if event.description.isEmpty {
                Text("내용이 없습니다.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Text(event.description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
            }
        }
        .frame(minHeight: 120, alignment: .top)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
        .padding(.horizontal)
    }
    
    // MARK: - 알림 섹션
    private var reminderSection: some View {
        VStack(alignment: .leading) {
            // 알림 섹션 제목
            Text("알림 정보")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary.opacity(0.8))
                .padding(.top, 16)
            
            Divider()
                .padding(.vertical, 8)
            
            if hasNotification, let notificationTime = notificationTime {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("알림 예정")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(notificationTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Text("변경")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.orange)
                            )
                    }
                }
                .padding(.bottom, 16)
            } else {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "bell.slash")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("알림 없음")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("이 일정에는 알림이 설정되어 있지 않습니다.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Text("설정")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.button)
                            )
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
        .padding(.horizontal)
        .id("\(hasNotification)-\(notificationTime ?? "none")-\(refreshTrigger)")
    }
    
    // MARK: - 함수
    private func checkNotificationStatus() {
        if let enabled = event.notificationEnabled,
           enabled,
           let time = event.notificationTime {
            
            hasNotification = true
            setNotificationTimeText(triggerDate: time)
            return
        }
        
        NotificationService.shared.findNotificationForNote(noteId: event.id.uuidString) { exists, triggerDate, title in
            DispatchQueue.main.async {
                self.hasNotification = exists
                
                if exists, let triggerDate = triggerDate {
                    self.setNotificationTimeText(triggerDate: triggerDate)
                    
                    self.viewModel.updateNoteNotification(
                        noteId: self.event.id,
                        enabled: true,
                        time: triggerDate
                    )
                } else {
                    self.notificationTime = nil
                    
                    self.viewModel.updateNoteNotification(
                        noteId: self.event.id,
                        enabled: false,
                        time: nil
                    )
                }
            }
        }
    }
    
    private func setNotificationTimeText(triggerDate: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM월 dd일 a h:mm"
        formatter.amSymbol = "오전"
        formatter.pmSymbol = "오후"
        formatter.locale = Locale(identifier: "ko_KR")
        
        self.notificationTime = formatter.string(from: triggerDate)
        
        if Calendar.current.isDate(triggerDate, equalTo: event.date, toGranularity: .minute) {
            self.notificationTime! += " (일정 시간)"
            return
        }
        
        let diffSeconds = event.date.timeIntervalSince(triggerDate)
        let diffMinutes = Int(diffSeconds / 60)
        
        if diffMinutes >= 60 {
            if diffMinutes % 60 == 0 {
                let hours = diffMinutes / 60
                self.notificationTime! += " (\(hours)시간 전)"
            } else {
                let hours = diffMinutes / 60
                let mins = diffMinutes % 60
                self.notificationTime! += " (\(hours)시간 \(mins)분 전)"
            }
        } else {
            self.notificationTime! += " (\(diffMinutes)분 전)"
        }
    }
    
    private func deleteNote() {
        if event.category == .일정 {
            NotificationService.shared.cancelNotification(with: event.id.uuidString)
        }
        
        let category = event.category == .일지 ? "일지" : "일정"
        let particle = event.category == .일지 ? "가" : "이"
        viewModel.toastMessage = ToastMessage(
            message: "\(category)\(particle) 삭제되었습니다.",
            type: .info
        )
        
        viewModel.deleteNote(note: event)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func categoryColor(for category: NoteCategory) -> Color {
        switch category {
        case .일지:
            return Color.blue
        case .일정:
            return Color.orange
        }
    }
    
    private func categoryIcon(for category: NoteCategory) -> String {
        switch category {
        case .일지:
            return "note.text"
        case .일정:
            return "calendar"
        }
    }
}
