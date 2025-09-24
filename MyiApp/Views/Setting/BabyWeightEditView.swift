//
//  BabyWeightEditView.swift
//  MyiApp
//
//  Created by Yung Hak Lee on 5/23/25.
//

import SwiftUI

struct BabyWeightEditView: View {
    @StateObject var viewModel: BabyProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    @State private var selectedWeight: Double?
    
    private var isButtonEnabled: Bool {
        selectedWeight != nil && selectedWeight! > 0
    }
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.minimum = 0
        formatter.maximum = 200
        formatter.allowsFloats = true
        return formatter
    }()
    
    init(viewModel: BabyProfileViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._selectedWeight = State(wrappedValue: viewModel.baby.weight)
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("몸무게를 입력하세요")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary.opacity(0.8))
                    .padding()
                    .padding(.top)
                ZStack(alignment: .trailing) {
                    TextField("몸무게를 입력하세요", value: $selectedWeight, formatter: numberFormatter)
                        .multilineTextAlignment(.leading)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.primary.opacity(0.6))
                        .font(.title2)
                        .padding()
                        .padding(.vertical)
                        .padding(.trailing, 70)
                        .background(
                            VStack {
                                Spacer()
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.primary.opacity(0.8))
                            }
                                .padding()
                        )
                        .focused($isTextFieldFocused)
                        .padding(.bottom)
                    
                    if selectedWeight != nil {
                        HStack(spacing: 15) {
                            Text("kg")
                                .foregroundColor(.primary.opacity(0.6))
                                .font(.title2)
                            Button(action: {
                                selectedWeight = nil
                                isTextFieldFocused = true
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.trailing, 20)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .navigationTitle(Text("몸무게"))
            .navigationBarTitleDisplayMode(.inline)
            
            Spacer()
            
                .safeAreaInset(edge: .bottom) {
                    VStack {
                        Button(action: {
                            if let weight = selectedWeight, weight > 0 {
                                viewModel.baby.weight = weight
                                Task {
                                    await viewModel.saveProfileEdits()
                                    dismiss()
                                }
                            }
                        }) {
                            Text("완료")
                                .foregroundColor(isButtonEnabled ? .white : .primary)
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
