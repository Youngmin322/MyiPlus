//
//  NotificationPermissionView.swift
//  MyiApp
//
//  Created by Saebyeok Jang on 5/15/25.
//

import SwiftUI

struct NotificationPermissionView: View {
    @ObservedObject var notificationService = NotificationService.shared
    var onRequestPermission: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray)
                .padding(.bottom, 8)
            
            Text("알림 권한이 필요합니다")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("일정 알림을 받기 위해서는 알림 권한이 필요합니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if notificationService.authorizationStatus == .denied {
                Button(action: {
                    notificationService.openNotificationSettings()
                }) {
                    Text("설정 앱에서 권한 설정하기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("sharkPrimaryColor"))
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            } else {
                Button(action: {
                    notificationService.requestAuthorization { granted in
                        if granted {
                            onRequestPermission?()
                        }
                    }
                }) {
                    Text("알림 권한 요청")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("sharkPrimaryColor"))
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }
            
            if notificationService.authorizationStatus == .denied {
                Text("또는 나중에 '설정 > 알림'에서 변경할 수 있습니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.tertiarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding()
    }
}
