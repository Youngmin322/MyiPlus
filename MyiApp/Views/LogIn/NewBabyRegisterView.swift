//
//  BabyProfileRegisterView.swift
//  MyiApp
//
//  Created by Yung Hak Lee on 5/28/25.
//

import SwiftUI

struct NewBabyRegisterView: View {
    @StateObject private var viewModel = RegisterBabyViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var focusedField: Field?
    private enum Field: Hashable {
        case name, birthDate, height, weight, submit
    }
    
    @State private var isNameEntered: Bool = false
    @State private var isGenderSelected: Bool = false
    @State private var isBirthDateSelected: Bool = false
    @State private var isHeightEntered: Bool = false
    @State private var isWeightEntered: Bool = false
    @State private var isBloodTypeSelected: Bool = false
    
    private var isButtonEnabled: Bool {
        isNameEntered &&
        isGenderSelected &&
        isHeightEntered &&
        isWeightEntered &&
        isBloodTypeSelected &&
        isBirthDateSelected
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("성별")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary.opacity(0.8))
                            .padding()
                            .padding(.top, 8)
                        HStack {
                            Text("남자 아이")
                                .foregroundColor(.primary.opacity(0.6))
                                .padding(.leading, 5)
                            
                            Spacer()
                            
                            Image(systemName: viewModel.gender == .male ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.title2)
                                .foregroundColor(viewModel.gender == .male ? Color("buttonColor") : .primary.opacity(0.6))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.gender = .male
                        }
                        .padding()
                        .padding(.top, 5)
                        .padding(.bottom, 5)
                        HStack {
                            Text("여자 아이")
                                .foregroundColor(.primary.opacity(0.6))
                                .padding(.leading, 5)
                            
                            Spacer()
                            
                            Image(systemName: viewModel.gender == .female ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.title2)
                                .foregroundColor(viewModel.gender == .female ? Color("buttonColor") : .primary.opacity(0.6))
                        }
                        .padding()
                        .padding(.bottom, 8)
                    }
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(10)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.gender = .female
                    }
                    .onChange(of: viewModel.gender) {
                        withAnimation {
                            isGenderSelected = viewModel.gender != nil
                            focusedField = .name
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("이름 / 태명")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary.opacity(0.8))
                            .padding()
                            .padding(.top, 8)
                        
                        ZStack(alignment: .trailing) {
                            TextField("이름을 입력하세요", text: $viewModel.name)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.primary.opacity(0.6))
                                .font(.title2)
                                .padding(.vertical)
                                .padding(.trailing, 40)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                                .background(
                                    VStack {
                                        Spacer()
                                        Rectangle()
                                            .frame(height: 1)
                                            .foregroundColor(.primary.opacity(0.8))
                                    }
                                )
                                .submitLabel(.done)
                                .focused($focusedField, equals: .name)
                            
                            if isNameEntered {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.name = ""
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 10)
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 8)
                    }
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(10)
                    .onChange(of: viewModel.name) { _, newValue in
                        isNameEntered = !newValue.isEmpty
                    }
                    .onSubmit {
                        if !viewModel.name.isEmpty {
                            withAnimation {
                                isNameEntered = true
                                focusedField = .birthDate
                            }
                        } else {
                            isNameEntered = false
                            focusedField = nil
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("출생일")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary.opacity(0.8))
                            .padding()
                            .padding(.top, 8)
                        HStack {
                            DatePicker(
                                "날짜",
                                selection: Binding(
                                    get: { viewModel.birthDate ?? Date() },
                                    set: {
                                        newValue in
                                        viewModel.birthDate = newValue
                                        isBirthDateSelected = true
                                    }
                                ),
                                displayedComponents: .date
                            )
                            .focused($focusedField, equals: .birthDate)
                        }
                        .padding()
                        .padding(.top, 5)
                        .padding(.bottom, 5)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("시간 입력", isOn: $viewModel.isTimeSelectionEnabled)
                                .padding()
                            if viewModel.isTimeSelectionEnabled {
                                HStack {
                                    DatePicker(
                                        "시간",
                                        selection: Binding(
                                            get: { viewModel.birthDate ?? Date() },
                                            set: { viewModel.birthDate = $0 }
                                        ),
                                        displayedComponents: .hourAndMinute
                                    )
                                    .focused($focusedField, equals: .birthDate)
                                }
                                .padding()
                                .padding(.bottom, 8)
                            }
                        }
                    }
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(10)
                    .onSubmit {
                        if !isHeightEntered {
                            withAnimation {
                                isBirthDateSelected = true
                                focusedField = .height
                            }
                        } else {
                            focusedField = nil
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("키")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary.opacity(0.8))
                            .padding()
                            .padding(.top, 8)
                        ZStack(alignment: .trailing) {
                            TextField("키를 입력하세요", text: $viewModel.height)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.primary.opacity(0.6))
                                .font(.title2)
                                .padding(.vertical)
                                .padding(.trailing, 40)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                                .background(
                                    VStack {
                                        Spacer()
                                        Rectangle()
                                            .frame(height: 1)
                                            .foregroundColor(.primary.opacity(0.8))
                                    }
                                )
                                .focused($focusedField, equals: .height)
                                .onChange(of: viewModel.height) { _, newValue in
                                    let filtered = newValue.filter { $0.isNumber || $0 == "." }
                                    if filtered != newValue {
                                        viewModel.height = filtered
                                    }
                                    isHeightEntered = !filtered.isEmpty
                                }
                            if !viewModel.height.isEmpty {
                                HStack(spacing: 15) {
                                    Text("cm")
                                        .foregroundColor(.primary.opacity(0.6))
                                        .font(.title2)
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.height = ""
                                            focusedField = .height
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .padding(.trailing, 10)
                                    }
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 8)
                    }
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("몸무게")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary.opacity(0.8))
                            .padding()
                            .padding(.top, 8)
                        ZStack(alignment: .trailing) {
                            TextField("몸무게를 입력하세요", text: $viewModel.weight)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.primary.opacity(0.6))
                                .font(.title2)
                                .padding(.vertical)
                                .padding(.trailing, 40)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                                .background(
                                    VStack {
                                        Spacer()
                                        Rectangle()
                                            .frame(height: 1)
                                            .foregroundColor(.primary.opacity(0.8))
                                    }
                                )
                                .focused($focusedField, equals: .weight)
                                .onChange(of: viewModel.weight) { _, newValue in
                                    let filtered = newValue.filter { $0.isNumber || $0 == "." }
                                    if filtered != newValue {
                                        viewModel.weight = filtered
                                    }
                                    isWeightEntered = !filtered.isEmpty
                                }
                            if isWeightEntered {
                                HStack(spacing: 15) {
                                    Text("kg")
                                        .foregroundColor(.primary.opacity(0.6))
                                        .font(.title2)
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.weight = ""
                                            focusedField = .weight
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .padding(.trailing, 10)
                                    }
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 8)
                    }
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("혈액형")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary.opacity(0.8))
                            .padding()
                            .padding(.top, 8)
                        HStack {
                            Text("A 형")
                                .foregroundColor(.primary.opacity(0.6))
                            Spacer()
                            
                            Image(systemName: viewModel.bloodType == .A ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.title2)
                                .foregroundColor(viewModel.bloodType == .A ? Color("buttonColor") : .primary.opacity(0.6))
                        }
                        .padding()
                        .padding(.top, 5)
                        .padding(.bottom, 5)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.bloodType = .A
                            dismissKeyboard()
                        }
                        
                        HStack {
                            Text("B 형")
                                .foregroundColor(.primary.opacity(0.6))
                            
                            Spacer()
                            
                            Image(systemName: viewModel.bloodType == .B ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.title2)
                                .foregroundColor(viewModel.bloodType == .B ? Color("buttonColor") : .primary.opacity(0.6))
                        }
                        .padding()
                        .padding(.top, 5)
                        .padding(.bottom, 5)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.bloodType = .B
                            dismissKeyboard()
                        }
                        
                        HStack {
                            Text("O 형")
                                .foregroundColor(.primary.opacity(0.6))
                            
                            Spacer()
                            
                            Image(systemName: viewModel.bloodType == .O ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.title2)
                                .foregroundColor(viewModel.bloodType == .O ? Color("buttonColor") : .primary.opacity(0.6))
                        }
                        .padding()
                        .padding(.top, 5)
                        .padding(.bottom, 5)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.bloodType = .O
                            dismissKeyboard()
                        }
                        
                        HStack {
                            Text("AB 형")
                                .foregroundColor(.primary.opacity(0.6))
                            
                            Spacer()
                            
                            Image(systemName: viewModel.bloodType == .AB ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.title2)
                                .foregroundColor(viewModel.bloodType == .AB ? Color("buttonColor") : .primary.opacity(0.6))
                        }
                        .padding()
                        .padding(.bottom, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.bloodType = .AB
                            dismissKeyboard()
                        }
                        
                    }
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(10)
                    .onChange(of: viewModel.bloodType) {
                        if viewModel.bloodType != nil {
                            withAnimation {
                                isBloodTypeSelected = true
                                focusedField = .submit
                                dismissKeyboard()
                            }
                        } else {
                            isBloodTypeSelected = false
                        }
                    }
                }
                
                Button(action: {
                    dismissKeyboard()
                    Task {
                        await viewModel.registerBaby()
                        if viewModel.isRegistered {
                            DatabaseService.shared.hasBabyInfo = true
                            popToRootViewController()
                        } else if let error = viewModel.errorMessage {
                            print("등록 실패: \(error)")
                        }
                    }
                }) {
                    Text("완료")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .font(.headline)
                        .background(isButtonEnabled ? Color("buttonColor") : Color.gray)
                        .cornerRadius(12)
                }
                .padding(.vertical)
                .disabled(!isButtonEnabled)
            }
            .padding(.horizontal)
        }
        .onTapGesture {
            dismissKeyboard()
        }
        .navigationTitle("새로운 아이 정보 등록")
        .background(Color("customBackgroundColor"))
    }
    
    
    private func dismissKeyboard() {
        focusedField = nil
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

#Preview {
    NavigationStack {
        NewBabyRegisterView()
    }
}

