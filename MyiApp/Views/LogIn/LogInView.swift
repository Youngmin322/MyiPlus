//
//  LogInView.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-07.
//

import SwiftUI
import GoogleSignInSwift
import AuthenticationServices

struct LogInView: View {
    @StateObject var viewModel: LogInViewModel = .init()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            VStack {
                
                Spacer()
                
                Text("My i")
                    .font(.system(size: 60))
                    .fontWeight(.bold)
                    .foregroundColor(Color("LaunchScreenTextColor"))
                    .fontDesign(.rounded)
                    .padding(.horizontal)
                    .padding(.top, 100)
                
                Text("쉽고 편한 육아 기록 앱")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("LaunchScreenTextColor"))
                    .padding(.bottom, 30)
                
                Image("launchScreenImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 431, height: 431)
                    .offset(y: -1)
                
                // Google 로그인 버튼
                Button(action: {
                    Task {
                        do {
                            try await viewModel.signInWithGoogle()
                        } catch {
                            viewModel.error = error.localizedDescription
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        // Google 로고 (Asset에서 추가한 이미지 사용)
                        Image("google-logo-icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                        
                        Text("Sign in with Google")
                            .font(.system(size: 18.5, weight: .semibold))
                            .kerning(-0.2)
                            .baselineOffset(0.5)
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal)
                        .padding(.vertical, 13)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.black, lineWidth: 0.8))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 50)
                .offset(y: -20)
                
                // 애플 로그인 버튼
                SignInWithAppleButton(.signIn) { request in
                    viewModel.configureAppleSignInRequest(request)
                } onCompletion: { result in
                    Task {
                        do {
                            switch result {
                            case .success(let authorization):
                                try await viewModel.signInWithApple(authorization)
                            case .failure(let error):
                                viewModel.error = error.localizedDescription
                            }
                        } catch {
                            viewModel.error = error.localizedDescription
                        }
                    }
                }
                .signInWithAppleButtonStyle(.whiteOutline)
                .frame(height: 50)
                .padding(.horizontal, 50)
                .padding(.bottom, 150)
                
                Spacer()
            }
            
            // 로그인 로딩 화면
            if viewModel.isLoading {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .padding()
                        .opacity(viewModel.isLoading ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
            }
        }
        .background(Color("LaunchScreenColor"))
    }
}

#Preview {
    LogInView()
}
