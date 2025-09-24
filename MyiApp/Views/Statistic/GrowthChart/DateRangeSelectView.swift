//
//  DateRangeSelectView.swift
//  MyiApp
//
//  Created by 이민서 on 5/29/25.
//

import SwiftUI

struct DateRangeSelectView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yy. M. d"
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 25) {
            
            HStack(alignment: .center) {
                // 시작 날짜 선택
                ZStack {
                    HStack {
                        Text("\(dateFormatter.string(from: startDate))")
                            .foregroundColor(.primary)
                            .padding(.vertical, 12)
                            .padding(.leading, 12)
                        Spacer()
                        Image(systemName: "calendar")
                            .foregroundColor(Color("buttonColor"))
                            .padding(.trailing, 12)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("buttonColor"), lineWidth: 2)
                    )
                    .padding(.horizontal)
                    DatePicker(
                        "",
                        selection: $startDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(height: 30)
                    .blendMode(.destinationOver)
                }
                
                Spacer()
                Text("~")
                Spacer()
                
                // 종료 날짜 선택
                ZStack {
                    HStack {
                        Text("\(dateFormatter.string(from: endDate))")
                            .foregroundColor(.primary)
                            .padding(.vertical, 12)
                            .padding(.leading, 12)
                        Spacer()
                        Image(systemName: "calendar")
                            .foregroundColor(Color("buttonColor"))
                            .padding(.trailing, 12)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("buttonColor"), lineWidth: 2)
                    )
                    .padding(.horizontal)
                    DatePicker(
                        "",
                        selection: $endDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(height: 30)
                    .blendMode(.destinationOver)
                }
                
            }
            
            
        }
    }
}
