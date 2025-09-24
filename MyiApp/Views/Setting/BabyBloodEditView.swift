//
//  BabyBloodEditView.swift
//  MyiApp
//
//  Created by Yung Hak Lee on 5/23/25.
//

import SwiftUI

struct BabyBloodEditView: View {
    @StateObject var viewModel: BabyProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBloodType: BloodType
    
    init(viewModel: BabyProfileViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._selectedBloodType = State(wrappedValue: viewModel.baby.bloodType)
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("혈액형을 선택하세요")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary.opacity(0.8))
                    .padding()
                    .padding(.top)
                
                VStack {
                    HStack {
                        Text("A 형")
                            .font(.title3)
                        
                        Spacer()
                        
                        Image(systemName: selectedBloodType == .A ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(selectedBloodType == .A ? Color("buttonColor") : .primary.opacity(0.6))
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedBloodType = .A
                    }
                    
                    HStack {
                        Text("B 형")
                            .font(.title3)
                        
                        Spacer()
                        
                        Image(systemName: selectedBloodType == .B ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(selectedBloodType == .B ? Color("buttonColor") : .primary.opacity(0.6))
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedBloodType = .B
                    }
                    
                    HStack {
                        Text("O 형")
                            .font(.title3)
                        
                        Spacer()
                        
                        Image(systemName: selectedBloodType == .O ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(selectedBloodType == .O ? Color("buttonColor") : .primary.opacity(0.6))
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedBloodType = .O
                    }
                    
                    HStack {
                        Text("AB 형")
                            .font(.title3)
                        
                        Spacer()
                        
                        Image(systemName: selectedBloodType == .AB ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(selectedBloodType == .AB ? Color("buttonColor") : .primary.opacity(0.6))
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedBloodType = .AB
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .navigationTitle(Text("혈액형"))
            .navigationBarTitleDisplayMode(.inline)
            
            Spacer()
            
            Button(action: {
                viewModel.baby.bloodType = selectedBloodType
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
