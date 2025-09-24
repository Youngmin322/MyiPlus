//
//  AuthService.swift
//  MyiApp
//
//  Created by Yung Hak Lee on 5/9/25.
//

import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import CryptoKit
import AuthenticationServices
import SwiftUI

@MainActor
class AuthService: ObservableObject {
    @Published private(set) var user: User?
    private let auth: Auth = Auth.auth()
    static let shared = AuthService()
    private var currentNonce: String?
    
    private init() {
        self.user = auth.currentUser
    }
    
    // 로그아웃
    func signOut() {
        do {
            try auth.signOut()
            self.user = nil
            DatabaseService.shared.hasBabyInfo = false
            CaregiverManager.shared.logout()
            try? Auth.auth().signOut()
            print("Sign out successful")
        } catch {
            print("Sign out failed: \(error.localizedDescription)")
        }
    }
    
    // 구글 로그인
    func googleSignIn() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No active window scene"])
        }
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase client ID missing"])
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get ID token"])
        }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: result.user.accessToken.tokenString)
        let authResult = try await auth.signIn(with: credential)
        self.user = authResult.user
        await CaregiverManager.shared.loadCaregiverInfo()
        print("Firebase user: \(authResult.user.uid)")
    }
    
    // 애플 로그인
    func appleSignIn(_ authorization: ASAuthorization) async throws {
        if authorization.credential is ASAuthorizationAppleIDCredential {
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Apple ID credential"])
            }
            guard let nonce = currentNonce else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nonce is missing"])
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get Apple ID token"])
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode ID token"])
            }
            guard let authCode = appleIDCredential.authorizationCode,
                  let authCodeString = String(data: authCode, encoding: .utf8) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get or decode authorizationCode"])
            }
            print("authCodeString: \(authCodeString)")
            // Initialize a Firebase credential, including the user's full name.
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                           rawNonce: nonce,
                                                           fullName: appleIDCredential.fullName)
            
            let authResult = try await auth.signIn(with: credential)
            self.user = authResult.user
            self.currentNonce = nil
            await CaregiverManager.shared.loadCaregiverInfo()
            print("Firebase user: \(authResult.user.uid)")
        }
    }
    
    // Apple 로그인 요청 설정
    func configureAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.email, .fullName]
        request.nonce = sha256(nonce)
        print("Generated Nonce: \(nonce)")
    }
    // Nonce 생성
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    // sha256 해시
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    // 회원 탈퇴
    func deleteAccount() async throws {
        guard let user = auth.currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "로그인된 유저 없음"])
        }
        let providerID = user.providerData.first?.providerID ?? ""
        do {
            if providerID.contains("google.com") {
                try await reauthenticateWithGoogle()
                try await revokeGoogleAccess()
            } else if providerID.contains("apple.com") {
                let authCode = try await reauthenticateWithApple()
                if let authCode = authCode {
                    try await revokeAppleToken(authCode: authCode)
                }
            } else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "지원되지 않는 제공자: \(providerID)"])
            }
            try await CaregiverManager.shared.deleteUserData(uid: user.uid)
            try await user.delete()
            DatabaseService.shared.hasBabyInfo = false
            CaregiverManager.shared.logout()
            self.user = nil
            try auth.signOut()
            print("회원 탈퇴 및 로그아웃 성공")
        } catch {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "회원탈퇴 실패: \(error.localizedDescription)"])
        }
    }
    
    // Google 재인증
    private func reauthenticateWithGoogle() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "활성 창 없음"])
        }
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase 클라이언트 ID 없음"])
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google ID 토큰 없음"])
        }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
        try await auth.currentUser?.reauthenticate(with: credential)
    }
    
    // Google 접근 권한 취소
    private func revokeGoogleAccess() async throws {
        try await GIDSignIn.sharedInstance.disconnect()
    }
    
    private func revokeAppleToken(authCode: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().revokeToken(withAuthorizationCode: authCode) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        }
    }
    
    // Apple 재인증
    private func reauthenticateWithApple() async throws -> String? {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = AppleSignInDelegate()
            delegate.completion = continuation
            
            DispatchQueue.main.async {
                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = delegate
                controller.performRequests()
                print("Apple 재인증 요청 시작")
                print("Nonce: \(nonce)")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if delegate.completion != nil {
                    delegate.completion?.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple 재인증 타임아웃"]))
                    delegate.completion = nil
                }
            }
        }
    }
    
    // Apple 재인증 delegate
    private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
        var completion: CheckedContinuation<String?, Error>?
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let authCode = appleIDCredential.authorizationCode,
                  let authCodeString = String(data: authCode, encoding: .utf8),
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8),
                  let nonce = AuthService.shared.currentNonce else {
                completion?.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple 인증 코드 또는 토큰 없음"]))
                return
            }
            
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: appleIDCredential.fullName)
            Task {
                do {
                    try await Auth.auth().currentUser?.reauthenticate(with: credential)
                    completion?.resume(returning: authCodeString)
                    completion = nil
                } catch {
                    completion?.resume(throwing: error)
                    completion = nil
                }
            }
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            completion?.resume(throwing: error)
            completion = nil
        }
    }
}
