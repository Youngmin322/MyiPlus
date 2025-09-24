//
//  MyiApp.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-07.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
import UserNotifications
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // 앱 첫 실행 체크
        checkForFreshInstall()
        
        if AuthService.shared.user == nil {
            DatabaseService.shared.hasBabyInfo = false
            CaregiverManager.shared.logout()
        }
        
        // 알림 설정
        UNUserNotificationCenter.current().delegate = self
        
        // 알림 권한 상태 확인
        NotificationService.shared.checkAuthorizationStatus()
        
        let backButtonAppearance = UIBarButtonItemAppearance()
        let appearance = UINavigationBarAppearance()
        let backImage = UIImage(systemName: "chevron.left")?
            .withTintColor(UIColor(Color.primary.opacity(0.8)), renderingMode: .alwaysOriginal)
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.configureWithOpaqueBackground()
        appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
        appearance.backButtonAppearance = backButtonAppearance
        appearance.shadowColor = .clear
        appearance.backgroundColor = .customBackground
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // 앱이 포그라운드 상태일 때 알림을 표시하기 위한 메서드
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // 알림을 탭했을 때 처리할 메서드
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 탭한 알림의 식별자를 가져와서 필요한 액션 수행
        let noteId = response.notification.request.identifier
        print("알림 탭됨: \(noteId)")
        
        center.setBadgeCount(0) { error in
            if let error = error {
                print("배지 초기화 오류: \(error.localizedDescription)")
            }
        }
        
        completionHandler()
    }
    
    func checkForFreshInstall() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        
        if !hasLaunchedBefore {
            // 앱 첫 실행이므로 강제로 로그아웃
            do {
                try Auth.auth().signOut()
                print("앱 첫 실행: 강제 로그아웃 완료")
            } catch let error {
                print("로그아웃 오류: \(error.localizedDescription)")
            }
            
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            UserDefaults.standard.synchronize()
        }
    }
}

enum AppState {
    case loading
    case login
    case content
    case register
}

@main
struct MyiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authService = AuthService.shared
    @StateObject var databaseService = DatabaseService.shared
    @State private var appState: AppState = .loading
    
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                currentView
                    .task {
                        await updateAppState()
                        await AccountEditViewModel.shared.loadProfile()
                    }
                    .onChange(of: authService.user) { _, _ in
                        Task { await updateAppState() }
                    }
                    .onChange(of: databaseService.hasBabyInfo) { _, newValue in
                        if newValue == true {
                            appState = .content
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    private var currentView: some View {
        switch appState {
        case .loading:
            ProgressView()
                .progressViewStyle(.circular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.customBackground.ignoresSafeArea())
        case .login:
            LogInView()
        case .content:
            ContentView()
        case .register:
            RegisterBabyView()
        }
    }
    
    @MainActor
    private func updateAppState() async {
        appState = authService.user == nil ? .login : await databaseService.checkBabyInfo() ? .content : .register
        databaseService.hasBabyInfo = appState != .login ? databaseService.hasBabyInfo : false
    }
}
