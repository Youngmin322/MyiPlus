//
//  ViewModel.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-08.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

class StatisticViewModel: ObservableObject {
    @Published var baby: Baby = Baby(name: "", birthDate: Date(), gender: .male, height: 0, weight: 0, bloodType: .A, mainCaregiver: "dd")
    @Published var records: [Record] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        CaregiverManager.shared.$selectedBaby
            .compactMap { $0 }
            .assign(to: &$baby)
        CaregiverManager.shared.$records
            .assign(to: &$records)
    }
    
}
