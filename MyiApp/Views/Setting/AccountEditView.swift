//
//  AccountSettingsView.swift
//  MyiApp
//
//  Created by Yung Hak Lee on 5/13/25.
//

import SwiftUI
import PhotosUI

struct AccountEditView: View {
    @ObservedObject private var viewModel = AccountEditViewModel.shared
    @State private var showPhotoActionSheet = false
    @State private var showPhotoPicker = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var selectedName: String
    private var isButtonEnabled: Bool {
        selectedName.trimmingCharacters(in: .whitespaces).isEmpty == false
    }
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    init(viewModel: AccountEditViewModel) {
        self.viewModel = viewModel
        self._selectedName = State(wrappedValue: viewModel.name)
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("사용자 이름을 입력하세요")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary.opacity(0.8))
                    .padding()
                    .padding(.top)
                ZStack(alignment: .trailing) {
                    TextField("이름을 입력하세요", text: $selectedName)
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
                            viewModel.name = selectedName
                            Task {
                                await viewModel.saveProfile()
                                if viewModel.isProfileSaved {
                                    dismiss()
                                }
                            }
                        }
                    
                    if !selectedName.isEmpty {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedName = ""
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
            .navigationTitle(Text("사용자 이름"))
            .navigationBarTitleDisplayMode(.inline)
            
            Spacer()
            
            .safeAreaInset(edge: .bottom) {
                VStack {
                    Button(action: {
                        viewModel.name = selectedName
                        Task {
                            await viewModel.saveProfile()
                            if viewModel.isProfileSaved {
                                await CaregiverManager.shared.loadCaregiverInfo()
                                dismiss()
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
}

