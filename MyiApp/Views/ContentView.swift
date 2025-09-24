//
//  ContentView.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-07.
//

import SwiftUI

struct ContentView: View {
    @StateObject var caregiverManager = CaregiverManager.shared
    
    // MARK: - 앱 업데이트 관련 상태
    @State private var showUpdateAlert = false
    @State private var latestVersion = ""
    @State private var releaseNotes: String? = nil
    @AppStorage("lastUpdateCheckDate") private var lastUpdateCheckDate = Date.distantPast.timeIntervalSince1970
    @AppStorage("skipVersion") private var skipVersion = ""
    
    init() {
        let tabbarAppearance = UITabBarAppearance()
        tabbarAppearance.configureWithOpaqueBackground()
        tabbarAppearance.backgroundColor = .customBackground
        UITabBar.appearance().standardAppearance = tabbarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabbarAppearance
    }
    
    var body: some View {
        Group {
            if caregiverManager.selectedBaby != nil {
                TabView {
                    NavigationStack { HomeView() }
                        .tabItem {
                            Label("홈", systemImage: "house.fill")
                        }
                    NavigationStack { NoteView() }
                        .tabItem {
                            Label("육아 수첩", systemImage: "book.fill")
                        }
                    NavigationStack { VoiceRecordView() }
                        .tabItem {
                            Label("울음 분석", systemImage: "waveform")
                        }
                    NavigationStack { StatisticView() }
                        .tabItem {
                            Label("기록 분석", systemImage: "chart.bar.fill")
                        }
                    NavigationStack { SettingsView() }
                        .tabItem {
                            Label("더 보기", systemImage: "line.3.horizontal")
                        }
                }
                .tabViewStyle(DefaultTabViewStyle())
                .edgesIgnoringSafeArea(.bottom)
                .tint(Color.button)
                .overlay(updateAlertOverlay)
                
            } else {
                ProgressView("케어기버 및 아기 정보를 불러오는 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.customBackground.ignoresSafeArea())
            }
        }
        .task {
            await caregiverManager.loadCaregiverInfo()
            print("불러오기 완료: \(caregiverManager.babies.count)명")
            
            // MARK: - 앱 업데이트 체크 호출
            checkForAppUpdate()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // 앱이 포그라운드로 돌아올 때마다 업데이트 체크
            checkForAppUpdate()
        }
    }
    
    // MARK: - 업데이트 알림 오버레이
    @ViewBuilder
    private var updateAlertOverlay: some View {
        if showUpdateAlert {
            ZStack {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        // 외부 탭 무시
                    }
                
                UpdateAlertView(
                    isPresented: $showUpdateAlert,
                    currentVersion: AppUpdateService.shared.getCurrentAppVersion(),
                    latestVersion: latestVersion,
                    releaseNotes: releaseNotes,
                    onUpdate: {
                        openAppStore()
                    },
                    onLater: {
                        // 나중에 버튼 - 8시간 후 다시 체크
                        lastUpdateCheckDate = Date().addingTimeInterval(8 * 60 * 60).timeIntervalSince1970
                    }
                )
                .transition(.scale)
                .animation(.easeInOut(duration: 0.3), value: showUpdateAlert)
            }
        }
    }
    
    // MARK: - 앱 업데이트 확인
    private func checkForAppUpdate() {
        let currentVersion = AppUpdateService.shared.getCurrentAppVersion()
        print("현재 앱 버전: \(currentVersion)")
        
        // 최근 체크 시간 확인
        let lastCheck = Date(timeIntervalSince1970: lastUpdateCheckDate)
        let hoursSinceLastCheck = Date().timeIntervalSince(lastCheck) / 3600
        print("마지막 업데이트 체크 이후 경과 시간: \(hoursSinceLastCheck)시간")
        
        // 앱 처음 설치 시나 업데이트 후 첫 실행 시에는 무조건 체크
        let lastKnownVersion = UserDefaults.standard.string(forKey: "lastKnownVersion") ?? ""
        let isFirstRunAfterUpdate = lastKnownVersion != currentVersion
        
        // 마지막 체크로부터 8시간 이상 지났는지 또는 앱 업데이트 후 첫 실행인지 확인
        if hoursSinceLastCheck < 8 && !isFirstRunAfterUpdate {
            print("8시간 이내에 이미 체크함, 업데이트 체크 건너뜀")
            return
        }
        
        // 현재 버전 저장
        UserDefaults.standard.set(currentVersion, forKey: "lastKnownVersion")
        
        Task {
            // 2초 딜레이 추가 (앱 시작 직후 바로 체크하지 않도록)
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // 최신 버전 정보 가져오기
            let result = await AppUpdateService.shared.checkForUpdate()
            
            await MainActor.run {
                // 업데이트 확인 날짜 저장
                lastUpdateCheckDate = Date().timeIntervalSince1970
                
                switch result {
                case .success(let versionInfo):
                    latestVersion = versionInfo.latestVersion
                    releaseNotes = versionInfo.releaseNotes
                    
                    print("앱스토어 버전: \(latestVersion), 릴리즈 노트: \(releaseNotes ?? "없음")")
                    
                    // 업데이트 필요성 확인
                    let updateAvailable = AppUpdateService.shared.isUpdateAvailable(
                        currentVersion: currentVersion,
                        latestVersion: latestVersion
                    )
                    
                    // 이미 스킵한 버전인지 확인
                    let isSkippedVersion = skipVersion == latestVersion
                    
                    print("업데이트 확인 결과 - 현재: \(currentVersion), 최신: \(latestVersion), 업데이트 필요: \(updateAvailable), 스킵됨: \(isSkippedVersion)")
                    
                    // 업데이트 필요하고 스킵한 버전이 아니면 알림 표시
                    if updateAvailable && !isSkippedVersion {
                        print("업데이트 알림 표시")
                        withAnimation {
                            showUpdateAlert = true
                        }
                    }
                    
                case .failure(let error):
                    print("업데이트 확인 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 앱스토어 열기
    private func openAppStore() {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(AppUpdateService.appID)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ContentView()
}
