//
//  AnniversaryType.swift
//  MyiApp
//
//  Created by Saebyeok Jang on 5/23/25.
//

import SwiftUI

enum AnniversaryType {
    case birthday
    case hundredDays
    case firstBirthday
    
    var emoji: String {
        switch self {
        case .birthday:
            return "🎂"
        case .hundredDays:
            return "💯"
        case .firstBirthday:
            return "🎉"
        }
    }
    
    var color: Color {
        switch self {
        case .birthday:
            return .pink
        case .hundredDays:
            return .purple
        case .firstBirthday:
            return .orange
        }
    }
    
    var text: String {
        switch self {
        case .birthday:
            return "생일"
        case .hundredDays:
            return "100일"
        case .firstBirthday:
            return "첫돌"
        }
    }
}
