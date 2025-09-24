//
//  SwiftRegisterBabyView.swift
//  MyiApp
//
//  Created by Yung Hak Lee on 5/19/25.
//

import SwiftUI

struct RegisterBabyView: View {
    @StateObject private var viewModel = RegisterBabyViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedForm: RegistrationType? = nil
    @State private var navigateToNextView = false
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("등록 방식을 선택해주세요")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary.opacity(0.8))
                    .padding()
                    .padding(.top)
                
                VStack {
                    HStack {
                        Text("새로운 아이 정보 등록")
                            .font(.title3)
                        
                        Spacer()
                        
                        Image(systemName: selectedForm == .newBaby ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(selectedForm == .newBaby ? Color("buttonColor") : .primary.opacity(0.6))
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedForm = .newBaby
                    }
                    
                    HStack {
                        Text("초대받은 아이 등록")
                            .font(.title3)
                        
                        Spacer()
                        Image(systemName: selectedForm == .existingBaby ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(selectedForm == .existingBaby ? Color("buttonColor") : .primary.opacity(0.6))
                    }
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedForm = .existingBaby
                    }
                }
            }
            .padding(.bottom)
            .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.tertiarySystemBackground))
                )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Spacer()
            
                Button(action: {
                    if selectedForm != nil {
                        navigateToNextView = true
                    }
                }) {
                    Text("다음")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .font(.headline)
                        .background(selectedForm == nil ? Color.gray : Color("buttonColor"))
                        .cornerRadius(12)
                }
                .disabled(selectedForm == nil)
                .navigationDestination(isPresented: $navigateToNextView) {
                    destinationView()
                }
                .padding()
        }
        .navigationTitle(Text("아이 등록"))
        .navigationBarTitleDisplayMode(.inline)
        .padding(.horizontal)
        .background(Color("customBackgroundColor"))
    }
    
    enum RegistrationType {
        case newBaby
        case existingBaby
    }
    
    @ViewBuilder
    private func destinationView() -> some View {
        switch selectedForm {
        case .newBaby:
            NewBabyRegisterView()
        case .existingBaby:
            ExistingBabyRegisterView()
        case .none:
            EmptyView()
        }
    }
}

#Preview {
    NavigationStack {
        RegisterBabyView()
    }
}
