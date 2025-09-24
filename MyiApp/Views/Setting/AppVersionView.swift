//
//  AppVersionView.swift
//  MyiApp
//
//  Created by Yung Hak Lee on 5/13/25.
//

import SwiftUI

struct AppVersionView: View {
    var body: some View {
            List {
                Section(header: Text("앱 정보")) {
                    InfoRow(label: "앱 버전", value: appVersion)
                    InfoRow(label: "기기", value: deviceModel)
                    InfoRow(label: "운영체제", value: systemVersion)
                }
            }
            .navigationTitle("앱 정보")
        }
        
        // 앱 버전 가져오기
        private var appVersion: String {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
            return "\(version).\(build)"
        }
        
        // 기기 모델 가져오기
        private var deviceModel: String {
            UIDevice.current.model + " (\(UIDevice.current.name))"
        }
        
        // iOS 버전
        private var systemVersion: String {
            UIDevice.current.systemName + " " + UIDevice.current.systemVersion
        }
    }

    struct InfoRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .foregroundColor(.primary)
            }
        }
}

#Preview {
    NavigationStack {
        AppVersionView()
    }
}
