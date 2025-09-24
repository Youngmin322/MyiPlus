//
//  JawsLoadingIndicator.swift
//  MyiApp
//
//  Created by Saebyeok Jang on 5/14/25.
//

import SwiftUI

struct CleanCharacterLoadingIndicator: View {
    let imageNames: [String]
    let frameInterval: Double
    @State private var currentFrameIndex = 0
    
    var body: some View {
        Image(imageNames[currentFrameIndex])
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 120)
            .onAppear {
                startFrameChange()
            }
    }
    
    private func startFrameChange() {
        Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { timer in
            currentFrameIndex = (currentFrameIndex + 1) % imageNames.count
        }
    }
}

struct CleanLoadingOverlay: View {
    var message: String
    var imageNames: [String]
    var frameInterval: Double = 0.3
    var backgroundColor: Color = Color("sharkPrimaryColor")
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                CleanCharacterLoadingIndicator(
                    imageNames: imageNames,
                    frameInterval: frameInterval
                )
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 25)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
            )
        }
    }
}

struct SimpleCleanLoadingOverlay: View {
    var message: String
    var imageNames: [String]
    var frameInterval: Double = 0.3
    
    var body: some View {
        VStack(spacing: 20) {
            CleanCharacterLoadingIndicator(
                imageNames: imageNames,
                frameInterval: frameInterval
            )
            
            Text(message)
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 25)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("sharkPrimaryColor"))
        )
        .shadow(radius: 10)
    }
}
