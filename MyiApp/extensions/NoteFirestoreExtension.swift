//
//  NoteFirestoreExtension.swift
//  MyiApp
//
//  Created by Saebyeok Jang on 5/13/25.
//

import Foundation
import FirebaseFirestore

extension Timestamp {
    var dateValue: Date {
        return Date(timeIntervalSince1970: TimeInterval(seconds) + TimeInterval(nanoseconds) / 1_000_000_000)
    }
}

extension Date {
    var timestamp: Timestamp {
        return Timestamp(date: self)
    }
}
