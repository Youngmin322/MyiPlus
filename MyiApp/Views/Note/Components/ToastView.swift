//
//  ToastView.swift
//  MyiApp
//
//  Created by Saebyeok Jang on 5/13/25.
//

import SwiftUI

struct ToastMessage: Equatable {
    var message: String
    var type: ToastType
    
    enum ToastType {
        case success
        case error
        case info
        
        var color: Color {
            switch self {
            case .success: return Color("sharkPrimaryColor")
            case .error: return Color.red
            case .info: return Color("sharkPrimaryColor")
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
}

struct ToastView: View {
    var toast: ToastMessage
    var onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
            
            Text(toast.message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                onDismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(toast.type.color)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if let toast = toast {
                        VStack {
                            Spacer()
                            ToastView(toast: toast) {
                                dismissToast()
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 20)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: toast != nil)
            )
            .onChange(of: toast) { _, newValue in
                if newValue != nil {
                    workItem?.cancel()
                    
                    let task = DispatchWorkItem {
                        dismissToast()
                    }
                    workItem = task
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: task)
                }
            }
    }
    
    private func dismissToast() {
        withAnimation {
            toast = nil
        }
        workItem?.cancel()
        workItem = nil
    }
}

extension View {
    func toast(message: Binding<ToastMessage?>) -> some View {
        self.modifier(ToastModifier(toast: message))
    }
}
