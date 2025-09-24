//
//  NoteReminderView.swift
//  MyiApp
//
//  Created by Saebyeok Jang on 5/15/25.
//

import SwiftUI

struct NoteReminderView: View {
    @Binding var isEnabled: Bool
    @Binding var reminderTime: Date
    @Binding var reminderMinutesBefore: Int
    @State private var showTimePicker = false
    @State private var tempReminderTime: Date = Date()
    @State private var showInvalidTimeAlert = false
    @State private var alertMessage = ""
    @ObservedObject var notificationService = NotificationService.shared
    
    var eventDate: Date
    
    private let reminderOptions = [0, 10, 15, 30, 60, 120, 1440]
    
    var body: some View {
        VStack(spacing: 16) {
            if notificationService.authorizationStatus == .authorized {
                authorizedView
            } else {
                NotificationPermissionView {
                    notificationService.requestAuthorization { granted in
                        if granted {
                            isEnabled = true
                            reminderMinutesBefore = 0
                            reminderTime = eventDate
                        } else {
                            print("알림 권한 획득 실패!")
                        }
                    }
                }
            }
        }
        .animation(.easeInOut, value: notificationService.authorizationStatus)
        .onAppear {
            notificationService.checkAuthorizationStatus()
            
            if eventDate <= Date() {
                isEnabled = false
            }
        }
        .alert(alertMessage, isPresented: $showInvalidTimeAlert) {
            Button("확인", role: .cancel) { }
        }
    }
    
    private var authorizedView: some View {
        VStack(spacing: 16) {
            Toggle("일정 알림", isOn: $isEnabled)
                .tint(Color.button)
                .onChange(of: isEnabled) { _, enabled in
                    if enabled {
                        // 알림 활성화 시 기본값 설정
                        if eventDate > Date() {
                            reminderMinutesBefore = 0
                            reminderTime = eventDate
                        } else {
                            // 과거 일정인 경우
                            isEnabled = false
                            showInvalidTimeAlert = true
                            alertMessage = "과거 일정에는 알림을 설정할 수 없습니다."
                        }
                    }
                }
            
            if isEnabled {
                VStack(spacing: 16) {
                    HStack {
                        Text("알림 시간")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Menu {
                            ForEach(reminderOptions, id: \.self) { minutes in
                                Button(action: {
                                    selectReminderOption(minutes: minutes)
                                }) {
                                    HStack {
                                        Text(minutesToString(minutes))
                                        if reminderMinutesBefore == minutes {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                            
                            Button(action: {
                                tempReminderTime = reminderTime
                                showTimePicker = true
                            }) {
                                HStack {
                                    Text("직접 설정")
                                    if reminderMinutesBefore == -1 {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(reminderMinutesBefore == -1 ? "직접 설정" : minutesToString(reminderMinutesBefore))
                                    .foregroundColor(.blue)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // 알림 시간 표시
                    Button(action: {
                        tempReminderTime = reminderTime
                        showTimePicker = true
                    }) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.button)
                            
                            Text(formattedReminderTime)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color("sharkCardBackground"))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $showTimePicker) {
                        timePickerSheet
                    }
                    
                    // 알림 설명
                    if reminderMinutesBefore == 0 {
                        Text("일정 시작 시간에 알림을 받습니다")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else if reminderMinutesBefore > 0 {
                        Text("일정이 시작되기 \(minutesToString(reminderMinutesBefore)) 알림을 받습니다")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("설정한 시간에 알림을 받습니다")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private var timePickerSheet: some View {
        VStack(spacing: 20) {
            Text("알림 시간 설정")
                .font(.headline)
                .padding(.top)
            
            DatePicker("알림 시간", selection: $tempReminderTime, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.wheel)
                .labelsHidden()
            
            HStack {
                Button(action: {
                    showTimePicker = false
                }) {
                    Text("취소")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    validateAndSetCustomTime()
                }) {
                    Text("확인")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.button)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
        }
        .presentationDetents([.height(350)])
    }
    
    // MARK: - Helper Methods
    
    private func selectReminderOption(minutes: Int) {
        if minutes == 0 {
            reminderMinutesBefore = 0
            reminderTime = eventDate
        } else {
            let newReminderTime = eventDate.addingTimeInterval(TimeInterval(-minutes * 60))
            
            // 현재 시간보다 5초 이상 미래인지 확인
            if newReminderTime > Date().addingTimeInterval(5) {
                reminderMinutesBefore = minutes
                reminderTime = newReminderTime
            } else {
                showInvalidTimeAlert = true
                alertMessage = "선택한 시간이 현재보다 이전입니다. 다른 옵션을 선택해주세요."
            }
        }
    }
    
    private func validateAndSetCustomTime() {
        // 일정 시간 이후인지 확인
        if tempReminderTime > eventDate {
            showInvalidTimeAlert = true
            alertMessage = "알림 시간은 일정 시작 시간 이후일 수 없습니다."
            return
        }
        
        // 현재 시간보다 5초 이상 미래인지 확인
        if tempReminderTime <= Date().addingTimeInterval(5) {
            showInvalidTimeAlert = true
            alertMessage = "알림 시간은 현재 시간보다 이후여야 합니다."
            return
        }
        
        // 시간 설정
        reminderTime = tempReminderTime
        
        // 분 단위 차이 계산
        let diffSeconds = eventDate.timeIntervalSince(tempReminderTime)
        let diffMinutes = Int(diffSeconds / 60)
        
        // 기존 옵션과 일치하는지 확인
        if reminderOptions.contains(diffMinutes) {
            reminderMinutesBefore = diffMinutes
        } else {
            reminderMinutesBefore = -1
        }
        
        showTimePicker = false
    }
    
    private var formattedReminderTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM월 dd일 a h:mm"
        formatter.amSymbol = "오전"
        formatter.pmSymbol = "오후"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: reminderTime)
    }
    
    private func minutesToString(_ minutes: Int) -> String {
        switch minutes {
        case 0:
            return "일정 시간"
        case -1:
            return "사용자 지정"
        case 1440:
            return "1일 전"
        case let m where m >= 60:
            return "\(m / 60)시간 전"
        default:
            return "\(minutes)분 전"
        }
    }
}
