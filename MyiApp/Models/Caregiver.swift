//
//  CareGiver.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-09.
//

import Foundation
import FirebaseFirestore

struct Caregiver: Codable, Identifiable {
    var id: String
    var name: String?
    var email: String?
    var provider: String?
    var babies: [DocumentReference]
    var lastSelectedBabyId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case provider
        case babies
        case lastSelectedBabyId
    }
}
