//
//  BabyBirthEditView.swift
//  MyiApp
//
//  Created by Yung Hak Lee on 5/23/25.
//

import SwiftUI

struct BabyBirthDayEditView: View {
    @StateObject var viewModel: BabyProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showBirthDatePicker = false
    @State private var selectedDate: Date
    
    init(viewModel: BabyProfileViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._selectedDate = State(wrappedValue: viewModel.baby.birthDate)
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("출생일을 선택하세요")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary.opacity(0.8))
                    .padding()
                    .padding(.top)
                HStack {
                    DatePicker(
                        "출생일",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .tint(Color("buttonColor"))
                    .datePickerStyle(.graphical)
                    .foregroundColor(.primary.opacity(0.6))
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Spacer()
            
            Button(action: {
                viewModel.baby.birthDate = selectedDate
                Task {
                    await viewModel.saveProfileEdits()
                    dismiss()
                }
            }) {
                Text("완료")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                    .frame(height: 50)
                    .background(Color("buttonColor"))
                    .cornerRadius(12)
            }
            .contentShape(Rectangle())
            .navigationTitle(Text("출생일"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .padding(.horizontal)
        .background(Color("customBackgroundColor"))
    }
}
