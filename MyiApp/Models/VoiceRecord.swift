//
//  VoiceRecord.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-09.
//

import Foundation

struct VoiceRecord: Codable, Identifiable {
    var id: UUID
    var createdAt: Date
    var recordReference: String
    var firstLabel: EmotionType
    var firstLabelConfidence: Double
    var secondLabel: EmotionType
    var secondLabelConfidence: Double
}

struct EmotionResult {
    let type: EmotionType
    let confidence: Double
}

enum EmotionType: String, CaseIterable, Codable {
    case bellyPain = "belly_pain"
    case burping
    case coldHot = "cold_hot"
    case discomfort
    case hungry
    case lonely
    case scared
    case tired
    case unknown
}

extension EmotionType {
    var displayName: String {
        switch self {
        case .bellyPain: return "배가 아파요"
        case .burping: return "트림하고 싶어요"
        case .coldHot: return "춥거나 더워요"
        case .discomfort: return "불편해요"
        case .hungry: return "배고파요"
        case .lonely: return "외로워요"
        case .scared: return "무서워요"
        case .tired: return "졸려요"
        case .unknown: return "분석 불가"
        }
    }
}
