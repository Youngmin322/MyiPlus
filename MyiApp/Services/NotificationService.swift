//
//  NotificationService.swift
//  MyiApp
//
//  Created by Saebyeok Jang on 5/15/25.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private var notificationCache: [String: (date: Date, title: String)] = [:]
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.authorizationStatus = granted ? .authorized : .denied
                if let error = error {
                    print("알림 권한 요청 에러: \(error.localizedDescription)")
                }
                completion(granted)
            }
        }
    }
    
    @discardableResult
    func scheduleNotification(for note: Note, minutesBefore: Int = 0) -> (success: Bool, time: Date?, message: String?) {
        
        if authorizationStatus != .authorized {
            return (false, nil, "알림 권한이 필요합니다")
        }
        
        cancelNotification(with: note.id.uuidString)
        
        let triggerDate: Date
        if minutesBefore == 0 {
            triggerDate = note.date
        } else {
            triggerDate = note.date.addingTimeInterval(TimeInterval(-minutesBefore * 60))
        }
        
        let minimumFutureTime = Date().addingTimeInterval(5)
        if triggerDate < minimumFutureTime {
            return (false, nil, "알림 시간은 현재 시간보다 최소 5초 이후여야 합니다.")
        }
        
        let content = UNMutableNotificationContent()
        content.title = "일정 알림"
        content.body = note.title
        content.sound = .default
        content.badge = 1
        
        content.categoryIdentifier = "SCHEDULE_NOTIFICATION"
        
        content.userInfo = [
            "noteId": note.id.uuidString,
            "title": note.title,
            "date": note.date.timeIntervalSince1970,
            "category": note.category.rawValue
        ]
        
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: note.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        var isSuccessful = true
        var errorMessage: String?
        let semaphore = DispatchSemaphore(value: 0)
        
        UNUserNotificationCenter.current().add(request) { error in
            defer { semaphore.signal() }
            
            if let error = error {
                isSuccessful = false
                errorMessage = error.localizedDescription
                print("알림 예약 실패: \(error.localizedDescription)")
            } else {
                print("알림 예약 성공: \(note.title) at \(triggerDate)")
            }
        }
        
        _ = semaphore.wait(timeout: .now() + 1.0)
        
        if isSuccessful {
            notificationCache[note.id.uuidString] = (triggerDate, note.title)
            return (true, triggerDate, nil)
        } else {
            return (false, nil, errorMessage ?? "알림 설정에 실패했습니다")
        }
    }
    
    func cancelNotification(with identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCache.removeValue(forKey: identifier)
        print("알림 취소됨: \(identifier)")
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        notificationCache.removeAll()
        print("모든 알림이 취소되었습니다")
    }
    
    func getNotificationTimeText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM월 dd일 a h:mm"
        formatter.amSymbol = "오전"
        formatter.pmSymbol = "오후"
        formatter.locale = Locale(identifier: "ko_KR")
        
        return formatter.string(from: date)
    }
    
    func findNotificationForNote(noteId: String, completion: @escaping (Bool, Date?, String?) -> Void) {
        
        if let cached = notificationCache[noteId] {
            DispatchQueue.main.async {
                completion(true, cached.date, cached.title)
            }
            return
        }
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            if let matchingRequest = requests.first(where: { $0.identifier == noteId }),
               let trigger = matchingRequest.trigger as? UNCalendarNotificationTrigger,
               let triggerDate = trigger.nextTriggerDate() {
                
                self.notificationCache[noteId] = (triggerDate, matchingRequest.content.title)
                
                DispatchQueue.main.async {
                    completion(true, triggerDate, matchingRequest.content.title)
                }
                return
            }
            
            for request in requests {
                if let storedNoteId = request.content.userInfo["noteId"] as? String,
                   storedNoteId == noteId,
                   let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let triggerDate = trigger.nextTriggerDate() {
                    
                    self.notificationCache[noteId] = (triggerDate, request.content.title)
                    
                    DispatchQueue.main.async {
                        completion(true, triggerDate, request.content.title)
                    }
                    return
                }
            }
            
            DispatchQueue.main.async {
                completion(false, nil, nil)
            }
        }
    }
    
    func getAllPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
    
    func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    func printAllPendingNotifications() {
        getAllPendingNotifications { requests in
            print("===== 예약된 알림 목록 =====")
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let nextDate = trigger.nextTriggerDate() {
                    print("ID: \(request.identifier)")
                    print("제목: \(request.content.title)")
                    print("시간: \(self.getNotificationTimeText(for: nextDate))")
                    print("------------------------")
                }
            }
            print("총 \(requests.count)개의 알림이 예약되어 있습니다.")
        }
    }
}
