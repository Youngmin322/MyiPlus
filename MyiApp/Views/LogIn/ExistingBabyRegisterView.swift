//
//  RegisterExistingBabyView.swift
//  MyiApp
//
//  Created by Yung Hak Lee on 5/28/25.
//

import SwiftUI

struct ExistingBabyRegisterView: View {
    @StateObject private var viewModel = RegisterBabyViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    private var isButtonEnabled: Bool {
        !viewModel.babyId.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("초대 코드를 입력하세요")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary.opacity(0.8))
                    .padding()
                    .padding(.top)
                ZStack(alignment: .trailing) {
                    TextField("초대 코드를 입력하세요", text: $viewModel.babyId)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary.opacity(0.6))
                        .font(.title2)
                        .padding()
                        .padding(.vertical)
                        .padding(.trailing, 40)
                        .focused($isTextFieldFocused)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .background(
                            VStack {
                                Spacer()
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.primary.opacity(0.8))
                            }
                                .padding()
                        )
                        .submitLabel(.done)
                        .onSubmit {
                            Task {
                                await viewModel.registerExistingBaby()
                                if viewModel.isRegistered {
                                    popToRootViewController()
                                }
                            }
                        }
                    
                    if !viewModel.babyId.isEmpty {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.babyId = ""
                                isTextFieldFocused = true
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing, 20)
                        }
                    }
                }
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
            .padding(.bottom)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .navigationTitle(Text("초대 코드 등록"))
            .navigationBarTitleDisplayMode(.inline)
            
            Spacer()
            
                .safeAreaInset(edge: .bottom) {
                    VStack {
                        Button(action: {
                            Task {
                                await viewModel.registerExistingBaby()
                                if viewModel.isRegistered {
                                    popToRootViewController()
                                }
                            }
                        }) {
                            Text("완료")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .font(.headline)
                                .background(isButtonEnabled ? Color("buttonColor") : Color.gray)
                        }
                        .contentShape(Rectangle())
                        .disabled(!isButtonEnabled)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.tertiarySystemBackground))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                }
        }
        .background(Color("customBackgroundColor"))
        .contentShape(Rectangle())
        .onTapGesture {
            isTextFieldFocused = false
        }
    }
    
    private func dismissKeyboard() {
        isTextFieldFocused = false
    }
    
    private func popToRootViewController() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let navController = window.rootViewController?.findNavigationController() {
            DispatchQueue.main.async {
                navController.popToRootViewController(animated: true)
            }
        }
    }
}
