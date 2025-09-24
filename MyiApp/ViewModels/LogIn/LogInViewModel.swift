//
//  LogInViewModel.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-07.
//

import AuthenticationServices

@MainActor
class LogInViewModel: ObservableObject {
    @Published var error: String?
    @Published var isLoading: Bool = false
    private let authService: AuthService
    
    init() {
        self.authService = AuthService.shared
    }
    
    func signInWithGoogle() async throws {
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.googleSignIn()
        } catch {
            self.error = "Goolge 로그인에 실패했습니다: \(error.localizedDescription)"
            throw error
        }
    }
    
    func signInWithApple(_ authorization: ASAuthorization) async throws {
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.appleSignIn(authorization)
        } catch {
            self.error = "Apple 로그인에 실패했습니다: \(error.localizedDescription)"
            throw error
        }
    }
    
    // Apple 로그인 요청 설정
    func configureAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        authService.configureAppleSignInRequest(request)
    }
}
