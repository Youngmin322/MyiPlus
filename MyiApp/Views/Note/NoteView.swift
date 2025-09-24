//
//  NoteView.swift
//  MyiApp
//
//  Created by Saebyeok Jang on 5/13/25.
//

import SwiftUI

struct NoteView: View {
    @StateObject private var viewModel = NoteViewModel()
    @State private var showingNoteEditor = false
    @State private var selectedFilterCategory: NoteCategory? = nil
    @State private var selectedEvent: Note? = nil
    @State private var selectedDate: Date? = nil
    @State private var isFirstAppear = true
    
    var body: some View {
        ZStack {
            Color("customBackgroundColor")
                .ignoresSafeArea()
            VStack(spacing: 0) {
                SafeAreaPaddingView()
                    .frame(height: getTopSafeAreaHeight())
                ScrollView {
                    
                    VStack(spacing: 15) {
                        HStack {
                            Text("육아 수첩")
                                .font(.title)
                                .bold()
                            Spacer()
                        }
                        
                        VStack(spacing: 15) {
                            VStack(spacing: 0) {
                                // 캘린더 헤더
                                calendarHeaderSection
                                
                                // 캘린더 그리드
                                calendarGridSection
                                    .padding(.bottom, 8)
                            }
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(12)
                            
                            // MARK: - 선택된 날짜 이벤트 섹션
                            VStack(spacing: 0) {
                                if let selectedDay = viewModel.selectedDay, let date = selectedDay.date {
                                    VStack(spacing: 12) {
                                        HStack {
                                            Text("\(date.formattedFullKoreanDateString())")
                                                .font(.headline)
                                            
                                            if let anniversary = viewModel.getAnniversaryType(date) {
                                                Text("\(anniversary.emoji) \(anniversary.text)")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(anniversary.color)
                                                    .padding(.horizontal, 8)
                                                    .background(
                                                        Capsule()
                                                            .fill(anniversary.color.opacity(0.1))
                                                    )
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                showingNoteEditor = true
                                            }) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "plus.circle.fill")
                                                        .font(.system(size: 20))
                                                    Text("추가")
                                                        .font(.system(size: 16, weight: .medium))
                                                }
                                                .foregroundColor(Color.button)
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.top, 16)
                                        
                                        // MARK: - 카테고리 필터
                                        categoryFilterSection
                                            .padding(.top, 4)
                                            .padding(.horizontal)
                                        
                                        // MARK: - 이벤트 목록
                                        eventsListView(for: date)
                                            .padding(.top, 8)
                                            .padding(.bottom, 16)
                                    }
                                } else {
                                    emptyEventsView
                                        .padding(.top, 16)
                                }
                            }
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingNoteEditor, onDismiss: {
            viewModel.objectWillChange.send()
        }) {
            NoteEditorView(selectedDate: viewModel.selectedDay?.date ?? Date())
                .environmentObject(viewModel)
        }
        .navigationDestination(item: $selectedEvent) { event in
            NoteDetailView(event: event)
                .environmentObject(viewModel)
        }
        .onAppear {
            if isFirstAppear {
                selectToday()
                isFirstAppear = false
            }
        }
        .toast(message: $viewModel.toastMessage)
    }
    
    // MARK: - 오늘 날짜 선택
    private func selectToday() {
        let today = Date()
        selectedDate = today
        
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: viewModel.selectedMonth)
        let todayMonth = calendar.component(.month, from: today)
        let currentYear = calendar.component(.year, from: viewModel.selectedMonth)
        let todayYear = calendar.component(.year, from: today)
        
        if currentMonth != todayMonth || currentYear != todayYear {
            viewModel.selectedMonth = today
            viewModel.fetchCalendarDays()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            if let todayDay = viewModel.days.first(where: { $0.isToday }) {
                viewModel.selectedDay = todayDay
            }
        }
    }
    
