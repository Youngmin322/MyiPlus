//
//  HomeView.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-08.
//

import SwiftUI
import Kingfisher

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel = .init()
    
    var body: some View {
        VStack(spacing: 0) {
            SafeAreaPaddingView()
                .frame(height: getTopSafeAreaHeight())
                .background(Color.customBackground)
            ScrollView {
                VStack(spacing: 15) {
                    babyInfoCard
                    VStack {
                        dateSection
                        gridItems
                        Divider()
                            .padding(.horizontal)
                        timeline
                    }
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .tertiarySystemBackground)))
                }
                .padding()
            }
        }
        .background(Color.customBackground)

    }
    private struct GridItemCategory: Identifiable {
        let id: UUID = UUID()
        let name: String
        let category: TitleCategory
        let image: UIImage
    }
    private struct InfoItem: View {
        let title: String
        let value: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
    }
    private var babyInfoCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if let baby = viewModel.baby {
                    NavigationLink(destination: BabyProfileView(baby: baby)) {
                        KFImage(URL(string: baby.photoURL ?? ""))
                            .placeholder({
                                ProgressView()
                            })
                            .onFailureImage(viewModel.displaySharkImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(.circle)
                            .background(Circle().fill(Color.sharkPrimaryLight))
                            .overlay(Circle().stroke(Color.sharksSadowTone, lineWidth: 2))
                    }
                    .padding(.trailing, 16)
                }
                
                VStack {
                    HStack {
                        Menu {
                            ForEach(viewModel.caregiverManager.babies) { baby in
                                Button {
                                    viewModel.babyChangeButtonDidTap(baby: baby)
                                } label: {
                                    HStack {
                                        Text(baby.name)
                                            .foregroundStyle(.primary)
                                        if baby.id == viewModel.baby?.id {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.blue)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            NavigationLink(destination: RegisterBabyView()) {
                                HStack {
                                    Text("아이 추가")
                                        .foregroundStyle(Color.button)
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.blue)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(viewModel.displayName)
                                    .foregroundColor(.primary)
                                    .font(.title3)
                                    .bold()
                                Image(uiImage: viewModel.displayGender)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(Color.primary)
                            }
                        }
                        Spacer()
                    }
                    HStack(alignment: .center) {
                        Text(viewModel.displayDevelopmentalStage)
                            .font(.subheadline)
                            .foregroundStyle(Color.button)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("태어난지")
                            .fontWeight(.semibold)
                        Text(viewModel.displayDayCount)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.button)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Divider()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            HStack {
                InfoItem(title: "생년월일", value: viewModel.displayBirthDate)
                Spacer()
                InfoItem(title: "키/몸무게", value: viewModel.displayHeightWeight)
                Spacer()
                InfoItem(title: "혈액형", value: viewModel.displayBloodType)
            }
            .padding([.bottom, .horizontal])
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .tertiarySystemBackground)))
    }
    private var dateSection: some View {
        ZStack {
            HStack(spacing: 6) {
                Button(action: {
                    viewModel.updateSelectedDate(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.body)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal)
                Spacer()
                Image(systemName: "calendar")
                Text(viewModel.selectedDate.formattedKoreanDateString())
                    .fontWeight(.medium)
                    .font(.body)
                Spacer()
                Button(action: {
                    viewModel.updateSelectedDate(by: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.body)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal)
            }
            DatePicker(
                "",
                selection: $viewModel.selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .frame(width: 180, height: 30)
            .blendMode(.destinationOver)
        }
        .padding(.vertical, 7)
    }
    private var gridItems: some View {
        let careItems: [GridItemCategory] = [
            .init(name: "수유/이유식", category: .breastfeeding, image: .colorMeal),
//            .init(name: "기저귀", category: .diaper, image: .colorDiaper),
            .init(name: "배변", category: .pee, image: .colorPotty),
            .init(name: "수면", category: .sleep, image: .colorSleep),
            .init(name: "키/몸무게", category: .heightWeight, image: .colorHeightWeight),
            .init(name: "목욕", category: .bath, image: .colorBath),
            .init(name: "간식", category: .snack, image: .colorSnack),
            .init(name: "건강 관리", category: .temperature, image: .normalClinic),
            .init(name: "메모", category: .clinic, image: .colorCheckList)
        ]
        let columns = Array(repeating: GridItem(.flexible()), count: 4)
        return LazyVGrid(columns: columns) {
            ForEach(careItems, id: \.name) { item in
                Button {
                    viewModel.gridItemDidTap(title: item.category)
                } label: {
                    VStack(spacing: 0) {
                        Image(uiImage: item.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.customBackground)
                                    .frame(width: 70, height: 70)
                            )
                        Text(item.name)
                            .font(.footnote)
                            .foregroundStyle(.foreground)
                    }
                    .frame(width: 90, height: 100)
                }
                .buttonStyle(.plain)
            }
        }
        .padding([.horizontal, .bottom])
    }
    private var timeline: some View {
        VStack(spacing: 0) {
            if viewModel.filteredRecords.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("이 날짜에 기록이 없습니다")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
            } else {
                List {
                    ForEach(viewModel.filteredRecords.indices, id: \.self) { index in
                        let record = viewModel.filteredRecords[index]
                        TimelineRow(
                            record: record,
                            index: index,
                            totalCount: viewModel.filteredRecords.count
                        )
                        .padding(.leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.recordToEdit = record
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteRecord(record)
                            } label: {
                                Label("삭제", systemImage: "trash")
                                    .foregroundColor(.red)
                            }
                            .tint(.red)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(height: CGFloat(viewModel.filteredRecords.count * 60))
                .sheet(item: $viewModel.recordToEdit) { record in
                    let detents: Set<PresentationDetent> = {
                        switch record.title {
                            case .babyFood, .formula, .breastfeeding, .pumpedMilk, .temperature, .medicine:
                                [.large]
                            default:
                                [.medium]
                        }
                    }()
                    EditRecordView(record: record)
                        .presentationDetents(detents)
                }
            }
        }
        .padding(.leading)
    }
    private func getTopSafeAreaHeight() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 0
        }
        
        let height = window.safeAreaInsets.top
        return height * 0.1
    }
}

#Preview {
    HomeView()
}
