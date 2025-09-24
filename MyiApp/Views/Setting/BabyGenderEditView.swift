//
//  BabyGenderEditView.swift
//  MyiApp
//
//  Created by Yung Hak Lee on 5/23/25.
//

import SwiftUI

struct BabyGenderEditView: View {
    @StateObject var viewModel: BabyProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGender: Gender
    
    init(viewModel: BabyProfileViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._selectedGender = State(wrappedValue: viewModel.baby.gender)
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("성별을 선택하세요")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary.opacity(0.8))
                    .padding()
                    .padding(.top)
                
                VStack {
                    HStack {
                        Text("남자 아이")
                            .font(.title3)
                        
                        Spacer()
                        
                        Image(systemName: selectedGender == .male ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(selectedGender == .male ? Color("buttonColor") : .primary.opacity(0.6))
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedGender = .male
                    }
                    
                    HStack {
                        Text("여자 아이")
                            .font(.title3)
                        
                        Spacer()
                        Image(systemName: selectedGender == .female ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(selectedGender == .female ? Color("buttonColor") : .primary.opacity(0.6))
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedGender = .female
                    }
                }
                .padding(.bottom)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.tertiarySystemBackground))
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .navigationTitle(Text("성별"))
            .navigationBarTitleDisplayMode(.inline)
            
            Spacer()
            
            Button(action: {
                viewModel.baby.gender = selectedGender
                Task {
                    await viewModel.saveProfileEdits()
                    dismiss()
                }
            }) {
                Text("완료")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .font(.headline)
                    .background(Color("buttonColor"))
                    .cornerRadius(12)
            }
            .contentShape(Rectangle())
        }
        .padding(.horizontal)
        .background(Color("customBackgroundColor"))
    }
}
