//
//  NoteEvent.swift
//  MyiApp
//
//  Created by Saebyeok Jang on 5/12/25.
//

import SwiftUI
import Kingfisher

struct NoteEventList: View {
    @EnvironmentObject private var viewModel: NoteViewModel
    var events: [Note]
    var filteredCategory: NoteCategory?
    var onSelectEvent: ((Note) -> Void)
    @State private var showingDeleteAlert = false
    @State private var noteToDelete: Note?
    
    var body: some View {
        let filteredEvents = filteredCategory == nil ? events : events.filter { $0.category == filteredCategory }
        
        if filteredEvents.isEmpty {
            emptyStateView
        } else {
            List {
                ForEach(filteredEvents) { event in
                    NoteEventListRow(event: event)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .onTapGesture {
                            onSelectEvent(event)
                        }
                }
                .onDelete { indexSet in
                    if let index = indexSet.first {
                        noteToDelete = filteredEvents[index]
                        showingDeleteAlert = true
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .alert("삭제 확인", isPresented: $showingDeleteAlert) {
                Button("취소", role: .cancel) {
                    noteToDelete = nil
                }
                Button("삭제", role: .destructive) {
                    if let note = noteToDelete {
                        deleteNote(note)
                    }
                    noteToDelete = nil
                }
            } message: {
                if let note = noteToDelete {
                    Text("\(note.title)을(를) 삭제하시겠습니까?")
                } else {
                    Text("이 항목을 삭제하시겠습니까?")
                }
            }
        }
    }
    
    private func deleteNote(_ note: Note) {
        // MARK: - 일정인 경우 알림 취소
        if note.category == .일정 {
            NotificationService.shared.cancelNotification(with: note.id.uuidString)
        }
        
        // MARK: - 삭제 토스트 메시지 설정
        let category = note.category == .일지 ? "일지" : "일정"
        let particle = note.category == .일지 ? "가" : "이"
        viewModel.toastMessage = ToastMessage(
            message: "\(category)\(particle) 삭제되었습니다.",
            type: .info
        )
        
        // MARK: - 노트 삭제
        viewModel.deleteNote(note: note)
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "doc.text.magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color.gray)
                
                Text(filteredCategory == nil ?
                     "이 날의 기록이 없습니다." :
                        "해당 카테고리의 기록이 없습니다.")
                .font(.headline)
                .foregroundColor(.gray)
                
                Text("새로운 일지를 작성해보세요.")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            Spacer()
        }
        .frame(height: 250)
    }
}

// MARK: - List Row View
struct NoteEventListRow: View {
    var event: Note
    @EnvironmentObject private var viewModel: NoteViewModel
    @State private var imageRefreshId = UUID()
    
    var body: some View {
        HStack(spacing: 12) {
            // MARK: - 이미지 또는 아이콘
            if event.category == .일지 && (!event.imageURLs.isEmpty || event.localImages?.isEmpty == false) {
                if let localImages = event.localImages, !localImages.isEmpty {
                    Image(uiImage: localImages[0])
                        .resizable()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    KFImage.url(URL(string: event.imageURLs[0]))
                        .placeholder {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color("sharkPrimaryColor")))
                                .frame(width: 40, height: 40)
                        }
                        .onFailure { error in
                            print("리스트 이미지 로드 실패: \(error)")
                        }
                        .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 80, height: 80)))
                        .scaleFactor(UIScreen.main.scale)
                        .fade(duration: 0.25)
                        .cacheOriginalImage()
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .id(imageRefreshId)
                }
            } else {
                Image(systemName: categoryIcon(for: event.category))
                    .foregroundColor(categoryColor(for: event.category))
                    .font(.system(size: 24))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(categoryColor(for: event.category).opacity(0.2))
                    )
            }
            
            // MARK: - 콘텐츠
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // MARK: - 시간 및 사진 개수
            VStack(alignment: .trailing, spacing: 4) {
                Text(event.timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if event.category == .일지 && event.imageURLs.count > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.system(size: 10))
                        Text("\(event.imageURLs.count)")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(UIColor.systemGray6))
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(10)
        .contentShape(Rectangle())
        .padding(.horizontal)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NoteImageUpdated"))) { notification in
            if let noteId = notification.object as? UUID, noteId == event.id {
                imageRefreshId = UUID()
            }
        }
    }
    
    private func categoryColor(for category: NoteCategory) -> Color {
        switch category {
        case .일지:
            return Color.button
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
