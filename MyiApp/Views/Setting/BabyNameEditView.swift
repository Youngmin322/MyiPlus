//
//  BabyNameEditView.swift
//  MyiApp
//
//  Created by Yung Hak Lee on 5/23/25.
//

import SwiftUI

struct BabyNameEditView: View {
    @StateObject var viewModel: BabyProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    @State private var selectedName: String
    private var isButtonEnabled: Bool {
        selectedName.trimmingCharacters(in: .whitespaces).isEmpty == false
    }
    
    init(viewModel: BabyProfileViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._selectedName = State(wrappedValue: viewModel.baby.name)
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("이름을 입력하세요")
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
                            viewModel.baby.name = selectedName
                            Task {
                                await viewModel.saveProfileEdits()
                                if viewModel.isProfileSaved {
                                    await CaregiverManager.shared.loadCaregiverInfo()
                                    dismiss()
                                }
                            }
                        }
                    
                    if !selectedName.isEmpty {
                        Button(action: {
                            selectedName = ""
                            isTextFieldFocused = true
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
            .navigationTitle(Text("이름 / 태명"))
            .navigationBarTitleDisplayMode(.inline)
            
            Spacer()
            
                .safeAreaInset(edge: .bottom) {
                    VStack {
                        Button(action: {
                            viewModel.baby.name = selectedName
                            Task {
                                await viewModel.saveProfileEdits()
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
