//
//  EditRecordView.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-20.
//

import SwiftUI

struct EditRecordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: EditRecordViewModel
    
    init(record: Record) {
        _viewModel = StateObject(wrappedValue: EditRecordViewModel(record: record))
    }
    
    var body: some View {
        NavigationView {
                Form {
                    content(record: viewModel.record)
                    if viewModel.record.title != .sleep { recordTimeSection }
                    deleteSection
                }
                .navigationTitle(viewModel.navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소", role: .cancel, action: {
                            dismiss()
                        })
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장", action: {
                            viewModel.saveRecord()
                            dismiss()
                        })
                    }
                }
                .scrollContentBackground(.hidden)
                .background {
                    Color.customBackground.ignoresSafeArea()
                    MinutesPickerActionSheet(isPresented: $viewModel.isRightMinutesPickerActionSheetPresent,
                                             selectedAmount: $viewModel.record.breastfeedingRightMinutes)
                    MinutesPickerActionSheet(isPresented: $viewModel.isLeftMinutesPickerActionSheetPresent,
                                             selectedAmount: $viewModel.record.breastfeedingLeftMinutes)
                    MLPickerActionSheet(isPresented: $viewModel.isMLPickerActionSheetPresent,
                                        selectedAmount: $viewModel.record.mlAmount)
                    TMPPickerActionSheet(isPresented: $viewModel.isTMPickerActionSheetPresent,
                                         selectedTemperature: Binding(
                                            get: { viewModel.record.temperature ?? 36.5 },
                                            set: { viewModel.record.temperature = $0 }
                                         ))
                }
            
        }
    }
    
    private var recordTimeSection: some View {
        Section {
            DatePicker("시간", selection: $viewModel.record.createdAt, displayedComponents: [.date, .hourAndMinute])
        }
    }
    
    private var deleteSection: some View {
        Section {
            Button("기록 삭제", role: .destructive, action: {
                viewModel.showDeleteAlert = true
            })
        }
        .alert("기록 삭제", isPresented: $viewModel.showDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                viewModel.deleteRecord()
                dismiss()
            }
        } message: {
            Text("정말로 이 기록을 삭제하시겠습니까?")
        }
    }
    
    @ViewBuilder func content(record: Record) -> some View {
        switch record.title {
            case .formula, .babyFood, .pumpedMilk, .breastfeeding:
                Section {
                    HStack {
                        Image(systemName: record.title == .breastfeeding ? "circle.inset.filled" : "circle")
                            .foregroundStyle(Color.button)
                        Image(.normalBreastFeeding)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                            .padding(.horizontal)
                        Text("모유수유")
                    }
                    .onTapGesture {
                        viewModel.updateRecordTitle(.breastfeeding)
                    }
                    HStack {
                        Image(systemName: record.title == .pumpedMilk ? "circle.inset.filled" : "circle")
                            .foregroundStyle(Color.button)
                        Image(.normalPumpedMilk)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                            .padding(.horizontal)
                        Text("유축수유")
                    }
                    .onTapGesture {
                        viewModel.updateRecordTitle(.pumpedMilk)
                    }
                    HStack {
                        Image(systemName: record.title == .formula ? "circle.inset.filled" : "circle")
                            .foregroundStyle(Color.button)
                        Image(.normalPowderedMilk)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                            .padding(.horizontal)
                        Text("분유")
                    }
                    .onTapGesture {
                        viewModel.updateRecordTitle(.formula)
                    }
                    HStack {
                        Image(systemName: record.title == .babyFood ? "circle.inset.filled" : "circle")
                            .foregroundStyle(Color.button)
                        Image(.normalBabyMeal)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                            .padding(.horizontal)
                        Text("이유식")
                    }
                    .onTapGesture {
                        viewModel.updateRecordTitle(.babyFood)
                    }
                } header: { Text("카테고리") }
                    .listRowSeparator(.hidden)
                
                if record.title == .breastfeeding {
                    Section {
                        HStack {
                            Text("왼쪽")
                            Spacer()
                            Button {
                                viewModel.isLeftMinutesPickerActionSheetPresent = true
                            } label: {
                                Text("\(viewModel.record.breastfeedingLeftMinutes ?? 0) 분")
                                    .foregroundStyle(Color.primary)
                            }
                            .buttonStyle(.bordered)
                        }
                        .buttonStyle(.plain)
                        HStack {
                            Text("오른쪽")
                            Spacer()
                            Button {
                                viewModel.isRightMinutesPickerActionSheetPresent = true
                            } label: {
                                Text("\(viewModel.record.breastfeedingRightMinutes ?? 0) 분")
                                    .foregroundStyle(Color.primary)
                            }
                            .buttonStyle(.bordered)
                        }
                        .buttonStyle(.plain)
                    } header: {
                        Text("수유 시간")
                    }
                } else {
                    Section {
                        HStack {
                            Text("용량")
                            Spacer()
                            Button {
                                viewModel.isMLPickerActionSheetPresent = true
                            } label: {
                                Text("\(viewModel.record.mlAmount ?? 0) ml")
                                    .foregroundStyle(Color.primary)
                            }
                            .buttonStyle(.bordered)
                        }
                        .buttonStyle(.plain)
                    } header: {
                        Text("용량")
                    }
                }
            case .sleep:
                Section {
                    DatePicker("시작", selection: Binding(
                        get: { viewModel.record.sleepStart ?? Date() },
                        set: { viewModel.record.sleepStart = $0 }
                    ), in: ...(viewModel.record.sleepEnd ?? Date()))
                    if let sleepEnd = viewModel.record.sleepEnd {
                        DatePicker("종료", selection: Binding(
                            get: { sleepEnd },
                            set: { viewModel.record.sleepEnd = $0 }
                        ), in: (viewModel.record.sleepStart ?? Date())...)
                    } else {
                        HStack {
                            Text("종료")
                            Spacer()
                            Button("현재 시간 기록") {
                                viewModel.record.sleepEnd = Date()
                            }
                            .buttonStyle(.bordered)
                            .foregroundStyle(Color.primary)
                        }
                    }
                } header: {
                    Text("수면 시간")
                }
            case .heightWeight:
                Section {
                    TextField(
                        "키를 입력해 주세요",
                        text: Binding(
                            get: { viewModel.record.height.map { String(format: "%.1f", $0) } ?? "" },
                            set: { viewModel.record.height = Double($0) }
                        )
                    )
                    .keyboardType(.decimalPad)
                    .overlay(
                        HStack {
                            Spacer()
                            Text("cm")
                                .foregroundColor(.secondary)
                                .padding(.trailing, 8)
                        }
                    )
                    TextField(
                        "몸무게를 입력해 주세요",
                        text: Binding(
                            get: { viewModel.record.weight.map { String(format: "%.1f", $0) } ?? "" },
                            set: { viewModel.record.weight = Double($0) }
                        )
                    )
                    .keyboardType(.decimalPad)
                    .overlay(
                        HStack {
                            Spacer()
                            Text("kg")
                                .foregroundColor(.secondary)
                                .padding(.trailing, 8)
                        }
                    )
                } header: {
                    Text("키/몸무게")
                }
            case .snack:
                Section {
                    TextField("간식을 입력해 주세요",
                              text: Binding(
                                get: { viewModel.record.content ?? "" },
                                set: { viewModel.record.content = $0 }
                              )
                    )
                } header: {
                    Text("내용")
                }
            case .clinic:
                Section {
                    TextField("메모를 입력해 주세요",
                              text: Binding(
                                get: { viewModel.record.content ?? "" },
                                set: { viewModel.record.content = $0 }
                              )
                    )
                } header: {
                    Text("내용")
                }
            case .temperature, .medicine:
                Section {
                    HStack {
                        Image(systemName: record.title == .temperature ? "circle.inset.filled" : "circle")
                            .foregroundStyle(Color.button)
                        Image(.normalTemperature)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                            .padding(.horizontal)
                        Text("체온")
                    }
                    .onTapGesture {
                        viewModel.updateRecordTitle(.temperature)
                    }
                    HStack {
                        Image(systemName: record.title == .medicine ? "circle.inset.filled" : "circle")
                            .foregroundStyle(Color.button)
                        Image(.normalMedicine)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                            .padding(.horizontal)
                        Text("투약")
                    }
                    .onTapGesture {
                        viewModel.updateRecordTitle(.medicine)
                    }
                } header: {
                    Text("카테고리")
                }
                .listRowSeparator(.hidden)
                
                if record.title == .temperature {
                    Section {
                        HStack {
                            Text("체온")
                            Spacer()
                            Button {
                                viewModel.isTMPickerActionSheetPresent = true
                            } label: {
                                Text(String(format: "%.1f °C", viewModel.record.temperature ?? 36.5))
                                    .foregroundColor(.primary)
                            }
                            .buttonStyle(.bordered)
                        }
                    } header: {
                        Text("현재 체온")
                    }
                } else {
                    Section {
                        TextField("내용을 입력해 주세요",
                                  text: Binding(
                                    get: { viewModel.record.content ?? "" },
                                    set: { viewModel.record.content = $0 }
                                  )
                        )
                    } header: {
                        Text("내용")
                    }
                }
            case .poop, .pee, .pottyAll:
                Section {
                    HStack {
                        Image(systemName: record.title == .pee ? "circle.inset.filled" : "circle")
                            .foregroundStyle(Color.button)
                        Image(.normalPee)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                            .padding(.horizontal)
                        Text("소변")
                    }
                    .onTapGesture {
                        viewModel.updateRecordTitle(.pee)
                    }
                    HStack {
                        Image(systemName: record.title == .poop ? "circle.inset.filled" : "circle")
                            .foregroundStyle(Color.button)
                        Image(.normalPoop)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                            .padding(.horizontal)
                        Text("대변")
                    }
                    .onTapGesture {
                        viewModel.updateRecordTitle(.poop)
                    }
                    HStack {
                        Image(systemName: record.title == .pottyAll ? "circle.inset.filled" : "circle")
                            .foregroundStyle(Color.button)
                        Image(.normalPotty)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                            .padding(.horizontal)
                        Text("둘다")
                    }
                    .onTapGesture {
                        viewModel.updateRecordTitle(.pottyAll)
                    }
                }
                .listRowSeparator(.hidden)
            case .diaper, .bath:
                EmptyView()
        }
    }
}

#Preview {
    let record = Record.mockRecords[0]
    return EditRecordView(record: record)
}
