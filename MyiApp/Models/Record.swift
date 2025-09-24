//
//  Record.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-09.
//

import Foundation

struct Record: Codable, Identifiable {
    var id: UUID
    var createdAt: Date
    var title: TitleCategory
    // 분유, 이유식, 유축수유 양 (ml)
    var mlAmount: Int?
    // 모유수유: 좌/우 분유 수유 시간 (분)
    var breastfeedingLeftMinutes: Int?
    var breastfeedingRightMinutes: Int?
    // 수면: 시작 및 종료 시간
    var sleepStart: Date?
    var sleepEnd: Date?
    // 키/몸무게
    var height: Double?
    var weight: Double?
    // 온도
    var temperature: Double?
    // 텍스트 필드 내용
    var content: String?
    
    init(id: UUID = UUID() ,createdAt: Date = Date(), title: TitleCategory, mlAmount: Int? = nil, breastfeedingLeftMinutes: Int? = nil, breastfeedingRightMinutes: Int? = nil, sleepStart: Date? = nil, sleepEnd: Date? = nil, height: Double? = nil, weight: Double? = nil, temperature: Double? = nil, content: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.mlAmount = mlAmount
        self.breastfeedingLeftMinutes = breastfeedingLeftMinutes
        self.breastfeedingRightMinutes = breastfeedingRightMinutes
        self.sleepStart = sleepStart
        self.sleepEnd = sleepEnd
        self.height = height
        self.weight = weight
        self.temperature = temperature
        self.content = content
    }
}

enum TitleCategory: String, Codable, CaseIterable {
    case formula        // 분유
    case babyFood       // 이유식
    case pumpedMilk     // 유축수유
    case breastfeeding  // 모유수유
    case diaper         // 기저귀
    case sleep          // 수면
    case heightWeight   // 키/몸무게
    case bath           // 목욕
    case snack          // 간식
    case temperature    // 온도
    case medicine
    case clinic
    case poop
    case pee
    case pottyAll
}

extension Record {
    static let mockRecords: [Record] = [
        // 분유
        Record(
            createdAt: Date(),
            title: .formula,
            mlAmount: 120
        ),
        Record(
            createdAt: Date().addingTimeInterval(-21600),
            title: .formula,
            mlAmount: 150
        ),
        Record(
            createdAt: Date().addingTimeInterval(-43200),
            title: .formula,
            mlAmount: 130
        ),

        // 이유식
        Record(
            createdAt: Date().addingTimeInterval(-3600),
            title: .babyFood,
            mlAmount: 80
        ),
        Record(
            createdAt: Date().addingTimeInterval(-25200),
            title: .babyFood,
            mlAmount: 100
        ),
        Record(
            createdAt: Date().addingTimeInterval(-46800),
            title: .babyFood,
            mlAmount: 90
        ),

        // 유축수유
        Record(
            createdAt: Date().addingTimeInterval(-7200),
            title: .pumpedMilk,
            mlAmount: 100
        ),
        Record(
            createdAt: Date().addingTimeInterval(-28800),
            title: .pumpedMilk,
            mlAmount: 120
        ),
        Record(
            createdAt: Date().addingTimeInterval(-50400),
            title: .pumpedMilk,
            mlAmount: 110
        ),

        // 모유수유
        Record(
            createdAt: Date().addingTimeInterval(-10800),
            title: .breastfeeding,
            breastfeedingLeftMinutes: 10,
            breastfeedingRightMinutes: 15
        ),
        Record(
            createdAt: Date().addingTimeInterval(-32400),
            title: .breastfeeding,
            breastfeedingLeftMinutes: 12,
            breastfeedingRightMinutes: 13
        ),
        Record(
            createdAt: Date().addingTimeInterval(-54000),
            title: .breastfeeding,
            breastfeedingLeftMinutes: 15,
            breastfeedingRightMinutes: 10
        ),

        // 기저귀
        Record(
            createdAt: Date().addingTimeInterval(-14400),
            title: .diaper
        ),
        Record(
            createdAt: Date().addingTimeInterval(-36000),
            title: .diaper
        ),
        Record(
            createdAt: Date().addingTimeInterval(-57600),
            title: .diaper
        ),

        // 배변 - poop
        Record(
            createdAt: Date().addingTimeInterval(-18000),
            title: .poop
        ),
        Record(
            createdAt: Date().addingTimeInterval(-39600),
            title: .poop
        ),

        // 배변 - pee
        Record(
            createdAt: Date().addingTimeInterval(-21600),
            title: .pee
        ),
        Record(
            createdAt: Date().addingTimeInterval(-43200),
            title: .pee
        ),

        // 수면
        Record(
            createdAt: Date().addingTimeInterval(-25200),
            title: .sleep,
            sleepStart: Date().addingTimeInterval(-25200),
            sleepEnd: Date().addingTimeInterval(-21600)
        ),
        Record(
            createdAt: Date().addingTimeInterval(-46800),
            title: .sleep,
            sleepStart: Date().addingTimeInterval(-46800),
            sleepEnd: Date().addingTimeInterval(-43200)
        ),
        Record(
            createdAt: Date().addingTimeInterval(-68400),
            title: .sleep,
            sleepStart: Date().addingTimeInterval(-68400),
            sleepEnd: Date().addingTimeInterval(-64800)
        ),

        // 키/몸무게
        Record(
            createdAt: Date().addingTimeInterval(-86400),
            title: .heightWeight,
            height: 65.3,
            weight: 7.8
        ),
        Record(
            createdAt: Date().addingTimeInterval(-172800),
            title: .heightWeight,
            height: 64.8,
            weight: 7.6
        ),
        Record(
            createdAt: Date().addingTimeInterval(-259200),
            title: .heightWeight,
            height: 64.2,
            weight: 7.5
        ),

        // 목욕
        Record(
            createdAt: Date().addingTimeInterval(-30000),
            title: .bath
        ),
        Record(
            createdAt: Date().addingTimeInterval(-51600),
            title: .bath
        ),

        // 간식
        Record(
            createdAt: Date().addingTimeInterval(-40000),
            title: .snack,
            content: "바나나 퓨레 1/2개"
        ),
        Record(
            createdAt: Date().addingTimeInterval(-61600),
            title: .snack,
            content: "사과 퓨레 1/3개"
        ),
        Record(
            createdAt: Date().addingTimeInterval(-83200),
            title: .snack,
            content: "당근 퓨레 1/4개"
        ),

        // 건강관리
        Record(
            createdAt: Date().addingTimeInterval(-50000),
            title: .temperature,
            temperature: 37.2
        ),
        Record(
            createdAt: Date().addingTimeInterval(-71600),
            title: .clinic,
            content: "예방접종 2차 완료"
        ),
        Record(
            createdAt: Date().addingTimeInterval(-93200),
            title: .medicine,
            content: "비타민 D 드롭 1방울 복용"
        )
    ]
}