    // MARK: - 캘린더 헤더 섹션
    private var calendarHeaderSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button(action: {
                    viewModel.changeMonth(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                
                Spacer()
                
                DatePicker(
                    "",
                    selection: $viewModel.selectedMonth,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(width: 140, height: 44)
                .accentColor(.clear)
                .colorMultiply(.clear)
                .overlay(
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .foregroundColor(.primary)
                        
                        Text(viewModel.currentMonth)
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    .allowsHitTesting(false)
                    .background(Color(UIColor.tertiarySystemBackground))
                )
                .onChange(of: viewModel.selectedMonth) {
                    viewModel.fetchCalendarDays()
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.changeMonth(by: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                
                Spacer()
                Spacer()
                
                Group {
                    if viewModel.selectedDay?.date != nil &&
                        !Calendar.current.isDateInToday(viewModel.selectedDay?.date ?? Date()) {
                        Button(action: {
                            selectToday()
                        }) {
                            Text("오늘")
                                .font(.subheadline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .foregroundColor(.primary)
                                .background(
                                    Capsule().stroke(Color.primary, lineWidth: 1)
                                )
                        }
                        .frame(width: 60)
                    } else {
                        Color.clear
                            .frame(width: 60, height: 44)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            HStack(spacing: 0) {
                ForEach(viewModel.weekdays, id: \.self) { day in
                    Text(day)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(day == "일" ? .red : day == "토" ? .blue : .primary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 캘린더 그리드
    private var calendarGridSection: some View {
        let days = viewModel.days
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days) { day in
                CalendarDayView(
                    day: day,
                    selectedDate: $selectedDate,
                    events: viewModel.getEventsForDay(day),
                    anniversaryType: viewModel.getAnniversaryType(day.date)
                )
                .onTapGesture {
                    if day.date != nil {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = day.date
                            viewModel.selectedDay = day
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - 카테고리 필터
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: {
                    selectedFilterCategory = nil
                }) {
                    Text("전체")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(selectedFilterCategory == nil ? Color.button : Color.gray.opacity(0.1))
                        )
                        .foregroundColor(selectedFilterCategory == nil ? .white : .primary)
                }
                
                ForEach(NoteCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedFilterCategory = category
                    }) {
                        Text(category.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedFilterCategory == category ? Color.button : Color.gray.opacity(0.1))
                            )
                            .foregroundColor(selectedFilterCategory == category ? .white : .primary)
                    }
                }
            }
        }
    }
    
    // MARK: - 날짜별 이벤트 목록 뷰
    private func eventsListView(for date: Date) -> some View {
        let dayEvents = viewModel.events[Calendar.current.startOfDay(for: date)] ?? []
        
        if dayEvents.isEmpty {
            return AnyView(emptyEventsView)
        } else {
            let filteredEvents = selectedFilterCategory == nil ?
            dayEvents :
            dayEvents.filter { $0.category == selectedFilterCategory }
            
            if filteredEvents.isEmpty {
                return AnyView(
                    VStack(spacing: 10) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        
                        Text("해당 카테고리의 기록이 없습니다.")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                        .frame(maxWidth: .infinity)
                        .frame(height: 97)
                        .padding(.vertical, 8)
                )
            } else {
                return AnyView(
                    List {
                        ForEach(filteredEvents) { event in
                            NoteEventListRow(event: event)
                                .environmentObject(viewModel)
                                .id(event.id)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .onTapGesture {
                                    selectedEvent = event
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteNote(event)
                                    } label: {
                                        Label("삭제", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: CGFloat(filteredEvents.count) * 85)
                        .fixedSize(horizontal: false, vertical: true)
                        .scrollDisabled(true)
                )
            }
        }
    }
    
    private var emptyEventsView: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("기록된 일지가 없습니다")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 97)
        .padding(.vertical, 8)
    }
    
    private func deleteNote(_ note: Note) {
        // MARK: - 삭제 처리
        if note.category == .일정 {
            NotificationService.shared.cancelNotification(with: note.id.uuidString)
        }
        
        let category = note.category == .일지 ? "일지" : "일정"
        let particle = note.category == .일지 ? "가" : "이"
        viewModel.toastMessage = ToastMessage(
            message: "\(category)\(particle) 삭제되었습니다.",
            type: .info
        )
        
        viewModel.deleteNote(note: note)
    }
    
    private func getTopSafeAreaHeight() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 0
        }
        
        let height = window.safeAreaInsets.top
        return height * 0.1
    }
}
